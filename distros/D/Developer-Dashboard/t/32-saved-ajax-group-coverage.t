#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Time::HiRes ();

use lib 'lib';

use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform ();
use Developer::Dashboard qw(spawn wait_process);

plan skip_all => 'POSIX saved-Ajax process-group units do not run on Windows'
  if Developer::Dashboard::Platform::is_windows();

# Hermetic, isolated runtime: an empty HOME that is also the CWD so any layer
# discovery resolves under the throwaway directory and never the real home.
my $home = tempdir( CLEANUP => 1 );
my $repo_root = cwd();
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
isa_ok( $runtime, 'Developer::Dashboard::PageRuntime', 'hermetic page runtime constructs under the temp home' );

# Safety net: any fixture process that outlives a failed assertion is removed
# so a failing run never leaks a sleeping child behind the harness.
my @cleanup_pids;
END {
    for my $pid ( grep { defined $_ && $_ =~ /^\d+$/ && $_ > 0 } @cleanup_pids ) {
        kill 9, $pid if kill 0, $pid;
    }
}

# _spawn_reaped_child()
# Starts and reaps a short-lived Perl process through the exported GoRoutine
# API, returning a pid that is guaranteed dead for deterministic cleanup tests.
# Input: none.
# Output: reaped child pid integer.
sub _spawn_reaped_child {
    my $pid = spawn( [ $^X, '-e', 'exit 0;' ], {} );
    die "GoRoutine spawn failed: $!" if !defined $pid;
    wait_process($pid);
    return $pid;
}

# _exec_failure_in_child($command)
# Drives the launcher's failed-exec path in an independent Perl process and hands the
# exception text back to the harness.
# The exec attempt must never happen in the harness process. Devel::Cover
# writes its run and stops recording the moment a process attempts an exec,
# because it expects the process to be replaced; a failed exec leaves the
# process running but blind, so every assertion after it in this file would
# pass while contributing nothing to the coverage gate. The child is a
# throwaway, so losing its recording after the exec attempt costs nothing.
# Input: absolute path of a command that cannot be executed.
# Output: exception text the launcher died with, or the empty string.
sub _exec_failure_in_child {
    my ($command) = @_;
    my $error_file = File::Spec->catfile( $home, 'failed-exec-error.txt' );
    my $source = q{
        use Capture::Tiny qw(capture);
        use Developer::Dashboard::PageRuntime;
        local $Developer::Dashboard::PageRuntime::SETPGID = sub { return '0 but true' };
        my $error = '';
        capture {
            eval { Developer::Dashboard::PageRuntime->_exec_saved_ajax_command($ARGV[0]); 1 };
            $error = $@;
        };
        open my $fh, '>', $ARGV[1] or die $!;
        print {$fh} $error or die $!;
        close $fh or die $!;
    };
    my @include = map { '-I' . File::Spec->catdir( $repo_root, $_ ) } qw(lib blib/lib blib/arch);
    my $pid = spawn( [ $^X, @include, '-e', $source, $command, $error_file ], { cwd => $home } );
    die "GoRoutine spawn failed: $!" if !defined $pid;
    my $status = wait_process($pid);
    die "Failed-exec child exited unsuccessfully: $status" if $status != 0;
    open my $fh, '<', $error_file or die "Unable to read child error '$error_file': $!";
    my $error = do { local $/; <$fh> } // '';
    close $fh or die "Unable to close child error '$error_file': $!";
    return $error;
}

