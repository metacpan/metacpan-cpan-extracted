use strict;
use warnings;
use utf8;

use FindBin;
use File::Spec;

# Load the fresh checkout lib first, ahead of the node's blib build, so this
# process runs the tip's Perl modules exactly like the CLI subprocesses
# already do (prove's -I only names the blib). Same pattern as t/05.
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::ProcessSupervision ();
use Developer::Dashboard::RuntimeManager;
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use POSIX qw(WNOHANG);
use Test::More;
use Time::Local qw(timegm timelocal);

my $repo = getcwd();

my $IS_WINDOWS = $^O eq 'MSWin32';

# A fake collector child sleeps this long and then exits on its own. The
# test never kills anything it finds, so a bounded sleep is how a control
# child goes away without a kill: the controls run in well under a second,
# and 30 seconds is margin enough for the slowest node.
my $FAKE_CHILD_SLEEP = 30;

# A state root with no runtime.json is only treated as a dead run when it
# is at least this old. Metadata lands at state-root creation, so a young
# metadata-less root may be a concurrent run still creating itself.
my $METADATA_LESS_ROOT_MIN_AGE = 3600;

# A supervisor polls every 5 seconds, so a heartbeat older than this is
# a stuck supervisor, not a slow one. Reported as evidence only: the
# orphan verdict never depends on the heartbeat.
my $SUPERVISOR_STUCK_HEARTBEAT_AGE = 600;

# _read_json_file($file)
# Returns the decoded JSON hash reference, or undef when the file is
# missing or unreadable.
sub _read_json_file {
    my ($file) = @_;
    return if !-f $file;
    open my $fh, '<', $file or return;
    local $/;
    my $raw = <$fh>;
    close $fh or return;
    my $data = eval { json_decode($raw) };
    return if !$data || ref($data) ne 'HASH';
    return $data;
}

# _write_json_file($file, $data)
# Writes one JSON hash reference to a file, creating parent dirs.
sub _write_json_file {
    my ( $file, $data ) = @_;
    my ( $volume, $dirs, $name ) = File::Spec->splitpath($file);
    my $dir = File::Spec->catpath( $volume, $dirs, '' );
    make_path($dir) if $dir ne '' && !-d $dir;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} json_encode($data) or die "Unable to write $file: $!";
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# _read_pid_file($file)
# Returns the pid integer from a pidfile, or undef when it is missing or
# does not hold a plain pid.
sub _read_pid_file {
    my ($file) = @_;
    return if !-f $file;
    open my $fh, '<', $file or return;
    my $pid = <$fh>;
    close $fh or return;
    return if !defined $pid;
    chomp $pid;
    return if $pid !~ /\A\d+\z/;
    return $pid + 0;
}

# _iso8601_now($utc)
# Formats the current time the way the product writes heartbeats: UTC with
# a trailing Z for the supervisor, local time without one for loops.
sub _iso8601_now {
    my ($utc) = @_;
    my @t = $utc ? gmtime(time) : localtime(time);
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0], $utc ? 'Z' : '';
}

# _heartbeat_age($file)
# Returns the age in seconds of the heartbeat_at stamp in one state JSON
# file, or undef when the file or the stamp is missing or unparseable.
# A trailing Z means UTC, no Z means local time; parsing them the wrong
# way round would be off by the timezone offset, so the two are kept apart.
sub _heartbeat_age {
    my ($file) = @_;
    my $data = _read_json_file($file);
    # NOTE: return undef, not a bare return: this sub is called in list
    # context as a hash value, and a bare return there is an empty list,
    # which makes the hash odd and warns.
    return undef if !$data || !$data->{heartbeat_at};
    my ( $y, $mo, $d, $h, $mi, $s, $z ) = $data->{heartbeat_at} =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z)?\z/ or return undef;
    my $when = $z ? timegm( $s, $mi, $h, $d, $mo - 1, $y - 1900 ) : timelocal( $s, $mi, $h, $d, $mo - 1, $y - 1900 );
    return time - $when;
}

# _windows_loop_shape_match($runner, $pid, $name)
# Windows-only identity path for a loop from another run. The product's
# _is_managed_loop can only confirm loops that belong to the checking
# process's own runtime on Windows (its state and pidfile fallbacks both
# read the checker's own paths), so a foreign loop is unconfirmable
# through it. But a real Windows loop child's CIM command line always
# carries its helper argv, collector-loop-foreground --name <name>, since
# $0 never rewrites it there - the product itself uses exactly this shape
# as the "does not disagree" condition in that fallback. An unrelated
# process cannot carry both tokens, so matching them confirms the loop.
sub _windows_loop_shape_match {
    my ( $runner, $pid, $name ) = @_;
    my $title = $runner->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return 1 if $title =~ /\bcollector-loop-foreground\b/ && $title =~ /--name\s+\Q$name\E(?:\s|\z)/;
    return 0;
}

