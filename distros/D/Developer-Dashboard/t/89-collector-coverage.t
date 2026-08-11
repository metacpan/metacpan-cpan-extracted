#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Fcntl qw(:flock);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(strftime);
use Test::More;

# $FAIL_FLOCK is a test-controlled switch for the CORE::GLOBAL::flock override
# installed below. The override has to be compiled before
# Developer::Dashboard::Collector so the module's own flock call resolves
# through it; while the switch is off every call delegates to the real flock so
# unrelated locking keeps working.
our $FAIL_FLOCK;

BEGIN {
    *CORE::GLOBAL::flock = sub {
        return 0 if $FAIL_FLOCK;
        return CORE::flock( $_[0], $_[1] );
    };
}

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

{
    # Test::Collector::FixedRoots is a minimal path-registry stand-in that
    # reports a caller-supplied collector-root list verbatim. The real registry
    # creates and re-chmods every root each time it is asked for them, so it can
    # never report a root that is missing or unreadable; this stand-in can, which
    # is what the layered-listing guards in list_collectors are there to survive.
    package Test::Collector::FixedRoots;

    # new(@roots)
    # Constructs the fixed-root path registry stand-in.
    # Input: ordered collector root directory path strings.
    # Output: Test::Collector::FixedRoots object.
    sub new {
        my ( $class, @roots ) = @_;
        return bless { roots => [@roots] }, $class;
    }

    # collectors_roots()
    # Returns the fixed collector roots in lookup order.
    # Input: none.
    # Output: ordered list of collector root directory path strings.
    sub collectors_roots {
        my ($self) = @_;
        return @{ $self->{roots} };
    }
}

# Hermetic runtime: a throwaway home, a throwaway state root, and a working
# directory inside that home so the deepest runtime layer resolves from the cwd.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths     = Developer::Dashboard::PathRegistry->new( home => $home );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );

# seed_collector($name, %files)
# Writes raw collector artifacts straight into the deepest layer's collector
# directory so a precise persisted-state shape can be exercised.
# Input: collector name string and a map of collector-relative filename to content.
# Output: collector directory path string.
sub seed_collector {
    my ( $name, %files ) = @_;
    my $dir = $paths->collector_dir($name);
    for my $file ( sort keys %files ) {
        my $path = File::Spec->catfile( $dir, $file );
        open my $fh, '>:raw', $path or die "Unable to write $path: $!";
        print {$fh} $files{$file} or die "Unable to write $path: $!";
        close $fh or die "Unable to close $path: $!";
    }
    return $dir;
}

# dies_like($code, $pattern, $label)
# Runs a code reference that is expected to die and asserts the failure message.
# Input: code reference, expected message regexp, and assertion label string.
# Output: none.
sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $lived = eval { $code->(); 1 };
    ok( !$lived, $label );
    like( $@, $pattern, "$label reports the expected failure" );
    return;
}

# ---------------------------------------------------------------------------
# write_result: status-callback contract, explicit result fields, and the
# previous-status carry-over rules for run counters and success/failure stamps.
# ---------------------------------------------------------------------------
{
    my $name = 'alpha';

    dies_like(
        sub { $collector->write_result( $name, exit_code => 0, status_callback => 'nope' ) },
        qr/Collector status callback must be a code reference/,
        'write_result rejects a status callback that is not a code reference',
    );

    # Fresh collector: no previous status at all.
    $collector->write_result( $name, exit_code => 0, stdout => "ok\n" );
    my $first = $collector->read_status($name);
    is( $first->{last_success}, 1, 'a zero exit code records a successful run' );
    is( $first->{active_runs}, 0, 'a fresh successful run keeps the active-run count at zero' );
    ok( !defined $first->{last_failure_at}, 'a fresh successful run has no recorded failure timestamp' );
    ok( !defined $first->{last_started_at}, 'a fresh run without a started_at has no recorded start timestamp' );

    # A failure after a success must keep the earlier success timestamp.
    $collector->write_result( $name, exit_code => 3, stderr => "boom\n" );
    my $failed = $collector->read_status($name);
    is( $failed->{last_success}, 0, 'a non-zero exit code records a failed run' );
    is( $failed->{last_success_at}, $first->{last_success_at}, 'a failed run preserves the previous success timestamp' );
    ok( defined $failed->{last_failure_at}, 'a failed run records a failure timestamp' );

    # A success after a failure must keep the earlier failure timestamp.
    $collector->write_result( $name, exit_code => 0 );
    my $recovered = $collector->read_status($name);
    is( $recovered->{last_failure_at}, $failed->{last_failure_at}, 'a recovered run preserves the previous failure timestamp' );

    # An explicit started_at wins over the stored one, and once stored it is
    # carried forward by later results that do not supply one.
    $collector->write_result( $name, exit_code => 0, started_at => 'START-1' );
    is( $collector->read_status($name)->{last_started_at}, 'START-1', 'an explicit started_at is recorded' );
    $collector->write_result( $name, exit_code => 0 );
    is( $collector->read_status($name)->{last_started_at}, 'START-1', 'a later result carries the stored start timestamp forward' );

    # Explicit lifecycle fields in the result take priority over everything else.
    $collector->write_result(
        $name,
        exit_code     => 0,
        enabled       => 0,
        running       => 1,
        active_runs   => 4,
        output_format => 'json',
        timed_out     => 1,
    );
    my $explicit = $collector->read_status($name);
    is( $explicit->{enabled}, 0, 'an explicit enabled field is honoured' );
    is( $explicit->{running}, 1, 'an explicit running field is honoured' );
    is( $explicit->{active_runs}, 4, 'an explicit active_runs field is honoured' );
    is( $explicit->{output_format}, 'json', 'the output format is recorded' );
    is( $explicit->{timed_out}, 1, 'a timed-out run is flagged' );

    # With no explicit counter and no callback contribution the stored count wins.
    $collector->write_result( $name, exit_code => 0 );
    is( $collector->read_status($name)->{active_runs}, 4, 'a result without counters carries the stored active-run count forward' );
    is( $collector->read_status($name)->{timed_out}, 0, 'a result without a timeout clears the timed-out flag' );

    # A callback may contribute the lifecycle counters instead.
    $collector->write_result(
        $name,
        exit_code       => 0,
        status_callback => sub {
            my ($previous) = @_;
            is( ref($previous), 'HASH', 'the status callback receives the previous status hash reference' );
            return { running => 1, active_runs => 2, note => 'from-callback' };
        },
    );
    my $extra = $collector->read_status($name);
    is( $extra->{active_runs}, 2, 'a callback-supplied active-run count is merged' );
    is( $extra->{running}, 1, 'a callback-supplied running flag is merged' );
    is( $extra->{note}, 'from-callback', 'callback-only fields are merged into the status' );

    # A callback that returns nothing contributes no extra fields.
    $collector->write_result( $name, exit_code => 0, status_callback => sub { return } );
    my $empty = $collector->read_status($name);
    is( $empty->{running}, 0, 'a callback that returns nothing leaves the running flag cleared' );
    is( $empty->{active_runs}, 2, 'a callback that returns nothing keeps the stored active-run count' );
}

