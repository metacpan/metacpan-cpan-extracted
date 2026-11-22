package TestDiscordLoop;

use v5.26;
use warnings;
use Exporter 'import';
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

our @EXPORT_OK = qw(await_future);

sub await_future {
    my ( $loop, $future, $description, %options ) = @_;
    return $future if $future->is_ready;

    # Relative test deadlines must not move when the system wall clock is corrected.
    my $clock = $options{clock} // sub { clock_gettime(CLOCK_MONOTONIC) };
    my $deadline = $clock->() + ( $options{timeout} // 5 );
    my $completed_at;
    $future->on_ready( sub { $completed_at = $clock->() } );

    # Drive real I/O, bounding each wait by the remaining monotonic budget.
    while ( !$future->is_ready ) {
        my $remaining = $deadline - $clock->();
        last if $remaining <= 0;
        $loop->loop_once($remaining);
    }

    # A long callback can complete the Future after its deadline within one loop iteration.
    if ( !defined($completed_at) || $completed_at > $deadline ) {
        $future->cancel unless $future->is_ready;
        die "Timed out waiting for $description\n";
    }
    return $future;
}

1;