# _orphans_in_root($root, $runner, $manager)
# Returns the orphan records for one state root whose run is already
# known dead: every confirmed-live collector process it still tracks.
# A pidfile alone proves nothing (DD-598: pids are reused), so each pid
# goes through the product's own identity checks - the supervisor check
# for the watchdog, the managed-loop check for loops, plus the Windows
# loop-helper shape for foreign loops _is_managed_loop cannot see.
sub _orphans_in_root {
    my ( $root, $runner, $manager ) = @_;
    my @found;

    my $sup_pid = _read_pid_file( File::Spec->catfile( $root, 'collector-supervisor.pid' ) );
    if ( defined $sup_pid && $manager->_is_collector_supervisor($sup_pid) ) {
        push @found,
          {
            root          => $root,
            kind          => 'supervisor',
            name          => '',
            pid           => $sup_pid,
            heartbeat_age => _heartbeat_age( File::Spec->catfile( $root, 'collector-supervisor.json' ) ),
          };
    }

    my $collectors_root = File::Spec->catdir( $root, 'collectors' );
    if ( -d $collectors_root ) {
        opendir my $dh, $collectors_root or die "Unable to read $collectors_root: $!";
        while ( my $entry = readdir $dh ) {
            my ($name) = $entry =~ /\A(.*)\.pid\z/ or next;
            next if $name eq '';
            my $pid = _read_pid_file( File::Spec->catfile( $collectors_root, $entry ) );
            next if !defined $pid;
            my $confirmed = $runner->_is_managed_loop( $pid, $name );
            if ( !$confirmed && $IS_WINDOWS ) {
                $confirmed = _windows_loop_shape_match( $runner, $pid, $name );
            }
            next if !$confirmed;
            push @found,
              {
                root          => $root,
                kind          => 'loop',
                name          => $name,
                pid           => $pid,
                heartbeat_age => _heartbeat_age( File::Spec->catfile( $collectors_root, $name, 'loop.json' ) ),
              };
        }
        closedir $dh;
    }
    return @found;
}

# _scan_state_base($base, $runner, $manager)
# Returns the orphan records for one state base: every collector process
# (supervisor, worker, loop) confirmed live in a state root whose run is
# dead. A root is a dead run when its runtime.json names a home directory
# that no longer exists - the same rule the Housekeeper's own
# _state_root_is_stale uses. A root whose home still exists is skipped
# outright, so a live run, a concurrent build, or a test that keeps its
# home can never be flagged. A root with no metadata at all is only
# treated as dead when it is old enough that no concurrent run can still
# be creating it. This routine only reads: it never kills, stops, or
# removes anything it finds.
sub _scan_state_base {
    my ( $base, $runner, $manager ) = @_;
    my @orphans;
    return @orphans if !-d $base;
    opendir my $dh, $base or die "Unable to read state base $base: $!";
    my @roots = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $entry (@roots) {
        my $root = File::Spec->catdir( $base, $entry );
        next if !-d $root;
        my $meta = _read_json_file( File::Spec->catfile( $root, 'runtime.json' ) );
        my $home = $meta ? ( $meta->{runtime_root} || '' ) : '';
        if ( $home ne '' && -d $home ) {
            next;
        }
        if ( $home eq '' ) {
            my @st = stat($root);
            next if !@st || ( time - $st[9] ) < $METADATA_LESS_ROOT_MIN_AGE;
        }
        push @orphans, _orphans_in_root( $root, $runner, $manager );
    }
    return @orphans;
}

# _etime_seconds($etime)
# Converts a ps etime value ([[dd-]hh:]mm:ss) into seconds, or undef when
# the text is not in that shape.
sub _etime_seconds {
    my ($etime) = @_;
    return undef if !defined $etime;
    my ( $d, $h, $m, $s ) = $etime =~ /\A(?:(?:(\d+)-)?(\d+):)?(\d+):(\d+)\z/ or return undef;
    return ( $d || 0 ) * 86400 + ( $h || 0 ) * 3600 + $m * 60 + $s;
}