# ---------------------------------------------------------------------------
# write_status merges a partial status, and tolerates an omitted one.
# ---------------------------------------------------------------------------
{
    my $name = 'gamma';
    $collector->write_status( $name, { flag => 'on' } );
    is( $collector->read_status($name)->{flag}, 'on', 'write_status merges the supplied fields' );
    $collector->write_status( $name, undef );
    is( $collector->read_status($name)->{flag}, 'on', 'write_status without a status hash preserves the stored fields' );
}

# ---------------------------------------------------------------------------
# update_status argument validation and lock-acquisition failures.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->update_status( undef, sub { {} } ) }, qr/Missing collector name/, 'update_status rejects an undefined collector name' );
    dies_like( sub { $collector->update_status( '', sub { {} } ) }, qr/Missing collector name/, 'update_status rejects an empty collector name' );
    dies_like( sub { $collector->update_status( 'delta', 'nope' ) }, qr/Missing collector status callback/, 'update_status rejects a callback that is not a code reference' );
    dies_like( sub { $collector->update_status( 'delta', sub { return 'nope' } ) }, qr/must return a hash reference/, 'update_status rejects a callback that does not return a hash reference' );

    my $written = $collector->update_status( 'delta', sub { return { ok => 1 } } );
    is( $written, $collector->collector_paths('delta')->{status}, 'update_status returns the written status file path' );
}

# The status lock file cannot be opened when its path is already a directory.
{
    my $name = 'lockdir';
    my $dir  = $paths->collector_dir($name);
    my $lock = File::Spec->catdir( $dir, '.status.lock' );
    mkdir $lock or die "Unable to create $lock: $!";
    dies_like(
        sub { $collector->write_status( $name, { flag => 1 } ) },
        qr/Unable to open \Q$lock\E/,
        'update_status dies when the status lock file cannot be opened',
    );
    rmdir $lock or die "Unable to remove $lock: $!";
}

# A lock that cannot be taken must surface, never silently merge unlocked.
{
    my $name = 'flocky';
    $collector->write_status( $name, { seeded => 1 } );

    my $lived;
    {
        local $FAIL_FLOCK = 1;
        $lived = eval { $collector->write_status( $name, { flag => 1 } ); 1 };
    }
    ok( !$lived, 'update_status dies when the status lock cannot be acquired' );
    like( $@, qr/Unable to lock/, 'the failed lock reports the lock file' );
    ok( !exists $collector->read_status($name)->{flag}, 'a failed lock leaves the stored status untouched' );
}

# ---------------------------------------------------------------------------
# mark_run_started / mark_run_finished keep an accurate active-run count.
# ---------------------------------------------------------------------------
{
    my $name = 'beta';
    $collector->mark_run_started($name);
    my $one = $collector->read_status($name);
    is( $one->{active_runs}, 1, 'the first start raises the active-run count to one' );
    ok( !defined $one->{last_started_at}, 'a start without a start timestamp records none' );

    $collector->mark_run_started( $name, { last_started_at => 'T1', pid => 4242 } );
    my $two = $collector->read_status($name);
    is( $two->{active_runs}, 2, 'a second overlapping start raises the active-run count to two' );
    is( $two->{last_started_at}, 'T1', 'a start with a start timestamp records it' );
    is( $two->{pid}, 4242, 'a start merges the supplied partial status' );

    $collector->mark_run_started($name);
    is( $collector->read_status($name)->{last_started_at}, 'T1', 'a start without a timestamp keeps the stored one' );
}

{
    my $name = 'epsilon';
    $collector->mark_run_finished( $name, exit_code => 0 );
    my $idle = $collector->read_status($name);
    is( $idle->{active_runs}, 0, 'finishing a run that never started keeps the active-run count at zero' );
    is( $idle->{running}, 0, 'finishing a run that never started reports the collector as not running' );

    $collector->mark_run_started($name);
    $collector->mark_run_finished( $name, exit_code => 0, stdout => "done\n" );
    my $done = $collector->read_status($name);
    is( $done->{active_runs}, 0, 'finishing the only live run drops the active-run count back to zero' );
    is( $done->{running}, 0, 'finishing the only live run reports the collector as not running' );

    # Overlapping runs: one worker finishing must not clear the other live one.
    $collector->mark_run_started($name);
    $collector->mark_run_started($name);
    $collector->mark_run_finished( $name, exit_code => 0 );
    my $overlapped = $collector->read_status($name);
    is( $overlapped->{active_runs}, 1, 'finishing one of two overlapping runs leaves the other counted' );
    is( $overlapped->{running}, 1, 'finishing one of two overlapping runs keeps the collector reported as running' );
}

# A collector whose very first run fails has no earlier success to carry over.
{
    my $name = 'fail-first';
    $collector->write_result( $name, exit_code => 9, stderr => "nope\n" );
    my $status = $collector->read_status($name);
    is( $status->{last_success}, 0, 'a first-ever failing run is recorded as unsuccessful' );
    ok( !defined $status->{last_success_at}, 'a first-ever failing run records no success timestamp' );
    ok( defined $status->{last_failure_at}, 'a first-ever failing run records a failure timestamp' );
}