# ---- _saved_ajax_launch_command: guard, Windows identity, POSIX wrapper ------
{
    eval { $runtime->_saved_ajax_launch_command(); 1 };
    like( $@, qr/Missing saved ajax command/, '_saved_ajax_launch_command dies without an argv' );

    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        is_deeply(
            [ $runtime->_saved_ajax_launch_command( 'cmd.exe', '/c', 'echo hi' ) ],
            [ 'cmd.exe', '/c', 'echo hi' ],
            '_saved_ajax_launch_command keeps the Windows argv unchanged',
        );
    }

    my @wrapped = $runtime->_saved_ajax_launch_command( 'echo', 'hi' );
    is( $wrapped[0], $^X, '_saved_ajax_launch_command wraps POSIX runs with the current perl' );
    is( $wrapped[1], '-MDeveloper::Dashboard::PageRuntime', '_saved_ajax_launch_command loads PageRuntime into the launcher' );
    is( $wrapped[2], '-e', '_saved_ajax_launch_command uses an inline launcher body' );
    like( $wrapped[3], qr/_exec_saved_ajax_command\(\@ARGV\)/, '_saved_ajax_launch_command routes through the process-group exec helper' );
    is_deeply( [ @wrapped[ 4 .. $#wrapped ] ], [ 'echo', 'hi' ], '_saved_ajax_launch_command preserves the original argv after the launcher' );
}

# ---- _own_saved_ajax_process_group: Windows zero, guard, POSIX identity ------
{
    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        is( $runtime->_own_saved_ajax_process_group(12345), 0, '_own_saved_ajax_process_group records no group on Windows' );
    }

    eval { $runtime->_own_saved_ajax_process_group(0); 1 };
    like( $@, qr/Missing saved ajax process id/, '_own_saved_ajax_process_group dies for a falsy pid' );

    is( $runtime->_own_saved_ajax_process_group($$), $$, '_own_saved_ajax_process_group mirrors the launcher pid as the group id' );
}

# ---- _exec_saved_ajax_command: guard, setpgid failure, exec failure ----------
{
    eval { Developer::Dashboard::PageRuntime->_exec_saved_ajax_command(); 1 };
    like( $@, qr/Missing saved ajax command/, '_exec_saved_ajax_command dies without a command' );

    {
        local $Developer::Dashboard::PageRuntime::SETPGID = sub { return };
        eval { Developer::Dashboard::PageRuntime->_exec_saved_ajax_command('/bin/true'); 1 };
        like( $@, qr/Unable to isolate saved ajax process/, '_exec_saved_ajax_command dies when process-group isolation fails' );
    }

    my $missing = File::Spec->catfile( $home, 'dd396-no-such-binary' );
    my $exec_error = _exec_failure_in_child($missing);
    like( $exec_error, qr/Unable to exec saved ajax command/, '_exec_saved_ajax_command dies when exec cannot start the command' );

    # The real injectable primitive: setpgid(0,0) succeeds in-process (it is a
    # no-op when this test is already its own group leader).
    ok( defined $Developer::Dashboard::PageRuntime::SETPGID->(), 'default SETPGID primitive isolates the calling process successfully' );
}

# ---- _terminate_saved_ajax_process: ownership-condition fallbacks ------------
{
    is( $runtime->_terminate_saved_ajax_process(0), 1, '_terminate_saved_ajax_process returns for a falsy pid' );

    my $dead = _spawn_reaped_child();

    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        is( $runtime->_terminate_saved_ajax_process( $dead, $dead ), 1, '_terminate_saved_ajax_process ignores the recorded group on Windows' );
    }
    is( $runtime->_terminate_saved_ajax_process($dead), 1, '_terminate_saved_ajax_process falls back to direct-pid cleanup without a group' );
    is( $runtime->_terminate_saved_ajax_process( $dead, 'not-a-pid' ), 1, '_terminate_saved_ajax_process rejects a non-numeric group id' );
    is( $runtime->_terminate_saved_ajax_process( $dead, 0 ), 1, '_terminate_saved_ajax_process rejects the zero group recorded by Windows launches' );
    is( $runtime->_terminate_saved_ajax_process( $dead, $dead ), 1, '_terminate_saved_ajax_process completes for an owned group whose pid is already reaped' );
}