# _process_table()
# Returns an array reference of live process rows, each with pid, ppid,
# age (seconds since start), args (command line or title, trailing
# padding removed), uid (Unix only) and parentless (true when the process
# has no live parent: on Unix ppid 1, or a parent pid that is not in the
# table, or one that started after the child and so is a reused pid; on
# Windows the last two only, as Windows never re-parents). Returns undef when the table cannot be read. The product's own
# _ps_processes carries no parent pid and no start time, so this reads
# the table itself, the same way the product does: one ps call on Unix,
# one PowerShell Win32_Process enumeration on Windows, both through
# system inside capture.
sub _process_table {
    local $?;
    my @rows;
    if ($IS_WINDOWS) {
        my $powershell = Developer::Dashboard::ProcessSupervision::_powershell_command();
        return undef if !defined $powershell || $powershell eq '';
        my ( $stdout, undef, $exit_code ) = capture {
            system(
                $powershell,
                '-NoLogo',
                '-NoProfile',
                '-Command',
                q{$ErrorActionPreference = 'Stop'; $now = Get-Date; Get-CimInstance Win32_Process | ForEach-Object { $cmd = $_.CommandLine; if ($null -eq $cmd) { $cmd = '' }; $cmd = $cmd -replace '\s+', ' '; $age = -1; if ($null -ne $_.CreationDate) { $age = [int](($now - $_.CreationDate).TotalSeconds) }; [Console]::Out.WriteLine($_.ProcessId.ToString() + [char]9 + $_.ParentProcessId.ToString() + [char]9 + $age.ToString() + [char]9 + $cmd) }},
            );
            return $? >> 8;
        };
        return undef if $exit_code != 0 || !defined $stdout;
        for my $line ( split /\r?\n/, $stdout ) {
            next if $line !~ /\A\s*(\d+)\t(\d+)\t(-?\d+)\t(.*?)\s*\z/;
            push @rows, { pid => $1 + 0, ppid => $2 + 0, age => $3 + 0, args => $4 };
        }
        my %age_of = map { $_->{pid} => $_->{age} } @rows;
        for my $row (@rows) {
            my $parent_age = $age_of{ $row->{ppid} };
            $row->{parentless} = ( !defined $parent_age || ( $parent_age >= 0 && $row->{age} >= 0 && $parent_age < $row->{age} ) ) ? 1 : 0;
        }
        return \@rows;
    }
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-eww', '-o', 'pid=,ppid=,uid=,etime=,args=';
        return $? >> 8;
    };
    return undef if $exit_code != 0 || !defined $stdout;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /\A\s*(\d+)\s+(\d+)\s+(\d+)\s+([\d:-]+)\s+(.*?)\s*\z/;
        my $age = _etime_seconds($4);
        next if !defined $age;
        push @rows, { pid => $1 + 0, ppid => $2 + 0, uid => $3 + 0, age => $age, args => $5 };
    }
    return _mark_unix_parentless( \@rows );
}

# _mark_unix_parentless($rows)
# Sets parentless on each Unix process row and returns the same array
# reference. A row is parentless when its parent pid is 1 (the ordinary
# orphan: the kernel hands it to pid 1), or its parent pid is not in the
# table, or its parent started after it did (a reused pid). The last two
# are in addition to the first, never instead of it: pid 1 is in the
# table and older than every child, so on their own they would stop
# flagging the ordinary orphan. Ages are whole seconds since start, so a
# parent that is younger has the smaller age. This only reads the rows.
sub _mark_unix_parentless {
    my ($rows) = @_;
    my %age_of = map { $_->{pid} => $_->{age} } grep { defined $_->{pid} } @{ $rows || [] };
    for my $row ( @{ $rows || [] } ) {
        my $ppid       = defined $row->{ppid} ? $row->{ppid} : -1;
        my $parent_age = $age_of{$ppid};
        $row->{parentless} =
            $ppid == 1                                                              ? 1
          : !exists $age_of{$ppid}                                                  ? 1
          : ( defined $parent_age && defined $row->{age} && $parent_age < $row->{age} ) ? 1
          :                                                                          0;
    }
    return $rows;
}

# _leftover_kind($manager, $row)
# Names what kind of dashboard runtime process one table row is, or
# returns undef for anything else. The supervisor and web shapes are the
# product's own matchers; the loop shape is the product's loop title
# ('d2 collector: <name>') or the loop helper's argv, which is all a
# Windows or emulated process shows; a Starman master is the web server
# a detached serve leaves behind.
sub _leftover_kind {
    my ( $manager, $row ) = @_;
    return undef if !$row || !defined $row->{args} || $row->{args} eq '';
    return 'supervisor' if $manager->_looks_like_collector_supervisor_process($row);
    return 'loop'       if $row->{args} =~ /\Ad2 collector: \S/;
    return 'loop'       if $row->{args} =~ /\bcollector-loop-foreground\b.*--name\s+\S/;
    return 'web'        if $manager->_looks_like_web_process($row);
    return 'web'        if $row->{args} =~ /\Astarman master\b/;
    return undef;
}

# _temp_roots()
# Returns the normalised directory prefixes that count as temporary
# space: the platform temp dir plus the usual fixed ones.
sub _temp_roots {
    my @roots = ( File::Spec->tmpdir );
    push @roots, $IS_WINDOWS ? ( grep { defined && length } @ENV{qw(TEMP TMP)} ) : ( '/tmp', '/var/tmp', '/var/folders' );
    my %seen;
    return grep { length($_) > 1 && !$seen{$_}++ } map { _normalise_origin($_) } @roots;
}

# _normalise_origin($text)
# Puts a path or command line into one comparable spelling: forward
# slashes, no trailing slash, no macOS /private prefix, no Linux
# ' (deleted)' suffix, lower case on Windows.
sub _normalise_origin {
    my ($text) = @_;
    return '' if !defined $text;
    $text =~ s{\\}{/}g;
    $text =~ s{ \(deleted\)\z}{};
    $text =~ s{\A/private(?=/(?:var|tmp)\b)}{};
    $text =~ s{/+\z}{};
    $text = lc $text if $IS_WINDOWS;
    return $text;
}

# _origin_is_temp($origin)
# True when a process origin lies in temporary space. On Unix the origin
# is the process's working directory and must sit under a temp root. On
# Windows the working directory of another process cannot be read, so
# the origin is its command line and must mention a temp root.
sub _origin_is_temp {
    my ($origin) = @_;
    my $text = _normalise_origin($origin);
    return 0 if $text eq '';
    for my $root ( _temp_roots() ) {
        return 1 if $IS_WINDOWS ? index( $text, "$root/" ) >= 0 : ( $text eq $root || index( $text, "$root/" ) == 0 );
    }
    return 0;
}