# ---------------------------------------------------------------------------
# mark_stopped resets the consumer-facing counters.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->mark_stopped(undef) }, qr/Missing collector name/, 'mark_stopped rejects an undefined collector name' );
    dies_like( sub { $collector->mark_stopped('') }, qr/Missing collector name/, 'mark_stopped rejects an empty collector name' );
    is( $collector->mark_stopped('never-ran'), undef, 'mark_stopped is a no-op for a collector with no status file' );

    $collector->mark_run_started('zeta');
    ok( $collector->mark_stopped('zeta'), 'mark_stopped writes a status file for a started collector' );
    my $stopped = $collector->read_status('zeta');
    is( $stopped->{running}, 0, 'mark_stopped clears the running flag' );
    is( $stopped->{active_runs}, 0, 'mark_stopped clears the active-run count' );
    ok( defined $stopped->{stopped_at}, 'mark_stopped records when the collector was stopped' );
}

# ---------------------------------------------------------------------------
# collector_exists spans the layered roots.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->collector_exists(undef) }, qr/Missing collector name/, 'collector_exists rejects an undefined collector name' );
    dies_like( sub { $collector->collector_exists('') }, qr/Missing collector name/, 'collector_exists rejects an empty collector name' );
    ok( $collector->collector_exists('alpha'), 'collector_exists finds a persisted collector' );
    ok( !$collector->collector_exists('no-such-collector'), 'collector_exists rejects an unknown collector' );
}

# ---------------------------------------------------------------------------
# read_job reads the stored job, and surfaces an unreadable one.
# ---------------------------------------------------------------------------
{
    my $name = 'lockedjob';
    $collector->write_job( $name, { name => $name, command => 'true' } );
    my $file = $collector->collector_paths($name)->{job};

    chmod 0000, $file or die "Unable to chmod $file: $!";
    dies_like(
        sub { $collector->read_job($name) },
        qr/Unable to read \Q$file\E/,
        'read_job dies when the stored job file cannot be opened',
    );
    chmod 0600, $file or die "Unable to chmod $file: $!";

    is( $collector->read_job($name)->{command}, 'true', 'read_job decodes the stored job definition' );
    is( $collector->read_job('no-such-collector'), undef, 'read_job returns undef when no job file exists' );
}

# ---------------------------------------------------------------------------
# read_output tolerates a persisted-but-empty artifact.
# ---------------------------------------------------------------------------
{
    my $name = 'emptyout';
    seed_collector( $name, 'stdout' => '', 'last_run' => '' );
    my $output = $collector->read_output($name);
    is( $output->{last_run}, '', 'an empty last_run artifact reads back as an empty string' );
    is( $output->{stdout}, '', 'an empty stdout artifact reads back as an empty string' );
    is( $output->{stderr}, '', 'a missing stderr artifact reads back as an empty string' );

    is( $collector->read_log($name), '', 'a collector with only empty artifacts renders no log entry' );
}

{
    my $name = 'trimmed';
    seed_collector( $name, 'last_run' => "2026-01-01T00:00:00Z\n" );
    is( $collector->read_output($name)->{last_run}, '2026-01-01T00:00:00Z', 'the last_run marker is read back without its trailing newline' );
}

# An artifact that exists but errors on read leaves the output value undefined.
# /proc/self/mem is a regular file that reports EIO on a read from offset zero,
# which is the one hermetic way to reach that path: it is exactly the case the
# defined() guards in read_output and _log_payload_present are there to survive.
SKIP: {
    skip 'requires /proc/self/mem to force an artifact read error', 3
      if !-f '/proc/self/mem';

    my $name    = 'unreadable-artifact';
    my $dir     = $paths->collector_dir($name);
    my $symlink = 1;
    for my $file (qw(stdout last_run)) {
        $symlink &&= symlink( '/proc/self/mem', File::Spec->catfile( $dir, $file ) );
    }
    skip "unable to symlink /proc/self/mem: $!", 3 if !$symlink;

    my $output = $collector->read_output($name);
    ok( !defined $output->{last_run}, 'an unreadable last_run artifact reads back as undefined' );
    ok( !defined $output->{stdout}, 'an unreadable stdout artifact reads back as undefined' );
    is( $collector->read_log($name), '', 'an unreadable artifact is not mistaken for log payload' );
}

# ---------------------------------------------------------------------------
# append_log_entry formatting and log-file failures.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->append_log_entry(undef) }, qr/Missing collector name/, 'append_log_entry rejects an undefined collector name' );
    dies_like( sub { $collector->append_log_entry('') }, qr/Missing collector name/, 'append_log_entry rejects an empty collector name' );

    my $name = 'logfmt';
    $collector->append_log_entry($name);
    like( $collector->read_log($name), qr/\@ unknown-time/, 'an entry without a timestamp is logged as unknown-time' );

    $collector->append_log_entry( $name, happened_at => '2026-01-01T00:00:00Z', source => '' );
    $collector->append_log_entry( $name, happened_at => '2026-01-01T00:00:01Z', error => '' );
    my $blank = $collector->read_log($name);
    unlike( $blank, qr/source=/, 'an empty source is not added to the entry header' );
    unlike( $blank, qr/\[error\]/, 'an empty error is not rendered as an error section' );

    $collector->append_log_entry(
        $name,
        happened_at => '2026-01-01T00:00:02Z',
        exit_code   => 2,
        timed_out   => 1,
        stdout      => 'out-without-newline',
        stderr      => "err\n",
        error       => 'boom',
        source      => 'unit-test',
    );
    my $full = $collector->read_log($name);
    like( $full, qr/exit=2 \| timed_out=1 \| source=unit-test ===/, 'a fully populated entry header is rendered' );
    like( $full, qr/\[stdout\]\nout-without-newline\n/, 'stdout is rendered with a normalized trailing newline' );
    like( $full, qr/\[stderr\]\nerr\n/, 'stderr is rendered in its own section' );
    like( $full, qr/\[error\]\nboom\n/, 'an error is rendered in its own section' );
    is( sprintf( '%04o', ( stat $collector->collector_paths($name)->{log} )[2] & 07777 ), '0600', 'serialized log appends keep the collector log owner-only' );
    my $lock = File::Spec->catfile( $collector->collector_paths($name)->{dir}, '.log.lock' );
    is( sprintf( '%04o', ( stat $lock )[2] & 07777 ), '0600', 'the collector log lock is owner-only' );
}