# ---- _terminate_saved_ajax_process: live owned group with a descendant -------
{
    my $marker = File::Spec->catfile( $home, "dd396-group-grandchild-$$.txt" );
    my $ready_file = File::Spec->catfile( $home, "dd396-group-ready-$$.txt" );
    my $leader_source = q{
        use Developer::Dashboard::GoRoutine ();
        my ( $marker, $ready ) = @ARGV;
        my $worker_source = q{
            my ($marker) = @ARGV;
            $SIG{TERM} = 'IGNORE';
            open my $fh, '>', $marker or die "Unable to write worker marker: $!";
            print {$fh} "$$\n" or die "Unable to write worker pid: $!";
            close $fh or die "Unable to close worker marker: $!";
            select undef, undef, undef, 30;
        };
        my $worker = Developer::Dashboard::GoRoutine::spawn(
            [ $^X, '-e', $worker_source, $marker ], {},
        );
        die "GoRoutine grandchild launch failed: $!" if !defined $worker;
        open my $fh, '>', $ready or die "Unable to write readiness marker: $!";
        print {$fh} "up\n" or die "Unable to publish readiness: $!";
        close $fh or die "Unable to close readiness marker: $!";
        select undef, undef, undef, 30;
    };
    my $leader = spawn( [ $^X, '-e', $leader_source, $marker, $ready_file ], { process_group => 1 } );
    die "GoRoutine spawn failed: $!" if !defined $leader;
    push @cleanup_pids, $leader;
    ok( _wait_for_marker($ready_file), 'group fixture reports the leader ready after its grandchild started' );
    ok( _wait_for_marker($marker), 'group fixture waits for the grandchild to publish its pid before checking liveness' );

    my $grandchild_pid;
    if ( open my $marker_fh, '<', $marker ) {
        my $line = <$marker_fh> // '';
        close $marker_fh;
        $line =~ s/\s+//g;
        $grandchild_pid = $line =~ /^\d+$/ ? $line + 0 : undef;
    }
    push @cleanup_pids, $grandchild_pid;
    ok( defined $grandchild_pid && kill( 0, $grandchild_pid ), 'group fixture grandchild is alive before termination' );

    is( $runtime->_terminate_saved_ajax_process( $leader, $leader ), 1, '_terminate_saved_ajax_process terminates a live owned process group' );
    waitpid( $leader, 0 );
    ok( !kill( 0, $leader ), '_terminate_saved_ajax_process leaves the group leader dead' );

    my $grandchild_gone = 0;
    for ( 1 .. 100 ) {
        if ( !kill 0, $grandchild_pid ) { $grandchild_gone = 1; last; }
        select undef, undef, undef, 0.05;
    }
    ok( $grandchild_gone, '_terminate_saved_ajax_process kills the TERM-ignoring descendant through the group signal' );
    unlink $marker if -e $marker;
}

# ---- DD-428: the SIGTERM escalation grants a real elapsed grace window -------

# _read_marker_pid($path)
# Reads a pid a fixture descendant recorded in its marker file.
# Input: marker file path.
# Output: pid integer, or undef when the marker holds no pid.
sub _read_marker_pid {
    my ($path) = @_;
    open my $fh, '<', $path or return undef;
    my $line = <$fh> // '';
    close $fh;
    $line =~ s/\s+//g;
    return $line =~ /^\d+$/ ? $line + 0 : undef;
}

# _wait_for_marker($path)
# Waits until a spawned process publishes its readiness marker.
# Input: absolute marker path string.
# Output: true when the marker exists before the bounded deadline.
sub _wait_for_marker {
    my ($path) = @_;
    my $deadline = Time::HiRes::time() + 5;
    while ( !-e $path && Time::HiRes::time() < $deadline ) {
        select undef, undef, undef, 0.01;
    }
    return -e $path ? 1 : 0;
}

# The shipped window is what production actually grants a signalled worker, so
# pin it here: the defect this block guards was a loop that believed it waited
# one second and returned in about a millisecond.
{
    is( $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_GRACE_SECONDS, 1, 'the shipped saved-Ajax SIGTERM grace window is one second' );
    cmp_ok( $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_POLL_SECONDS, '>', 0, 'the grace-window poll interval is positive' );
    cmp_ok(
        $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_POLL_SECONDS, '<',
        $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_GRACE_SECONDS,
        'the grace-window poll interval is shorter than the window it polls',
    );
}

