use v5.26;
use warnings;
use Test2::V1;
use IO::Async::Loop;
use Future;
use lib 't/lib';
use TestDiscordREST qw(error);
use TestDiscordGateway qw(gateway_info);

sub limiter {
    my (%args) = @_;

    # Use a shared controlled clock and scripted discovery results for permit scheduling.
    my $clock = bless { now => 0, timers => [] }, 'TestDiscordGateway::Clock';
    my $rest = bless {
        calls => [],
        responses => $args{responses} // [ gateway_info( max_concurrency => 2, remaining => 3 ) ]
        },
        'TestDiscordGateway::REST';
    my $limiter = Discord::Client::Gateway::IdentifyLimiter->new(
        loop => IO::Async::Loop->new,
        rest => $rest,
        clock => sub { $clock->{now} },
        delay => sub { $clock->delay( $_[0] ) },
        max_pending => $args{max_pending} // 1024
    );
    return ( $limiter, $clock, $rest );
}

T2->subtest(
    'modulo concurrency, reservation and actual send time',
    sub {
        my ( $limiter, $clock, $rest ) =
            limiter( responses => [ gateway_info( max_concurrency => 2, remaining => 3, reset_after => 60000 ), ] );

        # Different modulo buckets can reserve starts together while the same bucket waits.
        my $zero = $limiter->acquire(0);
        my $one = $limiter->acquire(1);
        my $two = $limiter->acquire(2);
        T2->ok( $zero->is_done && $one->is_done && !$two->is_ready,
            'separate Identify buckets start concurrently' );
        $clock->advance(8);
        T2->ok( !$two->is_ready, 'unsent reserved permit cannot allow another Identify' );

        # Cooldown begins at actual send time, not when the reservation was issued.
        $zero->get->commit;
        $one->get->commit;
        $clock->advance(4.99);
        T2->ok( !$two->is_ready, 'five-second window starts at actual send' );
        $clock->advance(0.01);
        T2->ok( $two->is_done, 'same bucket resumes after cooldown' );
        $two->get->commit;
        $limiter->close;
        T2->is( $clock->timer_count, 0, 'no limiter timer after close' );
    }
);

T2->subtest(
    'budget exhaustion refreshes server metadata',
    sub {
        my ( $limiter, $clock, $rest ) =
            limiter( responses => [ gateway_info( remaining => 1 ), gateway_info( remaining => 5 ) ] );

        # Consume the only start and wait for server metadata instead of inventing a new budget.
        $limiter->acquire(0)->get->commit;
        my $next = $limiter->acquire(1);
        $clock->advance(9.99);
        T2->ok( !$next->is_ready, 'zero remaining waits until reset' );
        $clock->advance(0.01);
        T2->ok( $next->is_done, 'fresh session limit permits Identify' );
        T2->is( scalar( @{ $rest->{calls} } ), 2, 'limit refreshed from REST, not guessed' );
        $next->get->commit;
        $limiter->close;
    }
);

T2->subtest(
    'zero reset delay retains budget and Identify cooldown',
    sub {
        # Zero-reset metadata is usable without refetching an available budget.
        my ( $limiter, $clock, $rest ) =
            limiter( responses => [ gateway_info( remaining => 2, reset_after => 0 ) ] );
        my $info = $limiter->info;
        T2->ok( $info->is_done, 'zero reset delay is accepted during discovery' );
        my $first = $limiter->acquire(0);
        T2->ok( $first->is_done, 'available budget permits the first Identify' );
        $first->get->commit;

        # A shared bucket still enforces the five-second interval between sends.
        my $next = $limiter->acquire(0);
        $clock->advance(4.99);
        T2->ok( !$next->is_ready, 'zero reset delay does not bypass Identify cooldown' );
        $clock->advance(0.01);
        T2->ok( $next->is_done, 'next Identify is permitted after five seconds' );
        T2->is( scalar( @{ $rest->{calls} } ), 1, 'available budget is not reset by repeated discovery' );
        T2->is( $limiter->stats->{remaining}, 0, 'both permits consume the reported budget' );
        $next->get->commit;
        $limiter->close;
        T2->is( $clock->timer_count, 0, 'shutdown leaves no refresh timer' );
    }
);