{
    my $name = 'logdir';
    my $dir  = $paths->collector_dir($name);
    my $log  = File::Spec->catfile( $dir, 'log' );
    mkdir $log or die "Unable to create $log: $!";
    dies_like(
        sub { $collector->append_log_entry( $name, happened_at => '2026-01-01T00:00:00Z' ) },
        qr/Unable to append \Q$log\E/,
        'append_log_entry dies when the log file cannot be opened for append',
    );
    rmdir $log or die "Unable to remove $log: $!";
}

# Log mutations surface lock-file open and acquisition failures without writing.
{
    my $name = 'log-lockdir';
    my $dir  = $paths->collector_dir($name);
    my $lock = File::Spec->catdir( $dir, '.log.lock' );
    mkdir $lock or die "Unable to create $lock: $!";
    dies_like(
        sub { $collector->append_log_entry( $name, happened_at => '2026-01-01T00:00:00Z' ) },
        qr/Unable to open \Q$lock\E/,
        'append_log_entry dies when the shared log lock file cannot be opened',
    );
    rmdir $lock or die "Unable to remove $lock: $!";
}

{
    my $name = 'log-flocky';
    my $lived;
    {
        local $FAIL_FLOCK = 1;
        $lived = eval { $collector->append_log_entry( $name, happened_at => '2026-01-01T00:00:00Z' ); 1 };
    }
    ok( !$lived, 'append_log_entry dies when the shared log lock cannot be acquired' );
    like( $@, qr/Unable to lock/, 'the failed shared log lock reports the lock file' );
    ok( !-f $collector->collector_paths($name)->{log}, 'a failed shared log lock leaves the collector log untouched' );
}

# A rotation that has already read its input must serialize with a concurrent
# append instead of replacing the newly appended entry with its stale snapshot.
{
    my $name = 'log-rotation-race';
    seed_collector( $name, 'log' => "old-line\nkept-line\n" );

    pipe my $ready_r, my $ready_w or die "Unable to create rotation-ready pipe: $!";
    pipe my $release_r, my $release_w or die "Unable to create rotation-release pipe: $!";
    my $apply_rotation = \&Developer::Dashboard::Collector::_apply_log_rotation;
    my $rotation_pid = fork();
    die "Unable to fork log rotation child: $!" if !defined $rotation_pid;
    if ( !$rotation_pid ) {
        close $ready_r;
        close $release_w;
        no warnings 'redefine';
        local *Developer::Dashboard::Collector::_apply_log_rotation = sub {
            syswrite $ready_w, 'R' or POSIX::_exit(91);
            my $released = '';
            sysread $release_r, $released, 1 or POSIX::_exit(92);
            return $apply_rotation->(@_);
        };
        eval { $collector->rotate_log( $name, { lines => 1 } ); 1 }
          or POSIX::_exit(93);
        POSIX::_exit(0);
    }
    close $ready_w;
    close $release_r;
    my $ready = '';
    sysread $ready_r, $ready, 1 or die 'Rotation child exited before reading its log snapshot';

    my $lock = File::Spec->catfile( $collector->collector_paths($name)->{dir}, '.log.lock' );
    open my $probe_fh, '>>', $lock or die "Unable to open log-lock probe $lock: $!";
    my $rotation_holds_lock = !flock( $probe_fh, LOCK_EX | LOCK_NB );
    flock( $probe_fh, LOCK_UN ) if !$rotation_holds_lock;

    pipe my $appended_r, my $appended_w or die "Unable to create append-complete pipe: $!";
    my $append_pid = fork();
    die "Unable to fork log append child: $!" if !defined $append_pid;
    if ( !$append_pid ) {
        close $appended_r;
        eval {
            $collector->append_log_entry(
                $name,
                happened_at => '2026-07-29T12:00:00Z',
                stdout      => "concurrent-marker\n",
            );
            1;
        } or POSIX::_exit(94);
        syswrite $appended_w, 'A' or POSIX::_exit(95);
        POSIX::_exit(0);
    }
    close $appended_w;

    my $appended = '';
    sysread $appended_r, $appended, 1
      if !$rotation_holds_lock;
    syswrite $release_w, 'G' or die 'Unable to release paused log rotation';
    sysread $appended_r, $appended, 1
      if $rotation_holds_lock;

    waitpid( $rotation_pid, 0 );
    is( $? >> 8, 0, 'the coordinated log rotation child exits cleanly' );
    waitpid( $append_pid, 0 );
    is( $? >> 8, 0, 'the coordinated log append child exits cleanly' );
    like( $collector->read_log($name), qr/concurrent-marker/, 'a concurrent append survives a rotation that already read its input snapshot' );
}

dies_like( sub { $collector->_format_log_entry( name => '' ) }, qr/Missing collector name/, '_format_log_entry rejects an empty collector name' );

# ---------------------------------------------------------------------------
# read_log falls back to a rendered snapshot of the latest persisted state.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->read_log(undef) }, qr/Missing collector name/, 'read_log rejects an undefined collector name' );
    dies_like( sub { $collector->read_log('') }, qr/Missing collector name/, 'read_log rejects an empty collector name' );
    is( $collector->read_log('no-such-collector'), '', 'read_log returns nothing for a collector that does not exist' );
}

{
    my $name = 'snap-output';
    seed_collector(
        $name,
        'stdout'      => "snap-out\n",
        'stderr'      => "snap-err\n",
        'last_run'    => "2026-02-01T00:00:00Z\n",
        'status.json' => json_encode( { name => $name, last_exit_code => 0, timed_out => 1 } ),
    );
    my $log = $collector->read_log($name);
    like( $log, qr/\@ 2026-02-01T00:00:00Z/, 'the snapshot log uses the persisted last_run marker' );
    like( $log, qr/source=latest state snapshot/, 'the snapshot log marks itself as rendered from state' );
    like( $log, qr/\[stdout\]\nsnap-out\n/, 'the snapshot log renders the persisted stdout' );
    like( $log, qr/\[stderr\]\nsnap-err\n/, 'the snapshot log renders the persisted stderr' );
}