# _process_origin($row)
# Returns where one live process comes from, or undef when that cannot
# be read: its working directory on Unix (procfs where there is one,
# lsof otherwise, as on macOS), its command line on Windows.
sub _process_origin {
    my ($row) = @_;
    return $row->{args} if $IS_WINDOWS;
    my $link = "/proc/$row->{pid}/cwd";
    if ( -d '/proc' && -l $link ) {
        my $cwd = readlink $link;
        return $cwd if defined $cwd && $cwd ne '';
        return undef;
    }
    local $?;
    my ( $stdout, undef, $exit_code ) = capture {
        my $ok = system 'lsof', '-a', '-p', $row->{pid}, '-d', 'cwd', '-Fn';
        return $ok == -1 ? -1 : $? >> 8;
    };
    return undef if !defined $stdout;
    return $1 if $stdout =~ /^n(\/.*)$/m;
    return undef;
}

# _leftovers_in_rows($rows, $manager, $min_age, $origin_of)
# Picks the leftover runtime processes out of process-table rows and
# returns two array references: the leftovers, and the candidates whose
# origin could not be read. A leftover is a supervisor, loop or web
# process of this user that has no live parent, started more than
# $min_age seconds ago (so nothing started by this test, and nothing
# still being stopped by the test file before it, qualifies), and comes
# from temporary space (so a person's real runtime is never flagged:
# tests run with a throwaway home under the temp dir, people do not).
# This routine only reads: it never kills, stops, or removes anything.
sub _leftovers_in_rows {
    my ( $rows, $manager, $min_age, $origin_of ) = @_;
    my ( @found, @unresolved );
    for my $row ( @{ $rows || [] } ) {
        next if $row->{pid} == $$;
        next if !$row->{parentless};
        next if !defined $row->{age} || $row->{age} <= $min_age;
        next if defined $row->{uid} && ( $row->{uid} + 0 ) != ( $< + 0 );
        my $kind = _leftover_kind( $manager, $row ) or next;
        my $origin = $origin_of->($row);
        my $record = { %{$row}, kind => $kind, origin => $origin };
        if ( !defined $origin || $origin eq '' ) {
            push @unresolved, $record;
            next;
        }
        next if !_origin_is_temp($origin);
        push @found, $record;
    }
    return ( \@found, \@unresolved );
}

# _spawn_fake_child($command, $env, $label, $log_dir)
# Starts one fake collector-shaped child with the product's own spawn and
# returns its pid. The child sleeps a bounded time and exits on its own;
# the test never kills it. GoRoutine::spawn is the cross-platform spawn
# the product itself uses for supervisors, so the child is a real process
# with a real pid, environ and command line on every platform. The
# child's stdio logs go under $log_dir, a tempdir the test owns, so no
# log litter survives the run.
sub _spawn_fake_child {
    my ( $command, $env, $label, $log_dir ) = @_;
    my $out = File::Spec->catfile( $log_dir, "t994-fake-child-$$-$label-out.log" );
    my $err = "$out.stderr";
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        $command,
        {
            stdin  => File::Spec->devnull(),
            stdout => $out,
            stderr => $err,
            env    => $env || {},
        },
    );
    die "Unable to spawn fake collector child for $label\n" if !$pid;
    return $pid;
}

# _wait_for_death($pid)
# Waits until a pid is no longer alive, or dies after 30 seconds. Used
# only to obtain a pid that is known dead, for the negative control. A
# child that has exited but not been reaped is a zombie, and kill 0 still
# answers true for a zombie (proven by probe: the child showed state Z
# two seconds after exit, and only went away once waitpid reaped it), so
# the wait reaps with WNOHANG each poll; when the pid is not our child
# at all (spawn double-forked on some platform) it falls back to kill 0.
sub _wait_for_death {
    my ($pid) = @_;
    for ( 1 .. 300 ) {
        my $reaped = waitpid( $pid, WNOHANG );
        return 1 if $reaped == $pid;
        return 1 if $reaped == -1 && !kill( 0, $pid );
        select( undef, undef, undef, 0.1 );
    }
    die "pid $pid did not die within 30 seconds\n";
}