T2->subtest(
    'exhausted zero reset delay refreshes without a busy loop',
    sub {
        # Metadata remains exhausted once, then supplies two available starts.
        my ( $limiter, $clock, $rest ) = limiter(
            responses => [
                gateway_info( remaining => 1, reset_after => 0, max_concurrency => 2 ),
                gateway_info( remaining => 0, reset_after => 0, max_concurrency => 2 ),
                gateway_info( remaining => 2, reset_after => 10000, max_concurrency => 2 ),
            ]
        );
        $limiter->acquire(0)->get->commit;
        my $next = $limiter->acquire(0);
        $clock->advance(0.99);
        T2->ok( !$next->is_ready, 'exhausted budget does not grant an Identify' );
        T2->is( scalar( @{ $rest->{calls} } ), 1, 'no immediate repeated discovery' );

        # A newly queued request must not postpone the already scheduled refresh.
        my $later = $limiter->acquire(1);
        $clock->advance(0.01);
        T2->is( scalar( @{ $rest->{calls} } ), 2, 'new waiters do not postpone the one-second refresh' );
        $clock->advance(0.99);
        T2->is( scalar( @{ $rest->{calls} } ), 2, 'still exhausted budget waits before another refresh' );
        $clock->advance(0.01);
        T2->is( scalar( @{ $rest->{calls} } ), 3, 'later metadata supplies a new budget' );
        T2->ok( $later->is_done, 'available bucket uses the refreshed budget' );
        $later->get->commit if $later->is_done;

        # A fresh budget cannot bypass the original bucket's cooldown.
        T2->ok( !$next->is_ready, 'refreshed budget preserves the original Identify cooldown' );
        $clock->advance(3);
        T2->ok( $next->is_done, 'Identify proceeds when both budget and cooldown allow it' );
        $next->get->commit if $next->is_done;
        $limiter->close;
        T2->is( $clock->timer_count, 0, 'all polling timers are removed' );
    }
);

T2->subtest(
    'negative reset delay is rejected',
    sub {
        my ($limiter) = limiter( responses => [ gateway_info( reset_after => -1 ) ] );

        # Reject malformed discovery before granting a permit.
        my $info = $limiter->info;
        T2->is( error($info)->category, 'protocol', 'negative reset delay fails discovery' );
        $limiter->close;
    }
);

T2->subtest(
    'cancellation, bounds and invalid discovery',
    sub {
        # Keep discovery pending so queue capacity and cancellation are observable.
        my $pending = Future->new;

        # A separate malformed discovery must fail queued acquisition without a send.
        my ( $limiter, $clock ) = limiter( responses => [$pending], max_pending => 1 );
        my $first_acquisition = $limiter->acquire(0);
        my $full = $limiter->acquire(1);
        T2->is( error($full)->category, 'queue_full', 'Identify queue bounded' );
        $first_acquisition->cancel;
        T2->is( $limiter->stats->{pending}, 0, 'cancelled Identify removed' );
        my $next_acquisition = $limiter->acquire(1);
        $limiter->close;
        T2->is( error($next_acquisition)->category, 'shutdown', 'close fails all pending work' );
        T2->ok( $pending->is_cancelled, 'discovery HTTP cancelled' );
        ( $limiter, $clock ) =
            limiter( responses => [ { url => 'wss://gateway.test', session_start_limit => { remaining => -1 } } ] );
        my $bad = $limiter->acquire(0);
        T2->is( error($bad)->category, 'protocol', 'malformed server limits rejected' );
        $limiter->close;
    }
);

T2->done_testing;