{
    my $name = 'snap-status-run';
    seed_collector(
        $name,
        'stdout'      => "body\n",
        'status.json' => json_encode( { name => $name, last_run => '2026-03-01T00:00:00Z' } ),
    );
    like( $collector->read_log($name), qr/\@ 2026-03-01T00:00:00Z/, 'the snapshot log falls back to the status last_run' );
}

{
    my $name = 'snap-completed';
    seed_collector(
        $name,
        'stdout'      => "body\n",
        'status.json' => json_encode( { name => $name, last_completed_at => '2026-04-01T00:00:00Z' } ),
    );
    like( $collector->read_log($name), qr/\@ 2026-04-01T00:00:00Z/, 'the snapshot log falls back to the status completion time' );
}

{
    my $name = 'snap-started';
    seed_collector(
        $name,
        'stdout'      => "body\n",
        'status.json' => json_encode( { name => $name, last_started_at => '2026-05-01T00:00:00Z' } ),
    );
    like( $collector->read_log($name), qr/\@ 2026-05-01T00:00:00Z/, 'the snapshot log falls back to the status start time' );
}

{
    my $name = 'snap-untimed';
    seed_collector( $name, 'status.json' => json_encode( { name => $name, last_exit_code => 0 } ) );
    my $log = $collector->read_log($name);
    like( $log, qr/\@ unknown-time/, 'a snapshot with no timestamps at all is rendered as unknown-time' );
    like( $log, qr/exit=0/, 'a snapshot with only an exit code still renders that exit code' );
}

# ---------------------------------------------------------------------------
# list_collectors across layered roots.
# ---------------------------------------------------------------------------
{
    my $proj = File::Spec->catdir( $home, 'proj' );
    make_path( File::Spec->catdir( $proj, '.developer-dashboard' ) );
    my $layered_paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $proj );
    my $layered = Developer::Dashboard::Collector->new( paths => $layered_paths );
    my @roots = $layered_paths->collectors_roots;
    is( scalar @roots, 2, 'a project layer adds a second collector root' );

    $collector->write_status( 'dup', { marker => 'home' } );
    $layered->write_status( 'dup', { marker => 'project' } );

    my %listed = map { $_->{name} => $_ } $layered->list_collectors;
    is( $listed{dup}{marker}, 'project', 'the deepest layer wins for a collector present in two roots' );
    ok( exists $listed{alpha}, 'collectors that only exist in the home layer are still listed' );
}

# A root that is missing, and a root that cannot be opened, are both skipped.
{
    my $base       = tempdir( CLEANUP => 1 );
    my $missing    = File::Spec->catdir( $base, 'missing-root' );
    my $unreadable = File::Spec->catdir( $base, 'unreadable-root' );
    my $usable     = File::Spec->catdir( $base, 'usable-root' );
    make_path( File::Spec->catdir( $unreadable, 'hidden' ) );
    make_path( File::Spec->catdir( $usable, 'visible' ) );
    open my $fh, '>:raw', File::Spec->catfile( $usable, 'visible', 'status.json' )
      or die "Unable to seed the usable root: $!";
    print {$fh} json_encode( { name => 'visible', running => 0 } ) or die "Unable to seed the usable root: $!";
    close $fh or die "Unable to seed the usable root: $!";

    chmod 0000, $unreadable or die "Unable to chmod $unreadable: $!";
    my $fixed = Developer::Dashboard::Collector->new(
        paths => Test::Collector::FixedRoots->new( $missing, $unreadable, $usable ),
    );
    my @listed = $fixed->list_collectors;
    chmod 0700, $unreadable or die "Unable to chmod $unreadable: $!";

    is( scalar @listed, 1, 'list_collectors skips a missing root and an unreadable root' );
    is( $listed[0]{name}, 'visible', 'list_collectors still reports the collectors it can read' );
}

# ---------------------------------------------------------------------------
# inspect_collector combines the three stored views.
# ---------------------------------------------------------------------------
{
    my $name = 'inspected';
    $collector->write_job( $name, { name => $name, command => 'true' } );
    $collector->write_result( $name, exit_code => 0, stdout => "inspect-me\n" );

    my $inspected = $collector->inspect_collector($name);
    is( $inspected->{job}{command}, 'true', 'inspect_collector returns the stored job definition' );
    is( $inspected->{output}{stdout}, "inspect-me\n", 'inspect_collector returns the stored output artifacts' );
    is( $inspected->{status}{last_success}, 1, 'inspect_collector returns the stored status metadata' );
}

# ---------------------------------------------------------------------------
# rotate_log configuration validation.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->rotate_log( undef, {} ) }, qr/Missing collector name/, 'rotate_log rejects an undefined collector name' );
    dies_like( sub { $collector->rotate_log( '', {} ) }, qr/Missing collector name/, 'rotate_log rejects an empty collector name' );
    dies_like( sub { $collector->rotate_log( 'alpha', 'nope' ) }, qr/must be a hash reference/, 'rotate_log rejects a rotation that is not a hash reference' );
    dies_like( sub { $collector->rotate_log( 'alpha', { bogus => 1 } ) }, qr/rotation key bogus for alpha is not supported/, 'rotate_log rejects an unknown rotation key' );
    dies_like( sub { $collector->rotate_log( 'alpha', { lines => undef } ) }, qr/rotation lines for alpha must be a non-negative integer/, 'rotate_log rejects an undefined rotation value' );
    dies_like( sub { $collector->rotate_log( 'alpha', { lines => 'abc' } ) }, qr/rotation lines for alpha must be a non-negative integer/, 'rotate_log rejects a non-numeric rotation value' );

    is( $collector->rotate_log( 'alpha', undef ), undef, 'rotate_log without a rotation configuration does nothing' );
    is( $collector->rotate_log( 'alpha', {} ), undef, 'rotate_log with an empty rotation configuration does nothing' );
    is( $collector->rotate_log( 'no-log-yet', { lines => 5 } ), undef, 'rotate_log does nothing when there is no log file' );
}

