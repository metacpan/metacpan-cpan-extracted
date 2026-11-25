use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
use Time::HiRes qw(time);

use Developer::Dashboard::GoRoutine ();

my $dir = tempdir( CLEANUP => 1 );
sub run_child {
    my ( $name, $source, $expected ) = @_;
    my $output = "$dir/$name.txt";
    my $script = "use strict; use warnings; use Developer::Dashboard::GoRoutine;\n$source";
    my $child = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', $script ],
        { stdout => $output, stderr => $output },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
        "$name child exits successfully" );
    open my $fh, '<', $output or die "Unable to read child output '$output': $!";
    my @lines = <$fh>;
    close $fh or die "Unable to close child output '$output': $!";
    is_deeply( \@lines, $expected, "$name drains the expected worker output" );
}

# The child schedules a short routine on a timer trigger and exits without
# wait_all. The END-block drain in GoRoutine.pm runs while the interpreter
# can still execute code, on the main thread, so the routine runs before
# the process ends. There is no second interpreter to tear down, so the
# old shutdown access violation cannot recur.
run_child(
    'automatic-shutdown',
    q{go(sub { print "worker-finished\n"; }, { after => 0.12 });
      print "main-finished\n";},
    [ "main-finished\n", "worker-finished\n" ],
);

run_child(
    'explicit-exit',
    q{go(sub { print "exit-worker-finished\n"; }, { after => 0.12 });
      print "main-exit\n"; exit 0;},
    [ "main-exit\n", "exit-worker-finished\n" ],
);

run_child(
    'nested-shutdown',
    q{go(sub {
          go(sub { print "nested-finished\n"; }, { after => 0.05 });
      }, { after => 0.05 });
      print "nested-main-finished\n";},
    [ "nested-main-finished\n", "nested-finished\n" ],
);

# A callback dispatched during the END drain registers a new repeating
# routine. The drain must cancel it too: a repeating routine never
# finishes on its own, so without the in-loop cancel the drain would
# pump for its timer until the 30 second deadline instead of exiting.
# The child must exit promptly, not after 30 seconds.
{
    my $name   = 'drain-repeating';
    my $output = "$dir/$name.txt";
    my $source = q{go(sub {
          go(sub { }, { every => 0.5 });
          print "finite-finished\n";
      }, { after => 0.05 });
      print "drain-main-finished\n";};
    my $script = "use strict; use warnings; use Developer::Dashboard::GoRoutine;\n$source";
    my $start  = time();
    my $child  = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-e', $script ],
        { stdout => $output, stderr => $output },
    );
    is( Developer::Dashboard::GoRoutine::wait_process($child), 0,
        "$name child exits successfully" );
    my $elapsed = time() - $start;
    ok( $elapsed < 10,
        "$name child exits promptly (took $elapsed seconds, not the 30s drain deadline)"
    );
    open my $fh, '<', $output or die "Unable to read child output '$output': $!";
    my @lines = <$fh>;
    close $fh or die "Unable to close child output '$output': $!";
    is_deeply( \@lines, [ "drain-main-finished\n", "finite-finished\n" ],
        "$name drains the expected worker output" );
}

done_testing;

__END__

=head1 NAME

240-goroutine-shutdown.t - verify automatic worker draining at Perl shutdown

=head1 DESCRIPTION

This test starts child Perl interpreters using C<Developer::Dashboard::GoRoutine>.
They launch delayed workers and reach normal shutdown, explicit C<exit>, or
nested worker completion without calling C<wait_all>. The parent verifies that
each child drains its workers before returning.

=head1 PURPOSE

Confirm the GoRoutine END-block shutdown drain runs outstanding finite
routines before the process ends, including nested routines and explicit
normal C<exit>, without requiring application code to add an C<END> block.

=head1 WHY IT EXISTS

Detached work must not be silently abandoned when a Perl program exits. The
test checks that normal, explicit, and nested shutdown paths drain workers
without every caller having to remember a separate wait operation. The drain
runs in a Perl C<END> block on the main thread, while the interpreter can
still execute code, so the teardown race of the old threaded engine, where
the main interpreter destroyed itself while a worker on a cloned interpreter
still ran, cannot recur: there is no second interpreter.

=head1 WHEN TO USE

Run after rebuilding the distribution XS in the dev Docker container. This is
the regression test for GoRoutine automatic shutdown behaviour.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/240-goroutine-shutdown.t

All test output is captured in a temporary directory. The child is launched
through the native GoRoutine process helper so the test does not call Perl
C<fork>.

=head1 WHAT USES IT

The test harness verifies GoRoutine's shutdown contract for programs that use
detached asynchronous callbacks and nested worker routines.

=head1 EXAMPLES

  go(sub { print "worker complete\n" }, { after => 0.1 });
  exit 0; # Normal exit drains the worker without an explicit wait_all().

=cut
