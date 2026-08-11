#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Test::More;
use Time::HiRes qw(sleep time);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform ();

plan skip_all => 'the Windows command-timeout simulation needs POSIX signals and fork'
  if Developer::Dashboard::Platform::is_windows();

# Hermetic runtime rooted at a throwaway home. The runtime root resolves from the
# deepest .developer-dashboard layer discovered from the current working
# directory, so the test must chdir into the temp home before building objects.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    paths      => $paths,
);

# Stand-in for the Windows tree killer. taskkill /PID <pid> /T /F destroys the
# named process and every descendant, so the POSIX stand-in signals the whole
# process group the spawned command leads and then the command itself.
my $fake_bin = File::Spec->catdir( $home, 'fake-windows-bin' );
make_path($fake_bin);
{
    my $taskkill = File::Spec->catfile( $fake_bin, 'taskkill' );
    open my $fh, '>', $taskkill or die "Unable to write $taskkill: $!";
    print {$fh} <<'SH';
#!/bin/sh
# Emulate `taskkill /PID <pid> /T /F`: kill the whole subtree, then the process.
kill -9 -"$2" 2>/dev/null
kill -9 "$2" 2>/dev/null
exit 0
SH
    close $fh or die "Unable to close $taskkill: $!";
    chmod 0755, $taskkill or die "Unable to chmod $taskkill: $!";
}

# spawn_marked_command_tree($marker_file, $seconds)
# Forks a session-leading stand-in for a Windows command shell that records
# itself and one descendant before blocking, so the timeout assertions can prove
# the whole subtree is gone rather than only the direct child.
# Input: path the pids are recorded to and how long the tree blocks.
# Output: the session-leading child pid.
sub spawn_marked_command_tree {
    my ( $marker_file, $seconds ) = @_;
    my $child = fork();
    die "Unable to fork the stand-in Windows command: $!" if !defined $child;
    if ( !$child ) {
        POSIX::setsid();
        $| = 1;
        my $descendant = fork();
        POSIX::_exit(1) if !defined $descendant;
        if ( !$descendant ) {
            sleep $seconds;
            POSIX::_exit(0);
        }
        open my $fh, '>', $marker_file or POSIX::_exit(1);
        print {$fh} "$$ $descendant\n";
        close $fh or POSIX::_exit(1);
        print "command-stdout-ready\n";
        print STDERR "command-stderr-ready\n";
        sleep $seconds;
        POSIX::_exit(0);
    }
    return $child;
}

# read_marked_pids($marker_file)
# Waits for the stand-in command tree to publish its pids and returns them.
# Input: marker file path.
# Output: list of the command pid and its descendant pid.
sub read_marked_pids {
    my ($marker_file) = @_;
    for ( 1 .. 500 ) {
        last if -s $marker_file;
        sleep 0.01;
    }
    open my $fh, '<', $marker_file or die "Unable to read $marker_file: $!";
    my $line = <$fh>;
    close $fh or die "Unable to close $marker_file: $!";
    my ( $command_pid, $descendant_pid ) = ( $line || '' ) =~ /^(\d+)\s+(\d+)/;
    die "The stand-in Windows command never published its pids" if !$command_pid;
    return ( $command_pid, $descendant_pid );
}

# await_absent_pids(@pids)
# Waits briefly for terminated pids to disappear so the assertions do not race
# the kernel's own teardown.
# Input: pid list.
# Output: true value.
sub await_absent_pids {
    my (@pids) = @_;
    for ( 1 .. 500 ) {
        last if !grep { kill 0, $_ } @pids;
        sleep 0.01;
    }
    return 1;
}

