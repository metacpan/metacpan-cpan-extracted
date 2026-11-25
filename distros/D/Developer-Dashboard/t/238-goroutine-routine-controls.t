use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempfile);
use FindBin;
use IO::Socket::INET;

use lib 'lib';
use Developer::Dashboard::GoRoutine;

# The engine is a single-threaded C event loop: no threads, no fork, and
# no perl_clone. The only occurrence of the name in the live engine source
# is a prose comment in GoRoutineEvent.h saying there is no perl_clone
# here, so the assertion targets the call form, perl_clone(, which would
# be a real use of the interpreter-cloning API.
my @engine_files = (
    File::Spec->catfile( $FindBin::Bin, '..', 'GoRoutine012.xs' ),
    File::Spec->catfile( $FindBin::Bin, '..', 'GoRoutineEvent.h' ),
);
for my $engine_file (@engine_files) {
    open my $engine_fh, '<', $engine_file
        or die "Could not read GoRoutine engine source '$engine_file': $!";
    my $engine_source = do { local $/; <$engine_fh> };
    close $engine_fh
        or die "Could not close GoRoutine engine source '$engine_file': $!";
    unlike( $engine_source, qr/perl_clone\s*\(/,
        "no perl_clone call remains in $engine_file" );
}
ok( !-e File::Spec->catfile( $FindBin::Bin, '..', 'GoRoutine012Native.h' ),
    'the old thread/clone engine header GoRoutine012Native.h is gone' );

# A yielding routine: it pumps the engine in short steps and stops as soon
# as its cooperative cancel flag is set. A callback that never yields can
# never observe a cancel, because it runs on the main thread and there is
# no other thread to interrupt it. The loop is bounded so a missed cancel
# fails the test instead of hanging it.
sub yielding_routine {
    my ($saw_cancel) = @_;
    my $routine;
    $routine = go sub {
        for ( 1 .. 300 ) {
            Developer::Dashboard::GoRoutine::pump(0.01);
            if ( $routine->cancel_requested ) {
                $$saw_cancel = 1;
                last;
            }
        }
    };
    return $routine;
}

my $normal = go sub {
    sleep 0.15;
};

isa_ok($normal, 'Developer::Dashboard::GoRoutine::Routine',
    'go returns a controllable routine handle');

{
    ok(!$normal->is_running, 'new routine is not running yet');
    is($normal->status, 'pending', 'new routine status is pending');
    ok(!$normal->cancel_requested, 'new routine has no cancel requested');
    cmp_ok($normal->age, '>=', 0, 'routine age is non-negative');

    my ($inside_running, $inside_status);
    my $probe;
    $probe = go sub {
        $inside_running = $probe->is_running;
        $inside_status  = $probe->status;
    };
    wait_all();
    ok($inside_running, 'routine reports running while its callback executes');
    is($inside_status, 'running', 'routine status is running during dispatch');

    wait_all();

    ok(!$normal->is_running, 'completed routine is not running');
    is($normal->status, 'done', 'normal completion status is done');
    ok(!$normal->is_killed, 'normal completion is not reported as killed');
    cmp_ok($normal->age, '>=', 0.10, 'completed routine age includes runtime');
    my $finished_age = $normal->age;
    sleep 0.03;
    cmp_ok(abs($normal->age - $finished_age), '<', 0.02,
        'routine age freezes when the routine completes');

    # Cooperative kill: a timer routine kills the yielding worker while it
    # is running. The worker observes the flag on its next pump and winds
    # down; kill cannot interrupt code that never yields.
    my $started = time;
    my $killed_saw_cancel = 0;
    my $killed = yielding_routine(\$killed_saw_cancel);
    my $killer = go(sub { $killed->kill }, { after => 0.05 });
    wait_all();
    cmp_ok(time - $started, '<', 3, 'cooperative kill stops a yielding routine promptly');
    ok($killed_saw_cancel, 'yielding routine observed the cancel flag');
    is($killed->status, 'killed', 'killed routine reports killed');
    ok($killed->is_killed, 'is_killed recognises killed status');
    ok(!$killed->is_running, 'killed routine is no longer running');
    ok($killed->cancel_requested, 'killed routine keeps its cancel flag set');
    is($killer->status, 'done', 'the timer that delivered the kill completes normally');
    ok(!$killed->kill, 'kill after completion is a no-op');

    # Cooperative timeout: the yielding worker's deadline fires while it
    # is running, sets the same flag, and the worker winds down.
    $started = time;
    my $timed_saw_cancel = 0;
    my $timed = yielding_routine(\$timed_saw_cancel);
    is($timed->timeout(0.15), $timed,
        'timeout returns the same routine handle for chaining');
    wait_all();
    cmp_ok(time - $started, '<', 3, 'timeout stops a yielding routine promptly');
    ok($timed_saw_cancel, 'yielding routine observed the timeout cancel flag');
    is($timed->status, 'timed_out', 'expired timeout reports timed_out');
    ok($timed->is_killed, 'is_killed recognises timeout status');

    # Kill a pending routine: it is cancelled at once and never runs.
    my $pending_ran = 0;
    my $pending_killed = go(sub { $pending_ran = 1 }, { after => 5 });
    is($pending_killed->status, 'pending', 'delayed routine is pending before it runs');
    ok($pending_killed->kill, 'kill request is accepted for a pending routine');
    wait_all();
    is($pending_killed->status, 'killed', 'pending routine killed before it runs reports killed');
    ok($pending_killed->is_killed, 'is_killed recognises a pending routine killed');
    is($pending_ran, 0, 'pending routine killed before it runs never executes');

    # Timeout a pending routine: the deadline cancels it before its
    # trigger fires, and the callback never runs.
    $started = time;
    my $pending_timed_out_ran = 0;
    my $pending_timed_out = go(sub { $pending_timed_out_ran = 1 }, { after => 5 });
    $pending_timed_out->timeout(0.15);
    wait_all();
    cmp_ok(time - $started, '<', 3, 'pending timeout fires promptly');
    is($pending_timed_out->status, 'timed_out', 'pending routine past its deadline reports timed_out');
    ok($pending_timed_out->is_killed, 'is_killed recognises a pending routine timed out');
    is($pending_timed_out_ran, 0, 'pending routine timed out before it runs never executes');

    my $replaced_saw_cancel = 0;
    my $replaced = yielding_routine(\$replaced_saw_cancel);
    $replaced->timeout(10)->timeout(0.15);
    wait_all();
    ok($replaced_saw_cancel, 'yielding routine observed the replacement timeout');
    is($replaced->status, 'timed_out', 'new timeout replaces the old timeout');

    my $disabled = go sub {
        sleep 0.15;
    };
    $disabled->timeout(0.02)->timeout(0);
    wait_all();
    is($disabled->status, 'done', 'timeout zero disables the active timeout');

    my $exited = go sub {
        exit 42;
    };
    wait_all();
    is($exited->status, 'exited', 'exit ends only the routine');
    ok(!$exited->is_killed, 'routine-local exit is not reported as a kill');
    pass('main interpreter continues after routine-local exit');

    # The same exit in a child perl, followed by exit() at top level:
    # exit() goes through PL_runops, so a leaked custom runops would
    # croak __GOROUTINE_EXIT__ and the child would die with 255 instead
    # of exiting 7. The croak inside go_ev_runops longjmps to the G_EVAL
    # set up by call_sv in _ev_invoke_callback, which returns normally,
    # so the restore on the next line always runs. (Q review 5979186129
    # on PR #82 claimed the restore is bypassed; this probe proves it
    # is not.) The child-spawn shape mirrors t/254: the map is
    # parenthesised on purpose, so the script file is passed as the
    # program instead of being mapped into an -I entry.
    {
        my $lib_dir = abs_path("$FindBin::Bin/../lib");
        my @blib_inc = grep { /blib/ } @INC;
        if (!@blib_inc) {
            my $blib_lib  = abs_path("$FindBin::Bin/../blib/lib");
            my $blib_arch = abs_path("$FindBin::Bin/../blib/arch");
            @blib_inc = grep { -d $_ } ($blib_lib, $blib_arch);
        }
        my $child_program = <<'CHILD';
use strict;
use warnings;
BEGIN { open(STDERR, '>&', STDOUT) or die "cannot dup stderr: $!"; }
use lib 'LIBDIR';
use Developer::Dashboard::GoRoutine;
my $r = go sub { exit 42 };
wait_all();
print "routine status=" . $r->status . "\n";
exit(7);
CHILD
        $child_program =~ s/LIBDIR/$lib_dir/;
        my ($child_fh, $child_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
        print {$child_fh} $child_program;
        close $child_fh;
        my @child_args = ($^X, '-I' . $lib_dir, (map { '-I' . $_ } @blib_inc), $child_file);
        open my $pipe, '-|', @child_args or die "cannot spawn child: $!";
        my $child_out = do { local $/; <$pipe> };
        close $pipe;
        my $child_rc = $? >> 8;
        is($child_rc, 7, 'child exit works after a routine-local exit (runops restored)');
        like($child_out // '', qr/routine status=exited/,
            'child routine exit was scoped to the routine');
    }

    # A die that merely mentions the exit token is a failure, not an
    # exit: the token counts as an exit only when the C runops loop
    # raises it first in the error, so a user message containing it
    # mid-string must not match.
    my $token_in_message = go sub {
        die "boom __GOROUTINE_EXIT__ boom";
    };
    wait_all();
    is( $token_in_message->status, 'failed',
        'a die mentioning the exit token mid-message reports failed' );
    ok( defined $token_in_message->error,
        'a die mentioning the exit token mid-message records its error' );

    my $invalid = go sub {
        sleep 0.05;
    };
    for my $bad (undef, -1, 'abc', 'Inf') {
        my $ok = eval { $invalid->timeout($bad); 1 };
        ok(!$ok, 'timeout rejects invalid value');
        like($@, qr/timeout\(\) requires a non-negative number/,
            'invalid timeout reports the documented error');
    }
    my $too_large = eval { $invalid->timeout('1e999'); 1 };
    ok(!$too_large, 'timeout rejects a non-finite value');
    like($@, qr/timeout\(\) requires a non-negative number/,
        'non-finite timeout reports the documented error');
    my $scientific = go sub { sleep 0.05 };
    is($scientific->timeout('1e3'), $scientific,
        'timeout accepts a valid exponent-form number');
    $scientific->timeout(0);
    wait_all();

    {
        my $ran = 0;
        my $unreferenced = go sub { $ran = 1; sleep 0.05 };
        undef $unreferenced;
        wait_all();
        is($ran, 1, 'routine still runs after its handle is released');
    }
    pass('worker reference keeps native control alive after handle release');
}

# A routine registered for both readable and writable on one socket pair
# exercises the IO removal pass with two nodes for one routine id: the
# engine must remove only the node that fired, not its sibling. (Q
# review 5953161892 on PR #82: the broad go_ev_cancel freed the saved
# next node, a use-after-free.) Sockets, not pipes: on Windows select
# only works on sockets.
{
    my $server = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', ReuseAddr => 1,
    ) or die "cannot listen: $!";
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $server->sockport, Proto => 'tcp',
    ) or die "cannot connect: $!";
    my $accepted = $server->accept or die "cannot accept: $!";
    $client->autoflush(1);
    print $client "x";
    my $ran = 0;
    my $routine = go sub { $ran++ },
        { readable => $accepted, writable => $client };
    wait_all();
    is($ran, 1, 'routine with both readable and writable triggers runs once');
    is($routine->status, 'done', 'both-direction routine finishes done');
}