my $home = tempdir( CLEANUP => 1 );
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $store = Developer::Dashboard::Collector->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new( collectors => $store, files => $files, paths => $paths );
my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { die "app_builder must not run in the detector\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

# Fake collector-shaped children, one per identity path the product
# recognises. They sleep a bounded time and exit on their own; the test
# never kills them. The supervisor child carries the helper argv the
# product's command-shape check matches; the loop child carries the env
# marker (Linux), the helper argv (Windows), and a fabricated loop.json
# in the checker's own paths (macOS state path); the plain child carries
# none of these, so it must never be confirmed as a collector.
my $script_dir = tempdir( CLEANUP => 1 );
my $core_script = File::Spec->catfile( $script_dir, '_dashboard-core' );
my $loop_script = File::Spec->catfile( $script_dir, 'collector-loop-foreground' );
for my $script ( $core_script, $loop_script ) {
    open my $fh, '>', $script or die "Unable to write $script: $!";
    print {$fh} "sleep $FAKE_CHILD_SLEEP;\n" or die "Unable to write $script: $!";
    close $fh or die "Unable to close $script: $!";
}
my $sup_pid = _spawn_fake_child( [ $^X, $core_script, 'collector-supervisor-foreground' ], {}, 'supervisor', $script_dir );
my $loop_pid = _spawn_fake_child( [ $^X, $loop_script, 'collector-loop-foreground', '--name', 'micro-tick' ],
    { DEVELOPER_DASHBOARD_LOOP_NAME => 'micro-tick' }, 'loop', $script_dir );
my $plain_pid = _spawn_fake_child( [ $^X, '-e', 'sleep 30' ], {}, 'plain', $script_dir );
ok( kill( 0, $sup_pid ) && kill( 0, $loop_pid ) && kill( 0, $plain_pid ), 'detector: fake collector children are alive for the controls' );

# One process-table snapshot while the fake children are certainly alive,
# for the process-list controls further down. Taken here because the
# controls in between can be slow on Windows and the children only live
# for their bounded sleep.
my $control_rows = _process_table();

# The loop control also needs the fabricated state the macOS path reads
# and the pidfile the Windows fallback reads, both in the checker's own
# paths: loop.json with pid, name and process title, and the pidfile.
my $loop_dir = $paths->collector_dir('micro-tick');
_write_json_file(
    File::Spec->catfile( $loop_dir, 'loop.json' ),
    {
        pid          => $loop_pid,
        name         => 'micro-tick',
        process_name => 'd2 collector: micro-tick',
        status       => 'running',
        heartbeat_at => _iso8601_now(0),
    }
);
my $runner_pidfile = $runner->_pidfile('micro-tick');
make_path( $paths->collectors_root );
open my $pfh, '>', $runner_pidfile or die "Unable to write $runner_pidfile: $!";
print {$pfh} $loop_pid or die "Unable to write $runner_pidfile: $!";
close $pfh or die "Unable to close $runner_pidfile: $!";

# A pid known dead, for the negative control: spawn a child that exits at
# once and wait until it is gone.
my $dying_pid = _spawn_fake_child( [ $^X, '-e', 'exit 0' ], {}, 'dying', $script_dir );
_wait_for_death($dying_pid);

my $dead_home = File::Spec->catdir( File::Spec->tmpdir(), "t994-dead-home-$$" );
my $live_home = tempdir( CLEANUP => 1 );
my $fake_base = tempdir( CLEANUP => 1 );

# Control 1: live supervisor, dead home. Must be flagged.
{
    my $root = File::Spec->catdir( $fake_base, 'root-supervisor-live-dead-home' );
    _write_json_file( File::Spec->catfile( $root, 'runtime.json' ),
        { runtime_root => $dead_home, app_name => 'developer-dashboard' } );
    open my $fh, '>', File::Spec->catfile( $root, 'collector-supervisor.pid' ) or die $!;
    print {$fh} $sup_pid or die $!;
    close $fh or die $!;
    _write_json_file( File::Spec->catfile( $root, 'collector-supervisor.json' ), { heartbeat_at => _iso8601_now(1) } );
    my @found = _scan_state_base( $fake_base, $runner, $manager );
    is( scalar @found, 1, 'detector: flags a live supervisor whose run is dead' );
    is( $found[0]{kind}, 'supervisor', 'detector: the flagged process is the supervisor' ) if @found;
    is( $found[0]{pid}, $sup_pid, 'detector: the flagged supervisor pid is the live one' ) if @found;
    remove_tree($root);
}

# Control 2: live loop, dead home. Must be flagged.
{
    my $root = File::Spec->catdir( $fake_base, 'root-loop-live-dead-home' );
    _write_json_file( File::Spec->catfile( $root, 'runtime.json' ),
        { runtime_root => $dead_home, app_name => 'developer-dashboard' } );
    make_path( File::Spec->catdir( $root, 'collectors' ) );
    open my $fh, '>', File::Spec->catfile( $root, 'collectors', 'micro-tick.pid' ) or die $!;
    print {$fh} $loop_pid or die $!;
    close $fh or die $!;
    my @found = _scan_state_base( $fake_base, $runner, $manager );
    is( scalar @found, 1, 'detector: flags a live loop whose run is dead' );
    is( $found[0]{kind}, 'loop', 'detector: the flagged process is a loop' ) if @found;
    is( $found[0]{name}, 'micro-tick', 'detector: the flagged loop name matches' ) if @found;
    remove_tree($root);
}

# Control 3: dead pid, dead home. Must NOT be flagged: a pidfile alone
# proves nothing, and the pid is gone.
{
    my $root = File::Spec->catdir( $fake_base, 'root-dead-pid-dead-home' );
    _write_json_file( File::Spec->catfile( $root, 'runtime.json' ),
        { runtime_root => $dead_home, app_name => 'developer-dashboard' } );
    open my $fh, '>', File::Spec->catfile( $root, 'collector-supervisor.pid' ) or die $!;
    print {$fh} $dying_pid or die $!;
    close $fh or die $!;
    make_path( File::Spec->catdir( $root, 'collectors' ) );
    open my $lfh, '>', File::Spec->catfile( $root, 'collectors', 'micro-tick.pid' ) or die $!;
    print {$lfh} $dying_pid or die $!;
    close $lfh or die $!;
    my @found = _scan_state_base( $fake_base, $runner, $manager );
    is( scalar @found, 0, 'detector: ignores a dead pid in a dead run' );
    remove_tree($root);
}

# Control 4: live supervisor, live home. Must NOT be flagged: the run
# still owns its home, so this may be a live run, not a leftover.
{
    my $root = File::Spec->catdir( $fake_base, 'root-supervisor-live-live-home' );
    _write_json_file( File::Spec->catfile( $root, 'runtime.json' ),
        { runtime_root => $live_home, app_name => 'developer-dashboard' } );
    open my $fh, '>', File::Spec->catfile( $root, 'collector-supervisor.pid' ) or die $!;
    print {$fh} $sup_pid or die $!;
    close $fh or die $!;
    my @found = _scan_state_base( $fake_base, $runner, $manager );
    is( scalar @found, 0, 'detector: ignores a live supervisor whose home still exists' );
    remove_tree($root);
}

# Control 5: live foreign process, dead home. Must NOT be flagged: the
# pid is alive but carries no collector identity, so it is a reused pid,
# not a collector (DD-598).
{
    my $root = File::Spec->catdir( $fake_base, 'root-foreign-live-dead-home' );
    _write_json_file( File::Spec->catfile( $root, 'runtime.json' ),
        { runtime_root => $dead_home, app_name => 'developer-dashboard' } );
    open my $fh, '>', File::Spec->catfile( $root, 'collector-supervisor.pid' ) or die $!;
    print {$fh} $plain_pid or die $!;
    close $fh or die $!;
    make_path( File::Spec->catdir( $root, 'collectors' ) );
    open my $lfh, '>', File::Spec->catfile( $root, 'collectors', 'plain.pid' ) or die $!;
    print {$lfh} $plain_pid or die $!;
    close $lfh or die $!;
    my @found = _scan_state_base( $fake_base, $runner, $manager );
    is( scalar @found, 0, 'detector: ignores a live foreign process with no collector identity' );
    remove_tree($root);
}

# Fixture teardown, not orphan cleanup: remove the two files the loop
# control wrote into the checker's own paths (the pidfile the Windows
# fallback reads, the loop.json the macOS state path reads). They are
# the test's own fixtures, and leaving them would point the NEXT run's
# scan at a pid that is still alive for the rest of its bounded sleep -
# a self-inflicted false positive one run later, proven by the local
# re-run that flagged the previous run's loop child. The fake children
# themselves are never touched: they exit on their own when the sleep
# ends, and with no pidfile naming them no scan can find them.
unlink $runner_pidfile;
unlink File::Spec->catfile( $loop_dir, 'loop.json' );

# The real scan: the shared state base. Any orphan found here fails the
# test, which trips the existing fail-fast/fail-safe and terminates the
# job through the existing mechanism - no separate monitor is needed.
# Nothing found is killed, stopped, or removed: it stays in place as
# evidence for the investigation.
my $real_base = $paths->state_base_root;
my @orphans = _scan_state_base( $real_base, $runner, $manager );
for my $orphan (@orphans) {
    my $age = defined $orphan->{heartbeat_age} ? $orphan->{heartbeat_age} . 's' : 'unknown';
    my $stuck = $orphan->{kind} eq 'supervisor' && defined $orphan->{heartbeat_age} && $orphan->{heartbeat_age} > $SUPERVISOR_STUCK_HEARTBEAT_AGE
      ? ' STUCK (heartbeat stale)'
      : '';
    diag( sprintf 'detector: ORPHAN %s %s pid %s root %s heartbeat age %s%s',
        $orphan->{kind}, $orphan->{name} || '-', $orphan->{pid}, $orphan->{root}, $age, $stuck );
}
is( scalar @orphans, 0, 'detector: no orphaned collector processes left behind after the run' );

# The process-list scan. The state-root scan above can only find a
# process through a pid file, and skips every root whose home directory
# exists. Both missed real leftovers (22 Nov 2026): 39 order-probe loops
# on the Linux box had no pid file at all, and every leftover supervisor
# had put its own home back by writing its log. This scan looks at the
# live process table instead.
my $LEFTOVER_MIN_AGE_MARGIN = 120;
my $min_age = ( time - $^T ) + $LEFTOVER_MIN_AGE_MARGIN;

# Controls for the process-list scan, on the snapshot taken while the
# fake children were alive.
ok( ref($control_rows) eq 'ARRAY' && scalar @{$control_rows}, 'detector: the process table is readable' );
my %control_row = map { $_->{pid} => $_ } @{ $control_rows || [] };
my ( $sup_row, $loop_row, $plain_row ) = @control_row{ $sup_pid, $loop_pid, $plain_pid };
is( _leftover_kind( $manager, $sup_row ),  'supervisor', 'detector: the process table shows the fake supervisor as a supervisor' );
is( _leftover_kind( $manager, $loop_row ), 'loop',       'detector: the process table shows the fake loop as a loop' );
ok( $plain_row && !defined _leftover_kind( $manager, $plain_row ), 'detector: the process table shows the plain child as nothing of ours' );
{
    my $temp_origin = File::Spec->catdir( File::Spec->tmpdir, 't994-origin' );
    my $from_temp   = sub { $temp_origin };
    my $old         = $min_age + 3600;
    my @live = grep { defined } ( $sup_row, $loop_row, $plain_row );
    my ( $found, $unresolved ) = _leftovers_in_rows( \@live, $manager, $min_age, $from_temp );
    is( scalar( @{$found} ) + scalar( @{$unresolved} ), 0, 'detector: process scan ignores this run\'s own young children' );

    my @orphaned = map { +{ %{ $_ || { pid => 1, args => '' } }, parentless => 1, age => $old } } ( $sup_row, $loop_row, $plain_row );
    ( $found, $unresolved ) = _leftovers_in_rows( \@orphaned, $manager, $min_age, $from_temp );
    is_deeply( [ sort map { $_->{kind} } @{$found} ], [ 'loop', 'supervisor' ], 'detector: process scan flags an old parentless supervisor and loop from temp space, not the plain process' );

    my @web = ( { pid => $sup_pid, uid => $<, parentless => 1, age => $old, args => 'starman master' } );
    delete $web[0]{uid} if $IS_WINDOWS;
    ( $found, $unresolved ) = _leftovers_in_rows( \@web, $manager, $min_age, $from_temp );
    is( scalar @{$found}, 1, 'detector: process scan flags an old parentless web master from temp space' );

    ( $found, $unresolved ) = _leftovers_in_rows( [ { %{ $orphaned[0] }, parentless => 0 } ], $manager, $min_age, $from_temp );
    is( scalar( @{$found} ) + scalar( @{$unresolved} ), 0, 'detector: process scan ignores a supervisor whose parent is alive' );

    {
        my $marked = _mark_unix_parentless(
            [
                { pid => 1,   ppid => 0,   age => 90000, args => 'init' },
                { pid => 500, ppid => 1,   age => 9000,  args => 'adopter' },
                { pid => 601, ppid => 1,   age => $old,  args => 'handed to pid 1' },
                { pid => 602, ppid => 777, age => $old,  args => 'parent not in the table' },
                { pid => 603, ppid => 604, age => $old,  args => 'parent started after it' },
                { pid => 604, ppid => 500, age => 5,     args => 'young reused pid' },
                { pid => 605, ppid => 500, age => 60,    args => 'live child of a live older parent' },
            ]
        );
        my %mark = map { $_->{pid} => $_->{parentless} } @{$marked};
        is( $mark{601}, 1, 'detector: Unix rule calls a process whose parent is pid 1 parentless' );
        is( $mark{602}, 1, 'detector: Unix rule calls a process whose parent is not in the table parentless' );
        is( $mark{603}, 1, 'detector: Unix rule calls a process whose parent started after it parentless' );
        is( $mark{605}, 0, 'detector: Unix rule leaves a live child of a live older parent alone' );
    }

    ( $found, $unresolved ) = _leftovers_in_rows( [ { %{ $orphaned[0] }, age => $min_age } ], $manager, $min_age, $from_temp );
    is( scalar( @{$found} ) + scalar( @{$unresolved} ), 0, 'detector: process scan ignores a supervisor that is not old enough' );

    my $real_home = $IS_WINDOWS ? 'C:\\Users\\someone\\project' : '/home/someone/project';
    ( $found, $unresolved ) = _leftovers_in_rows( [ $orphaned[0] ], $manager, $min_age, sub { $real_home } );
    is( scalar( @{$found} ) + scalar( @{$unresolved} ), 0, 'detector: process scan ignores a supervisor that does not come from temp space' );

    ( $found, $unresolved ) = _leftovers_in_rows( [ $orphaned[0] ], $manager, $min_age, sub { undef } );
    ok( scalar( @{$found} ) == 0 && scalar( @{$unresolved} ) == 1, 'detector: process scan reports, but does not flag, a supervisor whose origin cannot be read' );

    ok( _origin_is_temp($temp_origin) && !_origin_is_temp($real_home), 'detector: the temp-space rule tells the temp dir from a home directory' );
}

# The real process-list scan. Any leftover found fails the test, exactly
# like the state-root scan. Nothing found is killed, stopped, or removed.
my $scan_rows = _process_table();
ok( ref($scan_rows) eq 'ARRAY' && scalar @{$scan_rows}, 'detector: the process table is readable for the real scan' );
my ( $leftovers, $unreadable ) = _leftovers_in_rows( $scan_rows, $manager, $min_age, \&_process_origin );
for my $leftover ( @{$leftovers} ) {
    diag( sprintf 'detector: LEFTOVER %s pid %s parent %s started %ss ago from %s title [%s]',
        $leftover->{kind}, $leftover->{pid}, $leftover->{ppid}, $leftover->{age}, $leftover->{origin}, $leftover->{args} );
}
for my $candidate ( @{$unreadable} ) {
    diag( sprintf 'detector: NOTE %s pid %s started %ss ago title [%s] has no live parent but its origin could not be read, so it is not counted',
        $candidate->{kind}, $candidate->{pid}, $candidate->{age}, $candidate->{args} );
}
is( scalar @{$leftovers}, 0, 'detector: no parentless supervisor, loop or web process from an earlier test run is alive on this machine' );

done_testing();

__END__

=head1 NAME

t/994-orphan-collector-detector.t - fail the suite when orphaned collector processes are left behind

=head1 PURPOSE

Detect collector processes (supervisor, worker, loop) left behind after
a run and fail the test when one is found, so the existing fail-fast and
fail-safe terminate the job through the existing mechanism. The test
only detects: it never kills, stops, or removes anything it finds, so
the orphans stay in place as evidence for the investigation. Detection
reuses the product's own identity checks (the supervisor check and the
managed-loop check), so a bare pidfile never condemns a process - the
pid must still be the collector that recorded it. A state root is a
dead run when its runtime.json names a home directory that no longer
exists, the same rule the Housekeeper's own stale-root check uses, and
a root whose home still exists is skipped outright, so a live run, a
concurrent build, or a test that keeps its home can never be flagged.