# A rotation that keeps everything must not rewrite the log.
{
    my $name  = 'rot-noop';
    my $entry = $collector->_format_log_entry( name => $name, happened_at => '2026-01-01T00:00:00Z', exit_code => 0 );
    seed_collector( $name, 'log' => $entry );
    is( $collector->rotate_log( $name, { lines => 500 } ), undef, 'a rotation that changes nothing reports no rotation' );
    is( $collector->read_log($name), $entry, 'a rotation that changes nothing leaves the log untouched' );
}

# A line-based rotation keeps only the trailing lines.
{
    my $name = 'rot-lines';
    seed_collector( $name, 'log' => "l1\nl2\nl3\nl4\n" );
    my $rotated = $collector->rotate_log( $name, { lines => 2 } );
    is( $rotated->{kind}, 'collector-log-rotation', 'a line rotation reports a collector log rotation' );
    is( $rotated->{strategy}, 'lines=2', 'a line rotation reports its strategy' );
    is( $rotated->{before_bytes}, 12, 'a line rotation reports the original size' );
    is( $rotated->{after_bytes}, 6, 'a line rotation reports the rotated size' );
    is( $collector->read_log($name), "l3\nl4\n", 'a line rotation keeps only the trailing lines' );
}

# A time-based rotation with an explicit clock keeps only recent entries.
{
    my $name = 'rot-age-fixed';
    my $old  = $collector->_format_log_entry( name => $name, happened_at => '2019-01-01T00:00:00Z', exit_code => 0 );
    my $new  = $collector->_format_log_entry( name => $name, happened_at => '2020-01-01T00:00:00Z', exit_code => 0 );
    seed_collector( $name, 'log' => $old . $new );
    my $rotated = $collector->rotate_log( $name, { minutes => 5 }, now_epoch => 1_577_836_800 );
    is( $rotated->{strategy}, 'minutes=5', 'an age rotation reports its strategy' );
    is( $collector->read_log($name), $new, 'an age rotation drops the entries outside the retention window' );
}

# Two time units combine into one retention window, and the clock defaults to now.
{
    my $name   = 'rot-age-now';
    my $recent = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( time() ) );
    my $old    = $collector->_format_log_entry( name => $name, happened_at => '2019-01-01T00:00:00Z', exit_code => 0 );
    my $new    = $collector->_format_log_entry( name => $name, happened_at => $recent, exit_code => 0 );
    seed_collector( $name, 'log' => $old . $new );
    my $rotated = $collector->rotate_log( $name, { hours => 1, minutes => 30 } );
    is( $rotated->{strategy}, 'hours=1,minutes=30', 'combined time units are reported as one strategy' );
    is( $collector->read_log($name), $new, 'combined time units retain only the entries inside the window' );
}

# An unparsable entry must be reported, not silently discarded.
{
    my $name = 'rot-bad';
    seed_collector( $name, 'log' => "=== collector rot-bad | \@ not-a-timestamp ===\n\n" );
    dies_like(
        sub { $collector->rotate_log( $name, { minutes => 5 } ) },
        qr/Unable to parse collector log timestamp for rot-bad/,
        'rotate_log dies on a log entry whose timestamp cannot be parsed',
    );
}

# A combined line + age rotation must cut on entry boundaries. The line trim
# runs after the age trim, so a purely line-based cut used to leave an orphaned
# entry body at the front of the log; the very next rotation pass then died on
# that headerless chunk and the housekeeper stopped for good.
{
    my $name = 'rot-combined';

    # combined_log($count)
    # Builds a collector log blob of five-line entries for the combined-rotation checks.
    # Input: number of entries to format.
    # Output: log text string holding that many formatted entries.
    my $combined_log = sub {
        my ($count) = @_;
        return join '', map {
            $collector->_format_log_entry(
                name        => $name,
                happened_at => sprintf( '2026-07-%02dT00:00:00Z', 20 + $_ ),
                exit_code   => 0,
                stdout      => "body-$_-line-a\nbody-$_-line-b\n",
            )
        } 1 .. $count;
    };

    my $now      = 1_785_000_000;
    my $newest   = $collector->_format_log_entry(
        name        => $name,
        happened_at => '2026-07-24T00:00:00Z',
        exit_code   => 0,
        stdout      => "body-4-line-a\nbody-4-line-b\n",
    );

    # Every entry is five lines, so a six-line budget deliberately cuts inside
    # the second-newest entry and keeps only its trailing blank separator.
    seed_collector( $name, 'log' => $combined_log->(4) );
    my $rotation = { lines => 6, days => 3650 };
    my $rotated  = $collector->rotate_log( $name, $rotation, now_epoch => $now );
    is( $rotated->{strategy}, 'days=3650,lines=6', 'a combined age and line rotation reports both rules in one strategy' );
    is( $collector->read_log($name), $newest, 'a combined rotation keeps whole entries instead of slicing one in half' );

    is( $collector->rotate_log( $name, $rotation, now_epoch => $now ), undef, 'a second combined rotation pass finds nothing left to rotate' );
    is( $collector->read_log($name), $newest, 'a second combined rotation pass leaves the entry-aligned log untouched' );

    # A budget that lands exactly on an entry boundary needs no realignment.
    seed_collector( $name, 'log' => $combined_log->(4) );
    $collector->rotate_log( $name, { lines => 5, days => 3650 }, now_epoch => $now );
    is( $collector->read_log($name), $newest, 'a line budget that lands on an entry boundary keeps that entry verbatim' );

    # A budget smaller than a single entry cannot keep any whole entry, so the
    # transcript empties out rather than persisting a headerless fragment.
    seed_collector( $name, 'log' => $combined_log->(4) );
    $collector->rotate_log( $name, { lines => 4, days => 3650 }, now_epoch => $now );
    is( $collector->read_log($name), '', 'a line budget smaller than one entry empties the log instead of orphaning a body' );
}