# A callback that dies with a false value ("" or 0) still fails the
# routine: the XS error check must not test truth, or the exception is
# swallowed and the routine is wrongly marked done. Perl appends
# " at FILE line LINE" to a die value without a trailing newline, so
# the recorded error is the value plus that suffix, not the bare value.
for my $false_die ( "", 0 ) {
    my $label = $false_die eq "" ? 'empty string' : 'zero';
    my $pat = $false_die eq "" ? qr/\ADied at / : qr/\A0 at /;
    my $failed = go sub { die $false_die };
    wait_all();
    is( $failed->status, 'failed',
        "routine dying with $label reports failed" );
    ok( defined $failed->error,
        "routine dying with $label records its error" );
    like( $failed->error, $pat,
        "routine dying with $label keeps the die value" );
}

# A callback that dies with undef still fails the routine: Perl supplies
# the default "Died at FILE line LINE" message, so $@ is defined and the
# XS error check sees it (Q round 8 asked this to be verified).
{
    my $failed = go sub { die undef };
    wait_all();
    is( $failed->status, 'failed', 'routine dying with undef reports failed' );
    ok( defined $failed->error,
        'routine dying with undef records its error' );
    like( $failed->error, qr/\ADied at /,
        'routine dying with undef keeps the default die message' );
}

