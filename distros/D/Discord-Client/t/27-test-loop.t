use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordLoop qw(await_future);
use Future;
use IO::Async::Loop;
use IO::Async::Internals::TimeQueue;
use Time::HiRes ();

T2->subtest(
    'a wall-clock correction cannot expire a relative I/O wait',
    sub {
        my $offset = 0;
        my $wall_clock = sub { Time::HiRes::time() + $offset };
        no warnings 'redefine';
        local *IO::Async::Loop::time = $wall_clock;
        local *IO::Async::Internals::TimeQueue::time = $wall_clock;

        # Correct only the loop's wall clock between two real deferred callbacks.
        my $loop = IO::Async::Loop->new;
        my $future = $loop->new_future;
        $loop->later(
            sub {
                $offset += 60;
                $loop->later( sub { $future->done('received') } );
            }
        );
        T2->is( await_future( $loop, $future, 'clock correction' )->get,
            'received', 'I/O completes despite a wall-clock step larger than the watchdog' );
    }
);

T2->subtest(
    'a stalled real loop still times out and cancels pending work',
    sub {
        my $loop = IO::Async::Loop->new;
        my $future = $loop->new_future;

        # With no I/O or timers, loop_once must return when its wait budget is spent.
        T2->like(
            T2->dies( sub { await_future( $loop, $future, 'stalled peer', timeout => 0.01 ) } ),
            qr/Timed out waiting for stalled peer/,
            'a missing peer fails with the operation name'
        );
        T2->ok( $future->is_cancelled, 'timeout cancels the pending operation' );
    }
);

# Model one expensive callback without spending real time or using private loop state.
{

    package Local::CallbackLoop;

    sub loop_once { $_[0]->{callback}->( $_[1] ) }
}

T2->subtest(
    'completion after the deadline cannot hide an overlong callback',
    sub {
        my $now = 0;
        my $future = Future->new;
        my $loop = bless {
            callback => sub {
                $now = 6;
                $future->done;
            }
            },
            'Local::CallbackLoop';

        # A Future may complete before loop_once returns, after the entire budget was consumed.
        T2->like(
            T2->dies(
                sub {
                    await_future( $loop, $future, 'late dispatch', clock => sub { $now } )
                }
            ),
            qr/Timed out waiting for late dispatch/,
            'a late completion still fails its deadline'
        );
        T2->ok( $future->is_done, 'an already completed operation is not cancelled retroactively' );
    }
);

T2->done_testing;