# A log that was already headerless before rotation was corrupted outside the
# rotation path: keep its content and let the age trim keep failing loudly.
{
    my $name = 'rot-foreign';
    seed_collector( $name, 'log' => "f1\nf2\nf3\nf4\n" );
    $collector->rotate_log( $name, { lines => 2 } );
    is( $collector->read_log($name), "f3\nf4\n", 'a line rotation of an externally headerless log keeps its trailing lines' );

    dies_like(
        sub { $collector->rotate_log( $name, { lines => 2, days => 1 } ) },
        qr/Unable to parse collector log timestamp for rot-foreign/,
        'a combined rotation of an externally headerless log still fails loudly',
    );
}

# ---------------------------------------------------------------------------
# Rotation helpers in isolation.
# ---------------------------------------------------------------------------
{
    is( $collector->_trim_log_by_age( 'x', "text\n", undef ), "text\n", '_trim_log_by_age without a retention window returns the text unchanged' );
    is( $collector->_trim_log_by_age( 'x', '', 60 ), '', '_trim_log_by_age on an empty log returns an empty log' );

    is( $collector->_trim_log_by_lines( '', 3 ), '', '_trim_log_by_lines on an empty log returns an empty log' );
    is( $collector->_trim_log_by_lines( "a\nb\n", 9 ), "a\nb\n", '_trim_log_by_lines keeps a log shorter than the limit' );
    is( $collector->_trim_log_by_lines( "a\nb\nc\n", 2 ), "b\nc\n", '_trim_log_by_lines keeps the trailing lines of a newline-terminated log' );
    is( $collector->_trim_log_by_lines( "a\nb\nc", 2 ), "b\nc", '_trim_log_by_lines keeps the trailing lines of a log with no trailing newline' );

    my $one   = "=== collector one | \@ 2026-01-01T00:00:00Z ===\nbody-one\n\n";
    my $two   = "=== collector two | \@ 2026-01-02T00:00:00Z ===\nbody-two\n\n";
    my $split = $one . $two;
    is( $collector->_trim_log_by_lines( $split, 4 ), $two, '_trim_log_by_lines realigns a cut that lands inside an entry' );
    is( $collector->_trim_log_by_lines( $split, 3 ), $two, '_trim_log_by_lines keeps a cut that already lands on an entry header' );
    is( $collector->_trim_log_by_lines( $split, 2 ), '', '_trim_log_by_lines returns an empty log when no whole entry fits the line budget' );
    is( $collector->_trim_log_by_lines( $split, 0 ), '', '_trim_log_by_lines with a zero line budget returns an empty log' );

    is( $collector->_realign_to_entry_boundary( $split, $two ), $two, '_realign_to_entry_boundary leaves a header-anchored cut alone' );
    is( $collector->_realign_to_entry_boundary( $split, "body-one\n\n$two" ), $two, '_realign_to_entry_boundary drops an orphaned entry body' );
    is( $collector->_realign_to_entry_boundary( "x\ny\n", "y\n" ), "y\n", '_realign_to_entry_boundary keeps a log that was already headerless before the cut' );

    is( scalar( () = $collector->_split_log_entries(undef) ), 0, '_split_log_entries returns nothing for an undefined log' );
    is( scalar( () = $collector->_split_log_entries('') ), 0, '_split_log_entries returns nothing for an empty log' );
    my @entries = $collector->_split_log_entries(
        "=== collector a | \@ 2026-01-01T00:00:00Z ===\n\n=== collector b | \@ 2026-01-02T00:00:00Z ===\n\n" );
    is( scalar @entries, 2, '_split_log_entries splits one blob into its entries' );

    dies_like(
        sub { $collector->_entry_timestamp_epoch( 'x', "no header at all\n" ) },
        qr/Unable to parse collector log timestamp for x/,
        '_entry_timestamp_epoch dies on an entry with no parsable header',
    );
}

# ---------------------------------------------------------------------------
# Timestamp parsing.
# ---------------------------------------------------------------------------
{
    dies_like( sub { $collector->_iso8601_to_epoch('nope') }, qr/Unsupported collector log timestamp nope/, '_iso8601_to_epoch rejects an unsupported timestamp' );
    is( $collector->_iso8601_to_epoch('2020-01-01T00:00:00Z'), 1_577_836_800, '_iso8601_to_epoch parses a UTC timestamp' );
    is( $collector->_iso8601_to_epoch('2020-01-01T00:00:00+0100'), 1_577_833_200, '_iso8601_to_epoch applies a positive compact offset' );
    is( $collector->_iso8601_to_epoch('2020-01-01T00:00:00-05:00'), 1_577_854_800, '_iso8601_to_epoch applies a negative colon-separated offset' );
}

# ---------------------------------------------------------------------------
# Text helpers.
# ---------------------------------------------------------------------------
{
    is( Developer::Dashboard::Collector::_with_trailing_newline(undef), "\n", '_with_trailing_newline turns undef into a bare newline' );
    is( Developer::Dashboard::Collector::_with_trailing_newline('x'), "x\n", '_with_trailing_newline appends a missing newline' );
    is( Developer::Dashboard::Collector::_with_trailing_newline("x\n"), "x\n", '_with_trailing_newline leaves an existing newline alone' );
}

{
    my $outside = tempdir( CLEANUP => 1 );
    my $missing = File::Spec->catfile( $outside, 'missing' );
    is( Developer::Dashboard::Collector::_slurp($missing), '', '_slurp returns an empty string for a missing file' );

    my $file = File::Spec->catfile( $outside, 'unreadable' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} "kept\n" or die "Unable to write $file: $!";
    close $fh or die "Unable to close $file: $!";

    chmod 0000, $file or die "Unable to chmod $file: $!";
    dies_like( sub { Developer::Dashboard::Collector::_slurp($file) }, qr/Unable to read \Q$file\E/, '_slurp dies when an existing file cannot be opened' );
    chmod 0600, $file or die "Unable to chmod $file: $!";
    is( Developer::Dashboard::Collector::_slurp($file), "kept\n", '_slurp reads an existing readable file' );
}