# pump() re-entered from a dispatched callback nests on the stack: a
# chain of routines whose callbacks each call pump(0) nests until the
# depth guard trips, so those routines fail with the guard error and
# the process stays up. (Calling pump() and then recursing in the same
# callback does not nest: each pump returns before the next call, so
# the guard never fires.) With a chain of 105 and a guard at 100, the
# six routines dispatched once 100 callbacks are on the stack fail;
# the other ninety-nine complete normally.
my @chain;
for ( 1 .. 105 ) {
    push @chain, go sub { Developer::Dashboard::GoRoutine::pump(0) };
}
{
    # The chain nests the dispatcher 100 deep on purpose; silence
    # Perl's deep-recursion warning for this block, it is expected here.
    local $SIG{__WARN__} = sub {
        my ($msg) = @_;
        warn $msg unless $msg =~ /Deep recursion/;
    };
    wait_all();
}
my @guard_failed = grep {
    defined $_->error && $_->error =~ /recursion too deep/
} @chain;
is( scalar @guard_failed, 6,
    'the routines past the pump depth guard fail with the guard error' );
is( ( grep { $_->status eq 'done' } @chain ), 99,
    'the routines before the guard complete normally' );

# More IO routines than one Windows fd_set holds (FD_SETSIZE is 64):
# Winsock silently drops the extras, so they would never fire. Every
# registered routine must still run. The wait is bounded so a starved
# routine fails the test instead of hanging it.
{
    my $server = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', ReuseAddr => 1,
    ) or die "cannot listen: $!";
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $server->sockport, Proto => 'tcp',
    ) or die "cannot connect: $!";
    my $accepted = $server->accept or die "cannot accept: $!";
    $client->autoflush(1);
    print $client "x";
    my $fired = 0;
    my @many;
    for ( 1 .. 70 ) {
        push @many, go sub { $fired++ }, { readable => $accepted };
    }
    my $deadline = time() + 10;
    while ( time() < $deadline ) {
        last if $fired == 70;
        Developer::Dashboard::GoRoutine::pump(0.1);
    }
    is( $fired, 70, 'all 70 IO routines fire past the 64-entry fd_set limit' );
    is( ( grep { $_->status eq 'done' } @many ), 70,
        'all 70 IO routines finish done' );
}

