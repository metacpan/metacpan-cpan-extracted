#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes ();

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::GoRoutine ();
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Local::CollectorFixture qw(wait_for_managed_loop);

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
# Every collector loop this file starts is detached, and only the matching
# stop further down ends it. A run that is killed part-way never reaches
# that stop, and the loops then live on for days. Tie them to this test
# process: each loop ends itself once this pid is gone.
local $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID} = $$;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $collectors = Developer::Dashboard::Collector->new( paths => $paths );
my $runner     = Developer::Dashboard::CollectorRunner->new(
    collectors => $collectors,
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

my $name = "signal-probe-$$";
my $pid  = $runner->start_loop( { name => $name, interval => 3600, mode => 'singleton', command => 'true' } );
ok( $pid, 'a supervisor started' );

# Wait until the loop is not merely recognized but actually up: it is
# recognizable from the moment it is spawned (its identity marker travels in
# the spawn environ), but its SIGTERM handler is only installed once it has
# finished starting. Sending TERM before that kills it with the default
# disposition and the handler never records the signal - which is exactly
# what the assertions below check for. The 10s budget matches the poll this
# replaces (200 x 0.05s).
wait_for_managed_loop( $runner, $pid, $name, timeout => 10, ready => 1 );

# On Windows, Perl kill TERM ends a process without delivering the signal,
# so the loop's SIGTERM handler never runs and the loop survives the kill,
# orphaned, holding the harness pipe open. The product's stop path is the
# only stop that can record the signal there (stop_loop writes the same
# record the handler writes on Unix), so exercise that path on Windows and
# keep the raw signal on Unix, where the handler is what is under test.
if ( $^O eq 'MSWin32' ) {
    $runner->stop_loop($name);
}
else {
    kill 'TERM', $pid;
}

my $said = '';
for ( 1 .. 60 ) {
    $said = join ' ', map { ref $_ ? ( $_->{error} // '' ) : $_ } eval { $collectors->read_log($name) };
    last if $said =~ /SIGTERM/;
    Time::HiRes::sleep(0.1);
}

# A collector that stopped used to leave a 'stopped' state and no pidfile, which
# reads identically whether it shut down in an orderly way, was stopped by a
# watchdog, or was killed by somebody's stray signal. That ambiguity cost hours on
# DD-532, where every investigation began from "it died" instead of "it was told
# to stop". Perl hands the handler the signal name; it was being thrown away.
like( $said, qr/SIGTERM/, 'the loop records WHICH signal stopped it, not merely that it stopped' );
like( $said, qr/received by pid \d+/, 'and which process received it, so the record names a subject' );

# AC-2, and it turned out the product was already right. A zombie keeps a
# process-table entry, so kill 0 returns true for it - which is why three checks
# written that way during DD-532 reported a dead supervisor as alive. The runner
# does not use kill 0 for this: _pid_is_running reads the process state and
# refuses 'Z'. Asserted here so that stays true, because the obvious
# simplification is to replace it with kill 0.
{
    my $zombie = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'exit 0' ],
        {},
    );

    # Do NOT reap it: an unreaped exited child IS a zombie, which is the state
    # under test.
    for ( 1 .. 100 ) {
        last if ( $runner->_read_process_state($zombie) || '' ) eq 'Z';
        Time::HiRes::sleep(0.05);
    }

    SKIP: {
        skip 'Windows has no zombie process state: an exited child keeps no process-table entry once its handles close', 2
          if $^O eq 'MSWin32';
        is( $runner->_read_process_state($zombie), 'Z', 'the fixture really is a zombie, not merely a dead pid' );
        ok( kill( 0, $zombie ), 'kill 0 reports the zombie as present - which is why it is the wrong question' );
    }
    is( $runner->_pid_is_running($zombie), 0, 'the runner does NOT report a zombie as running' );
    is( $runner->_is_managed_loop( $zombie, $name ), 0, 'and does not mistake one for a managed collector loop' );

    waitpid $zombie, 0;
}

# Keep a direct process-API parity assertion separate from the zombie fixture:
# CollectorRunner may reap any exited child while refreshing its loop inventory.
{
    my $child = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', 'exit 0' ],
        {},
    );
    is(
        Developer::Dashboard::GoRoutine::wait_process($child),
        0,
        'GoRoutine wait_process returns the child exit status',
    );
}

# AC-3: a supervisor that has exited must leave no record claiming it is running.
# Two exit paths, and they clean up differently, which is the point:
#   - signalled: _shutdown_loop writes a 'stopped' state and removes the files.
#   - KILLed with no handler: nothing runs in the child at all, so the pidfile and
#     a 'running' state survive it. running_loops is what repairs that, and this
#     asserts it does, because a stale record claiming a dead collector is running
#     is precisely what let 27 loops hide behind one entry (DD-532).
{
    my $orphan_name = "orphan-probe-$$";
    my $orphan = $runner->start_loop( { name => $orphan_name, interval => 3600, mode => 'singleton', command => 'true' } );
    for ( 1 .. 200 ) { last if $runner->_is_managed_loop( $orphan, $orphan_name ); Time::HiRes::sleep(0.05) }

    kill 'KILL', $orphan;    # no handler runs, so nothing cleans up after it
    for ( 1 .. 100 ) {
        last if !$runner->_pid_is_running($orphan);
        Time::HiRes::sleep(0.05);
    }

    my @claimed = grep { ( $_->{name} // '' ) eq $orphan_name } $runner->running_loops;
    is( scalar @claimed, 0, 'a killed supervisor leaves no record claiming the collector is running' );
    ok( !-f $runner->_pidfile($orphan_name), 'and its stale pidfile is cleared rather than left to be believed' );
}

done_testing;

__END__

=head1 NAME

t/154-collector-signal-recorded.t - a stopped collector says what stopped it

=head1 PURPOSE

Verify that when a supervisor loop is stopped by a signal, the signal's name and
the receiving pid are written to that collector's log before it shuts down.

=head1 WHY IT EXISTS

A collector that has been signalled leaves a C<stopped> state and no pidfile.
That is byte-identical to an orderly shutdown, to a watchdog stop, and to a stray
kill from somewhere else on the machine. During DD-532 a supervisor was being
stopped during batch test runs and every line of investigation started from the
wrong premise - that it had crashed - because nothing recorded that it had been
told to stop, or by which signal.

Perl passes the signal name to the handler. It was being discarded.

=head1 WHEN TO USE

Whenever the collector's signal handling or shutdown path changes.

=head1 HOW TO USE

    d2 docker compose exec dev prove -blv t/154-collector-signal-recorded.t

=head1 WHAT USES IT

Nothing; it is a regression test for C<Developer::Dashboard::CollectorRunner>.
Its zombie and exit-status fixtures launch native children with
C<Developer::Dashboard::GoRoutine::spawn>; the separate exit-status fixture
also verifies C<wait_process>. The test does not use Perl C<fork>.

=head1 EXAMPLES

The line it guarantees appears in the collector's own log:

    SIGTERM received by pid 1433463

=cut