# ---------------------------------------------------------------------------
# _read_status_file tolerates junk but surfaces an unreadable file.
# ---------------------------------------------------------------------------
{
    my $name = 'lockedstatus';
    $collector->write_status( $name, { flag => 1 } );
    my $file = $collector->collector_paths($name)->{status};

    chmod 0000, $file or die "Unable to chmod $file: $!";
    dies_like( sub { $collector->_read_status_file($file) }, qr/Unable to read \Q$file\E/, '_read_status_file dies when an existing status file cannot be opened' );
    chmod 0600, $file or die "Unable to chmod $file: $!";
    is( $collector->_read_status_file($file)->{flag}, 1, '_read_status_file decodes a readable status file' );
}

{
    my $name = 'junkstatus';
    seed_collector( $name, 'status.json' => 'not json at all' );
    is( $collector->read_status($name), undef, 'an undecodable status file reads back as undef' );
}

# ---------------------------------------------------------------------------
# _pending_path stages every write under a per-writer temporary name so
# concurrent collector workers cannot share one staging file.
# ---------------------------------------------------------------------------
{
    my $file    = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'combined' );
    my $pending = $collector->_pending_path($file);
    like( $pending, qr/\A\Q$file\E\.\Q$$\E\.[0-9.]+\.pending\z/,
        '_pending_path returns a "<file>.<pid>.<time>.pending" staging path' );
    isnt( $pending, "$file.pending",
        '_pending_path never returns the process-independent shared staging path' );
}

# ---------------------------------------------------------------------------
# _atomic_write_text surfaces a pending file it cannot open or write. The
# staging name is pinned through _pending_path for these two cases so the
# blocking directory and the /dev/full symlink can occupy it; the per-writer
# naming itself is asserted above.
# ---------------------------------------------------------------------------
{
    my $outside = tempdir( CLEANUP => 1 );
    my $target  = File::Spec->catfile( $outside, 'blocked' );
    my $pending = "$target.blocked-open.pending";
    no warnings 'redefine';
    local *Developer::Dashboard::Collector::_pending_path = sub { return $pending };
    use warnings 'redefine';
    mkdir $pending or die "Unable to create $pending: $!";
    dies_like(
        sub { $collector->_atomic_write_text( $target, 'payload' ) },
        qr/Unable to write \Q$pending\E/,
        '_atomic_write_text dies when the pending file cannot be opened',
    );
    rmdir $pending or die "Unable to remove $pending: $!";
}

SKIP: {
    skip 'requires a writable /dev/full to force a write failure', 3
      if !-e '/dev/full' || !-w '/dev/full';

    my $outside = tempdir( CLEANUP => 1 );
    my $target  = File::Spec->catfile( $outside, 'nospace' );
    my $pending = "$target.forced-full.pending";
    no warnings 'redefine';
    local *Developer::Dashboard::Collector::_pending_path = sub { return $pending };
    use warnings 'redefine';

    skip "unable to symlink /dev/full: $!", 3
      if !symlink( '/dev/full', $pending );

    # The payload has to exceed the buffer so the write reaches the device
    # inside print() rather than being deferred to close().
    my @warnings;
    my $lived;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $lived = eval { $collector->_atomic_write_text( $target, 'x' x 200_000 ); 1 };
    }
    ok( !$lived, '_atomic_write_text dies when the pending write cannot be flushed to the device' );
    like( $@, qr/Unable to write \Q$pending\E/, 'the failed write reports the pending file' );
    is( scalar( grep { $_ !~ /unable to close filehandle/i } @warnings ),
        0, 'the failed write emits nothing beyond the interpreter close-failure notice' );

    unlink $pending if -l $pending;
}

# ---------------------------------------------------------------------------
# new() and new_from_all_folders().
# ---------------------------------------------------------------------------
{
    dies_like( sub { Developer::Dashboard::Collector->new }, qr/Missing paths registry/, 'new requires a paths registry' );
    isa_ok( Developer::Dashboard::Collector->new_from_all_folders, 'Developer::Dashboard::Collector' );
}

done_testing;

__END__

=head1 NAME

t/89-collector-coverage.t - branch and condition closure for the collector store

=head1 PURPOSE

This test drives every decision point in
C<Developer::Dashboard::Collector>: status-callback validation, the
previous-status carry-over rules for run counters and success/failure stamps,
layered collector-root listing, log formatting, log retention, ISO-8601
timestamp parsing, the per-writer staging name every atomic write is built on,
and the failure paths of the atomic write and slurp helpers. It exists to hold
the collector store at 100% on the branch and condition coverage metrics as
well as statement and subroutine.

=head1 WHY IT EXISTS

The collector store is the only writer of collector state, and its hard cases
are exactly the ones ordinary runs never reach: a lock that cannot be taken, a
status file that cannot be read, a pending file that cannot be flushed, a
retention rule that trims nothing, a runtime layer whose root has gone away. Those
paths decide whether a stale "running" flag survives a crash or whether a
truncated file is published as fact, so they need executable proof rather than a
coverage waiver. This file supplies that proof, forcing the failures with a
flock override, directories parked on file paths, unreadable modes, and
C</dev/full>.

=head1 WHEN TO USE

Use this file when changing collector on-disk layout, status JSON fields, the
active-run accounting in mark_run_started/mark_run_finished, log entry
formatting, log rotation rules, or the layered root lookup order.

=head1 HOW TO USE

Run C<prove -lv t/89-collector-coverage.t> while iterating on the collector
store, then keep it green under C<prove -lr t>. To confirm the coverage
contract it defends, run the repository coverage gate and check that
C<lib/Developer/Dashboard/Collector.pm> reports 100.0 for statement,
subroutine, branch, and condition.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file, alongside
C<t/54-hunt-collector.t> which owns the atomic-rename durability regressions,
and C<t/07-core-units.t> which owns the collector unit behaviour shared with the
runner.

=head1 EXAMPLES

Example 1:

  prove -lv t/89-collector-coverage.t

Run the collector coverage closure checks on their own.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run the whole suite under the coverage gate this file was written to close.

Example 3:

  cover -report text -select_re 'Collector\.pm' -coverage branch -coverage condition

Report just the collector store's branch and condition coverage after that run.

Example 4:

  prove -lr t

Put any collector change back through the entire suite before release.

=cut