# The status reference threaded into the grace-window wait is documented as
# optional, and both production callers do pass one. The omitted form is still a
# supported call that the process-group scenarios above rely on, so pin it here
# directly instead of leaving the contract to be inferred from them: a future
# refactor that reads the guard as dead defensive code has to fail this first.
{
    my $orphan = spawn( [ $^X, '-e', 'exit 0;' ], {} );
    die "GoRoutine spawn failed: $!" if !defined $orphan;
    push @cleanup_pids, $orphan;
    my $deadline = Time::HiRes::time() + 5;
    while ( !Developer::Dashboard::GoRoutine::process_exited($orphan)
        && Time::HiRes::time() < $deadline )
    {
        select undef, undef, undef, 0.01;
    }
    die "GoRoutine worker did not exit before deadline"
      if !Developer::Dashboard::GoRoutine::process_exited($orphan);

    is( $runtime->_await_saved_ajax_exit( $orphan, undef ), 1, '_await_saved_ajax_exit drains an exited worker with no status reference supplied' );
    is( waitpid( $orphan, WNOHANG ), -1, '_await_saved_ajax_exit reaped the worker it drained without a status reference' );
}

# Scenario: a cooperative worker whose SIGTERM handler needs measurable time to
# reap its children, delete scratch files, and flush partial output.
{
    # A generous window keeps the assertion about returning early from riding on
    # host load: the handler needs 0.3s and the window here is 5s.
    local $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_GRACE_SECONDS = 5;

    my $marker = File::Spec->catfile( $home, "dd428-worker-cleanup-$$.txt" );
    my $ready_file = File::Spec->catfile( $home, "dd428-worker-ready-$$.txt" );
    my $worker_source = q{
        use POSIX ();
        my ( $marker, $ready ) = @ARGV;
        $SIG{TERM} = sub {
            select undef, undef, undef, 0.3;
            open my $marker_fh, '>', $marker or POSIX::_exit(91);
            print {$marker_fh} "cleaned up\n";
            close $marker_fh or POSIX::_exit(92);
            POSIX::_exit(0);
        };
        open my $fh, '>', $ready or die "Unable to write readiness marker: $!";
        print {$fh} "up\n" or die "Unable to publish readiness: $!";
        close $fh or die "Unable to close readiness marker: $!";
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    };
    my $worker = spawn(
        [ $^X, '-e', $worker_source, $marker, $ready_file ],
        { process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $worker;
    push @cleanup_pids, $worker;
    is( _wait_for_marker($ready_file), 1, 'cooperative worker fixture installed its SIGTERM cleanup handler' );

    my $reaped_status;
    my $started = Time::HiRes::time();
    is( $runtime->_terminate_saved_ajax_process( $worker, $worker, \$reaped_status ), 1, '_terminate_saved_ajax_process reports success for a cooperative owned group' );
    my $elapsed = Time::HiRes::time() - $started;

    ok( -e $marker, '_terminate_saved_ajax_process lets the worker SIGTERM handler finish its cleanup before escalating' );
    is( $reaped_status, 0, '_terminate_saved_ajax_process reports the cooperative exit status instead of a SIGKILL status' );
    cmp_ok( $elapsed, '>=', 0.3, '_terminate_saved_ajax_process waits for the handler rather than returning instantly' );
    cmp_ok( $elapsed, '<', 4, '_terminate_saved_ajax_process returns as soon as the owned group is gone instead of burning the window' );
    is( waitpid( $worker, WNOHANG ), -1, '_terminate_saved_ajax_process reaped the worker it waited out' );
    unlink $marker if -e $marker;
}

# Scenario: a descendant, not the worker itself, is the one still cleaning up.
{
    my $descendant_marker = File::Spec->catfile( $home, "dd428-descendant-pid-$$.txt" );
    my $cleanup_marker    = File::Spec->catfile( $home, "dd428-descendant-cleanup-$$.txt" );
    my $ready_file        = File::Spec->catfile( $home, "dd428-descendant-ready-$$.txt" );
    my $leader_source = q{
        use Developer::Dashboard::GoRoutine ();
        use POSIX ();
        my ( $descendant_marker, $cleanup_marker, $ready ) = @ARGV;
        my $descendant_source = q{
            use POSIX ();
            my ( $descendant_marker, $cleanup_marker ) = @ARGV;
            $SIG{TERM} = sub {
                select undef, undef, undef, 0.3;
                open my $fh, '>', $cleanup_marker or POSIX::_exit(91);
                print {$fh} "cleaned up\n";
                close $fh or POSIX::_exit(92);
                POSIX::_exit(0);
            };
            open my $fh, '>', $descendant_marker or POSIX::_exit(93);
            print {$fh} "$$\n" or POSIX::_exit(94);
            close $fh or POSIX::_exit(95);
            select undef, undef, undef, 30;
            POSIX::_exit(0);
        };
        my $descendant = Developer::Dashboard::GoRoutine::spawn(
            [ $^X, '-e', $descendant_source, $descendant_marker, $cleanup_marker ], {},
        );
        die "GoRoutine descendant launch failed: $!" if !defined $descendant;
        $SIG{TERM} = sub { POSIX::_exit(0) };
        for ( 1 .. 200 ) {
            last if -s $descendant_marker;
            select undef, undef, undef, 0.02;
        }
        die "GoRoutine descendant did not publish its pid marker" if !-s $descendant_marker;
        open my $fh, '>', $ready or die "Unable to publish readiness: $!";
        print {$fh} "up\n" or die "Unable to write readiness: $!";
        close $fh or die "Unable to close readiness: $!";
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    };
    my $leader = spawn(
        [ $^X, '-e', $leader_source, $descendant_marker, $cleanup_marker, $ready_file ],
        { process_group => 1 },
    );
    die "GoRoutine spawn failed: $!" if !defined $leader;
    push @cleanup_pids, $leader;
    is( _wait_for_marker($ready_file), 1, 'descendant fixture reports the leader ready after its descendant started' );

    my $descendant_pid = _read_marker_pid($descendant_marker);
    push @cleanup_pids, $descendant_pid;
    ok( defined $descendant_pid && kill( 0, $descendant_pid ), 'descendant fixture process is alive before termination' );

    is( $runtime->_terminate_saved_ajax_process( $leader, $leader ), 1, '_terminate_saved_ajax_process completes when only a descendant is still shutting down' );
    ok( -e $cleanup_marker, '_terminate_saved_ajax_process holds the SIGKILL escalation while an owned descendant is still cleaning up' );

    my $descendant_gone = 0;
    for ( 1 .. 100 ) {
        if ( !kill 0, $descendant_pid ) { $descendant_gone = 1; last; }
        select undef, undef, undef, 0.05;
    }
    ok( $descendant_gone, '_terminate_saved_ajax_process leaves no descendant behind once the group drains' );
    waitpid( $leader, WNOHANG );
    unlink grep { -e $_ } $descendant_marker, $cleanup_marker;
}

# Scenario: nothing in the owned group cooperates, so the escalation must fire
# only after the window really elapsed, and must clear the whole subtree.
{
    # A short window keeps the timing assertion cheap; the point is that the
    # measured wait tracks the configured window instead of collapsing to zero.
    local $Developer::Dashboard::PageRuntime::SAVED_AJAX_TERM_GRACE_SECONDS = 0.4;

    my $marker = File::Spec->catfile( $home, "dd428-stubborn-pid-$$.txt" );
    my $ready_file = File::Spec->catfile( $home, "dd428-stubborn-ready-$$.txt" );
    my $leader_source = q{
        use Developer::Dashboard::GoRoutine ();
        my ( $marker, $ready ) = @ARGV;
        my $descendant_source = q{
            my ($marker) = @ARGV;
            $SIG{TERM} = 'IGNORE';
            open my $fh, '>', $marker or die "Unable to write descendant marker: $!";
            print {$fh} "$$\n" or die "Unable to write descendant pid: $!";
            close $fh or die "Unable to close descendant marker: $!";
            select undef, undef, undef, 30;
        };
        my $descendant = Developer::Dashboard::GoRoutine::spawn(
            [ $^X, '-e', $descendant_source, $marker ], {},
        );
        die "GoRoutine descendant launch failed: $!" if !defined $descendant;
        $SIG{TERM} = 'IGNORE';
        for ( 1 .. 200 ) {
            last if -s $marker;
            select undef, undef, undef, 0.02;
        }
        die "GoRoutine descendant did not publish its pid marker" if !-s $marker;
        open my $fh, '>', $ready or die "Unable to publish readiness: $!";
        print {$fh} "up\n" or die "Unable to write readiness: $!";
        close $fh or die "Unable to close readiness: $!";
        select undef, undef, undef, 30;
    };
    my $leader = spawn( [ $^X, '-e', $leader_source, $marker, $ready_file ], { process_group => 1 } );
    die "GoRoutine spawn failed: $!" if !defined $leader;
    push @cleanup_pids, $leader;
    is( _wait_for_marker($ready_file), 1, 'TERM-ignoring fixture reports the leader ready after its descendant started' );

    my $descendant_pid = _read_marker_pid($marker);
    push @cleanup_pids, $descendant_pid;
    ok( defined $descendant_pid && kill( 0, $descendant_pid ), 'TERM-ignoring descendant is alive before termination' );

    my $reaped_status = 'untouched';
    my $started       = Time::HiRes::time();
    is( $runtime->_terminate_saved_ajax_process( $leader, $leader, \$reaped_status ), 1, '_terminate_saved_ajax_process escalates for a TERM-ignoring owned group' );
    my $elapsed = Time::HiRes::time() - $started;

    cmp_ok( $elapsed, '>=', 0.4, '_terminate_saved_ajax_process waits the whole configured window before the SIGKILL escalation' );
    is( $reaped_status, 'untouched', '_terminate_saved_ajax_process leaves the status untouched when the worker had to be SIGKILLed' );
    waitpid( $leader, 0 );
    ok( !kill( 0, $leader ), '_terminate_saved_ajax_process leaves the TERM-ignoring group leader dead' );

    my $descendant_gone = 0;
    for ( 1 .. 100 ) {
        if ( !kill 0, $descendant_pid ) { $descendant_gone = 1; last; }
        select undef, undef, undef, 0.05;
    }
    ok( $descendant_gone, '_terminate_saved_ajax_process still kills the TERM-ignoring descendant after the real window' );
    unlink $marker if -e $marker;
}

done_testing;

__END__

=head1 NAME

32-saved-ajax-group-coverage.t - saved-Ajax POSIX process-group unit coverage

=head1 DESCRIPTION

This test drives every branch and condition of the saved-Ajax process-group
helpers in C<Developer::Dashboard::PageRuntime>: the launch-command wrapper,
the group-ownership recorder, the child-side exec launcher, and the
group-aware terminator, including the live owned-group path that must kill a
TERM-ignoring descendant. It also pins the elapsed SIGTERM grace window the
terminator grants before escalating to SIGKILL: a cooperative worker completes
its own cleanup handler, a still-draining descendant holds the escalation off,
and a group that ignores SIGTERM is killed only after the configured window has
really passed. Isolated helper processes are launched with the public
C<Developer::Dashboard> GoRoutine C<spawn> and C<wait_process> exports; the
failed-exec assertion captures its diagnostic in a child so the test harness
does not lose coverage instrumentation when C<exec> is attempted.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Give the DD-396 process-group cleanup code direct unit coverage on all four
Devel::Cover metrics, complementing the end-to-end disconnect acceptance test
with deterministic per-branch checks, and hold the DD-428 grace window to a
measured elapsed wait rather than an intention expressed in code.

=head1 WHY IT EXISTS

The acceptance scenario only exercises the healthy POSIX path. The Windows
fallbacks, the argument guards, the setpgid failure path, and the
already-reaped-group path need direct calls with controlled inputs, and the
injectable C<$SETPGID> primitive needs both its stubbed and real forms driven.

=head1 WHEN TO USE

Run this test whenever the saved-Ajax launch wrapper, process-group ownership,
or termination escalation logic changes.

=head1 HOW TO USE

Run C<d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -lv
t/32-saved-ajax-group-coverage.t> during development, or include it in the
repository-wide Docker suite and coverage gates.

=head1 WHAT USES IT

Developers, the Perl test harness, and the all-metric coverage gate use this
file to hold the saved-Ajax lifecycle helpers at full coverage.

=head1 EXAMPLES

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -lv t/32-saved-ajax-group-coverage.t

Run the focused process-group unit checks.

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -MDevel::Cover -lv t/32-saved-ajax-group-coverage.t

Collect the per-branch coverage these units exist to provide.

=for comment FULL-POD-DOC END

=cut