That state-root scan alone proved blind to the leftovers that actually
formed, so a second scan reads the live process table. It flags every
supervisor, loop ("d2 collector: <name>") or web process (a managed web
process or a Starman master) of this user that has no live parent,
started more than two minutes before this test file did, and comes from
temporary space - its working directory on Unix, its command line on
Windows. Tests run with a throwaway home under the temp dir and people
do not, so a person's own running dashboard is never flagged.

=head1 WHY IT EXISTS

Round 25 failed on ARM64 t/05 test 360 because 19 orphaned "d2
collector supervisor" processes plus a spinning housekeeper loop had
accumulated on the Pi from earlier fail-fast-killed runs, some ten
hours old. Nothing in the suite noticed them: each run just got slower
until a timing test broke, and the orphans were only found by hand
afterwards. A detector in the suite itself turns that silent pile-up
into a loud failure at the point it happens, with the orphan's pid,
state root and heartbeat age in the output for the investigation.

On 22 Nov 2026 the first version passed on three machines that held 49,
73 and 11 leftovers. It found a process only through a pid file, and 39
leftover order-probe loops had none; and it skipped every state root
whose home directory existed, while every leftover supervisor had put
its home back by writing its own log. The process-list scan closes both
holes: it needs no pid file and no state root.

=head1 WHEN TO USE