done_testing;

__END__

=head1 NAME

t/238-goroutine-routine-controls.t - tests for GoRoutine routine handles

=head1 PURPOSE

This test verifies the public routine-handle controls of
Developer::Dashboard::GoRoutine after the redesign onto a single-threaded
C event loop, and that the old perl_clone engine is gone.

=head1 WHEN TO USE

Run this contract after building the XS extension and whenever the GoRoutine
routine lifecycle, routine-handle API, cancellation, timeout or shutdown code
changes. It is part of the normal package suite and should also be run alone
while debugging those behaviors.

=head1 WHY IT EXISTS

The earlier Dashboard integration returned no routine handle, so callers
could not inspect, cancel, or time-limit one asynchronous routine. The
routine-handle contract adds those controls. This test keeps that contract
visible and guards the timeout, cancellation, completion, and exit behavior
against regressions. Under the event loop a fresh routine reports
C<pending>, not C<running>, and cancellation of a running routine is
cooperative: the callback must yield and check C<cancel_requested>.

=head1 WHAT IT COVERS

    The test checks that no C<perl_clone> call remains in the engine
    source, normal completion, pending and running state, elapsed age,
    frozen completion age, cooperative kill and timeout of a yielding
    routine, at-once kill and timeout of a pending routine, timeout
    creation and replacement, timeout disabling, routine-local C<exit>,
    and clear validation errors for invalid timeout values. It uses the
    shared C<wait_all> barrier so every worker has finished before the
    assertions complete.

A callback that blocks forever without yielding cannot be killed or timed
out on the main thread by design: there is no other thread to interrupt
it from. The kill and timeout tests therefore use a callback that pumps
the engine in short steps and checks C<cancel_requested>, which is the
documented cooperative contract.

=head1 HOW TO USE

Run this test through the project development container after building the XS
extension:

    d2 docker compose exec dev prove -lv t/238-goroutine-routine-controls.t

The test fails if C<go> does not return a routine handle or if any GoRoutine
routine control is absent. No control assertions are conditionally skipped.

=head1 WHAT USES IT

The distribution's Perl test suite runs this file to verify the public
C<Developer::Dashboard::GoRoutine> routine-handle contract. Developers use it
to validate changes to the event-loop routine controls and their Perl-facing
wrapper.

=head1 EXAMPLES

The tested normal-completion usage is equivalent to:

    my $routine = go sub { perform_work(); };
    print $routine->status;
    wait_all();

Timeout and cancellation usage is equivalent to:

    my $routine = go sub {
        for (1 .. 100) {
            Developer::Dashboard::GoRoutine::pump(0.01);
            last if $routine->cancel_requested;
        }
    };
    $routine->timeout(10);
    $routine->kill if $should_cancel;
    wait_all();

=head1 SEE ALSO

L<Developer::Dashboard::GoRoutine>, L<Time::HiRes>, L<Test::More>.

=cut