# ===========================================================================
# DD-389 acceptance: a blocked native-Windows command collector must still be
# interrupted at its timeout.
#
# Windows dispatches Perl's SIGALRM emulation only at operation boundaries, so
# an alarm() armed around a synchronous system() never interrupts the wait and
# the collector runs until the command exits on its own. The simulation blocks
# SIGALRM for real on this POSIX host, which reproduces exactly that failure
# mode: the alarm still expires, but its handler can never run.
# ===========================================================================
{
    my $marker_file = File::Spec->catfile( $home, 'blocked-windows-command.pids' );
    my @spawned_argv;
    my $command_pid;

    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_command = sub {
        my ( undef, @argv ) = @_;
        push @spawned_argv, [@argv];
        $command_pid = spawn_marked_command_tree( $marker_file, 20 );
        return $command_pid;
    };
    use warnings 'redefine';

    local $ENV{PATH} = "$fake_bin:$ENV{PATH}";

    # Discard the alarm the POSIX path would have armed: with SIGALRM blocked it
    # stays pending, and the default disposition would kill this test process
    # when the mask is restored.
    local $SIG{ALRM} = 'IGNORE';
    my $blocked  = POSIX::SigSet->new( POSIX::SIGALRM() );
    my $restored = POSIX::SigSet->new;
    POSIX::sigprocmask( POSIX::SIG_BLOCK(), $blocked, $restored )
      or die "Unable to block SIGALRM: $!";

    my $started = time();
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => 'dd389-blocked-command',
        cwd        => $home,
        timeout_ms => 200,
    );
    my $elapsed = time() - $started;

    POSIX::sigprocmask( POSIX::SIG_SETMASK(), $restored )
      or die "Unable to restore the signal mask: $!";

    cmp_ok( $elapsed, '<', 10,
        'a blocked Windows command collector returns at its timeout instead of waiting for the command to exit' );
    is( $exit_code, 124, 'a timed-out Windows command collector reports exit code 124' );
    ok( $timed_out, 'a timed-out Windows command collector is flagged as timed out' );
    like( $stdout, qr/command-stdout-ready/, 'stdout written before the Windows timeout stays captured' );
    like( $stderr, qr/command-stderr-ready/, 'stderr written before the Windows timeout stays captured' );
    is( scalar @spawned_argv, 1, 'the Windows path spawns the command exactly once' );
    is_deeply(
        $spawned_argv[0],
        [ Developer::Dashboard::Platform::shell_command_argv( 'dd389-blocked-command', login => 0 ) ],
        'the Windows path spawns the resolved shell argv without the POSIX pid-file launcher',
    );

    my ( $marked_pid, $descendant_pid ) = read_marked_pids($marker_file);
    is( $marked_pid, $command_pid, 'the spawned Windows command pid is the process the runner polls' );
    await_absent_pids( $marked_pid, $descendant_pid );
    ok( !kill( 0, $marked_pid ), 'the timed-out Windows command process is terminated' );
    ok( !kill( 0, $descendant_pid ), 'the timed-out Windows command descendant is terminated' );
}

# ===========================================================================
# _await_windows_command: a command that finishes before the deadline keeps its
# own exit code, and the pid it was given is published for signal forwarding.
# ===========================================================================
{
    my $pidfile = File::Spec->catfile( $home, 'completed-windows-command.pid' );
    my $child   = fork();
    die "Unable to fork the stand-in Windows command: $!" if !defined $child;
    if ( !$child ) {
        sleep 0.3;
        POSIX::_exit(7);
    }

    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_command = sub { return $child };
    use warnings 'redefine';

    my ( $exit_code, $timed_out ) =
      $runner->_await_windows_command( $pidfile, 30_000, 'dd389-completed-command' );
    is( $exit_code, 7, '_await_windows_command preserves the exit code of a command that finished in time' );
    is( $timed_out, 0, '_await_windows_command does not flag a command that finished in time' );
    is( $runner->_command_pid_from_file($pidfile), $child,
        '_await_windows_command publishes the spawned pid through the launcher pid file' );
    unlink $pidfile;
}

# ===========================================================================
# _await_windows_command: an unspawnable command is an explicit failure, never a
# silent success.
# ===========================================================================
{
    my $pidfile = File::Spec->catfile( $home, 'unspawnable-windows-command.pid' );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_command = sub { return -1 };
    use warnings 'redefine';

    my $error = eval { $runner->_await_windows_command( $pidfile, 1000, 'dd389-unspawnable' ); 1 } ? '' : $@;
    like( $error, qr/Unable to spawn collector command/,
        '_await_windows_command dies when the asynchronous spawn fails' );
    ok( !-e $pidfile, 'a failed Windows spawn records no command pid' );
}

# ===========================================================================
# _await_windows_command: a process the runner does not own can never be waited
# for, so the poll reports that instead of spinning to the deadline.
# ===========================================================================
{
    my $pidfile = File::Spec->catfile( $home, 'unowned-windows-command.pid' );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_command = sub { return 999_999_999 };
    use warnings 'redefine';

    my $error = eval { $runner->_await_windows_command( $pidfile, 30_000, 'dd389-unowned' ); 1 } ? '' : $@;
    like( $error, qr/Unable to wait for collector command process 999999999/,
        '_await_windows_command dies when the spawned command cannot be waited for' );
    unlink $pidfile;
}

# ===========================================================================
# _spawn_windows_command: the asynchronous system() spawn form. On this POSIX
# host the leading 1 is resolved as the program name, so a stand-in named `1`
# proves the argv reaches the operating system exactly as written.
# ===========================================================================
{
    my $spawn_log = File::Spec->catfile( $home, 'async-spawn.log' );
    my $stub      = File::Spec->catfile( $fake_bin, '1' );
    open my $fh, '>', $stub or die "Unable to write $stub: $!";
    print {$fh} "#!/bin/sh\nprintf '%s\\n' \"\$@\" > '$spawn_log'\nexit 0\n";
    close $fh or die "Unable to close $stub: $!";
    chmod 0755, $stub or die "Unable to chmod $stub: $!";

    local $ENV{PATH} = "$fake_bin:$ENV{PATH}";
    my $spawned = $runner->_spawn_windows_command( 'dd389-shell', '-c', 'dd389 body' );
    is( $spawned, 0, '_spawn_windows_command returns the numeric spawn result' );

    open my $log_fh, '<', $spawn_log or die "Unable to read $spawn_log: $!";
    my @passed = <$log_fh>;
    close $log_fh or die "Unable to close $spawn_log: $!";
    chomp @passed;
    is_deeply( \@passed, [ 'dd389-shell', '-c', 'dd389 body' ],
        '_spawn_windows_command hands the command argv to the operating system unshelled' );
    unlink $stub;
}