It runs as part of the normal suite (prove runs files in lexical order,
so t/994 runs near the end, after the serve tests). Run it as a Jenkins
solo (TEST_FILE=t/994-orphan-collector-detector.t) to check one leg, or
read its diag lines in a full run to see exactly which orphans it
found. Never run it by hand against a live home: it reads the shared
state base, which is where every run on the machine keeps its roots.

=head1 HOW TO USE

No setup: the test builds its own throwaway home, spawns three fake
collector-shaped children (supervisor, loop, plain) that sleep a bounded
time and exit on their own, and runs five controls against fake state
roots before the real scan. The controls prove the detection logic in
both directions - live supervisor and live loop in a dead run are
flagged, a dead pid, a live home, and a live foreign process are not.
The process-list controls then check that the live process table shows
the fake supervisor and loop as what they are and the plain child as
nothing, that this run's own young children are never flagged, and, on
copies of those rows, that an old parentless supervisor, loop and web
master from temp space are flagged while one with a live parent, one
that is too young, and one from outside temp space are not. Four more
check the Unix parentless rule on made-up rows: parent pid 1, parent not
in the table and parent started after the child are parentless, a live
child of a live older parent is not.
When a real scan finds orphans, the test fails and diags each one
(kind, name, pid, state root, heartbeat age, and STUCK when a
supervisor heartbeat is stale; for the process-list scan kind, pid,
parent, age, origin and title). A candidate whose origin cannot be read
is reported as a NOTE and not counted. Do not delete what it reports:
they are the evidence, and are only cleaned up once the mechanism is
proven and the fix is in.

=head1 WHAT USES IT

Nothing in the product uses this file. It is a permanent suite test for
the orphan problem, in the testing-v1 loop. The fail-fast and fail-safe
in the Jenkins job terminate the run when it fails; no separate monitor
watches for orphans.

=head1 EXAMPLES

On a clean machine the test passes with twenty-five assertions: the
fake children are alive, the state-root controls agree and that scan
finds no orphans, the process-list controls agree and that scan finds
no leftovers. On a machine with leftovers it fails with diag lines like
"ORPHAN supervisor - pid 3010488 root
/tmp/tester/developer-dashboard/state/728eaf... heartbeat age 642s
STUCK (heartbeat stale)" from the state-root scan, or "LEFTOVER loop
pid 167522 parent 1 started 290000s ago from /tmp/JRlybSMOB0 title
[d2 collector: order-probe]" from the process-list scan, naming exactly
what to investigate.

=cut