# ===========================================================================
# _record_command_pid: the pid file the POSIX launcher writes for itself is the
# same file the Windows path publishes, and an unwritable path is explicit.
# ===========================================================================
{
    my $pidfile = File::Spec->catfile( $home, 'recorded-windows-command.pid' );
    ok( $runner->_record_command_pid( $pidfile, 4242 ), '_record_command_pid reports success' );
    is( $runner->_command_pid_from_file($pidfile), 4242,
        '_record_command_pid writes a pid the launcher pid-file reader accepts' );
    unlink $pidfile;

    my $unwritable = File::Spec->catfile( $home, 'no-such-dir', 'command.pid' );
    my $error = eval { $runner->_record_command_pid( $unwritable, 4242 ); 1 } ? '' : $@;
    like( $error, qr/Unable to write collector command pid file/,
        '_record_command_pid dies when the pid file cannot be written' );
}

# The close of a written pid file can genuinely fail: the buffered integer is
# only flushed at close time, so a full device reports ENOSPC there rather than
# at open or print. /dev/full provides that deterministically, which keeps the
# failure branch covered by a real test instead of an annotation.
SKIP: {
    skip 'this host has no writable /dev/full to provoke a close-time ENOSPC', 1
      if !-w '/dev/full';

    my $close_error = eval { $runner->_record_command_pid( '/dev/full', 4243 ); 1 } ? '' : $@;
    like( $close_error, qr/Unable to close collector command pid file/,
        '_record_command_pid dies when the pid file cannot be flushed at close' );
}

done_testing();

__END__

=head1 NAME

t/122-collectorrunner-windows-timeout.t

=head1 PURPOSE

Pins the native-Windows command-collector timeout contract: a command that
blocks past its timeout is interrupted, reported as exit code 124 with the
timed-out flag, has its whole process subtree terminated, and keeps the output
it produced before the deadline. It also closes the branch and condition
coverage of the asynchronous spawn, the pid publication, and the bounded poll
loop that implement it.

=head1 WHY IT EXISTS

Windows only dispatches Perl's C<alarm> emulation at operation boundaries, so
the C<SIGALRM> timeout that guards the POSIX collector command never fires while
a synchronous C<system()> waits for the command. A hung Windows command
collector therefore ran until the command exited on its own, however long that
took, and the configured timeout was silently meaningless.

The failure cannot be reproduced by simply forcing the Windows platform flag,
because POSIX hosts deliver C<SIGALRM> perfectly well. This file reproduces the
real defect instead: it blocks C<SIGALRM> with C<sigprocmask> so the alarm still
expires but its handler can never run, which is precisely what the caller
observes on Windows. Any implementation that depends on the alarm to interrupt
the command fails here.

=head1 WHEN TO USE

Run it when changing the collector command execution path, the Windows spawn or
process-tree termination, the launcher pid-file contract, or the collector
timeout semantics.

=head1 HOW TO USE

Run it directly from a source checkout:

  perl -Ilib t/122-collectorrunner-windows-timeout.t

It builds its own throwaway home, chdirs into it so the runtime layer resolves
hermetically, and installs POSIX stand-ins for the Windows C<taskkill> tree
killer and for the asynchronous C<system()> spawn on a private C<PATH>. Nothing
beyond a writable temp directory, C<fork>, and POSIX signals is required.

=head1 WHAT USES IT

The repository test harness runs it as part of C<prove -lr t>, and the coverage
gate consumes it when measuring C<Developer::Dashboard::CollectorRunner>. It is
the Windows companion of the collector-runner bug hunt and the two
collector-runner coverage files, which own the POSIX launcher, the signal
forwarding, and the subtree termination.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/122-collectorrunner-windows-timeout.t

Run the Windows command-timeout regression on its own.

Example 2:

  prove -lv t/53-hunt-collectorrunner.t t/103-collectorrunner-coverage.t t/115-collectorrunner-coverage-2.t t/122-collectorrunner-windows-timeout.t

Run the whole collector-runner command-execution set after editing the timeout,
spawn, or termination paths.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -l t/122-collectorrunner-windows-timeout.t

Confirm the asynchronous spawn, the pid publication, and every arm of the
bounded poll loop are genuinely recorded rather than merely exercised.

Example 4:

  prove -lr t

Put any change to the collector runner back through the whole suite before
release.

=cut
