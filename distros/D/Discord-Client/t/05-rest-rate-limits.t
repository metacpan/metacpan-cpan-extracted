use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordREST qw(client response error);

T2->subtest(
    'route discovery, reset and independent major parameters',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Queue two messages in one channel and one in another to distinguish major parameters.
        my $first_request = $rest->request( 'GET', '/channels/123/messages/456' );
        my $second_request = $rest->request( 'GET', '/channels/123/messages/789' );
        my $other = $rest->request( 'GET', '/channels/999/messages/789' );
        T2->is( $http->count, 2, 'unknown route serialized; different channel concurrent' );
        $http->respond(
            response(
                200, {},
                'X-RateLimit-Bucket' => 'same',
                'X-RateLimit-Remaining' => 0,
                'X-RateLimit-Reset-After' => 1.25
            ),
            0
        );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'same', 'X-RateLimit-Remaining' => 1 ), 1 );
        T2->ok( !$second_request->is_ready, 'same channel waits' );
        T2->is( $clock->timer_count, 1, 'one scheduler timer' );

        # Probe just before the fractional reset and then cross its exact boundary.
        $clock->advance(1.24);
        T2->is( $http->count, 2, 'fractional delay observed' );
        $clock->advance(0.01);
        T2->is( $http->count, 3, 'request sent after reset' );
        $http->respond( response( 200, {} ) );
        T2->ok( $first_request->is_done && $second_request->is_done && $other->is_done, 'all requests complete' );
        T2->is( $clock->timer_count, 0, 'no remaining timer' );
        $rest->close;
    }
);

T2->subtest(
    'discovered shared bucket',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Teach the scheduler that different HTTP methods share a server bucket.
        my $first_request = $rest->request( 'GET', '/channels/123/messages' );
        my $second_request = $rest->request( 'POST', '/channels/123/messages', json => {} );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'shared', 'X-RateLimit-Remaining' => 2 ), 0 );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'shared', 'X-RateLimit-Remaining' => 2 ), 1 );

        # Exhaust the learned bucket and verify both methods obey its reset.
        my $next_read = $rest->request( 'GET', '/channels/123/messages' );
        my $next_write = $rest->request( 'POST', '/channels/123/messages', json => {} );
        T2->is( $http->count, 3, 'methods sharing bucket serialize' );
        $http->respond(
            response(
                200, {},
                'X-RateLimit-Bucket' => 'shared',
                'X-RateLimit-Remaining' => 0,
                'X-RateLimit-Reset-After' => 2
            ),
            2
        );
        T2->is( $http->count, 3, 'shared bucket exhausts across methods' );
        $clock->advance(2);
        T2->is( $http->count, 4, 'shared bucket resumes' );
        $http->respond( response( 200, {} ) );
        T2->ok( $next_read->is_done && $next_write->is_done, 'both complete' );
        $rest->close;
    }
);

T2->subtest(
    'merging into a bucket with an outstanding request',
    sub {
        my ( $rest, $http ) = client();
        my $first_request = $rest->request( 'GET', '/channels/123/messages' );
        my $second_request = $rest->request( 'POST', '/channels/123/messages' );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'shared', 'X-RateLimit-Remaining' => 3 ), 0 );

        # Keep a request active while a different route learns the same bucket alias.
        my $pending_read = $rest->request( 'GET', '/channels/123/messages' );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'shared', 'X-RateLimit-Remaining' => 3 ), 1 );
        my $next_request = $rest->request( 'POST', '/channels/123/messages' );
        T2->is( $http->count, 3, 'merged route waits for existing in-flight request' );

        # Cancellation must release the merged reservation once and unblock the next route.
        $pending_read->cancel;
        T2->is( $http->count, 4, 'cancellation releases merged bucket once' );
        $http->respond( response( 200, {} ), 3 );
        T2->ok( $first_request->is_done && $second_request->is_done && $next_request->is_done,
            'merged bucket drains correctly' );
        $rest->close;
    }
);

T2->subtest(
    'route and global 429 delays',
    sub {
        for my $global ( 0, 1 ) {
            my ( $rest, $http, $clock ) = client();

            # Compare route-only and global rejection while an unrelated guild request is queued.
            my $first_request = $rest->request( 'POST', '/channels/123/messages', json => {} );
            $http->respond( response( 429, { retry_after => 1.5, global => $global }, 'Retry-After' => 2 ) );
            my $second_request = $rest->request( 'GET', '/guilds/999' );
            T2->is( $http->count, $global ? 1 : 2, 'global pauses unrelated routes; local does not' );
            $http->respond( response( 200, {} ), 1 ) unless $global;

            # The larger header delay takes precedence over the body delay.
            $clock->advance(1.99);
            T2->is( $http->count, $global ? 1 : 2, 'uses longer retry delay' );
            $clock->advance(0.01);
            T2->is( $http->count, 3, 'retry and independent route dispatched' );
            $http->respond( response( 200, {} ), $global ? 1 : 2 );
            $http->respond( response( 200, {} ), 2 ) if $global;
            T2->ok(
                $first_request->is_done && $second_request->is_done,
                '429 POST retried only after received rejection'
            );
            $rest->close;
        }
    }
);

T2->subtest(
    'shared 429 overrides positive remaining',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Advertise spare quota and an earlier reset alongside a longer shared restriction.
        my $request_future = $rest->request( 'GET', '/channels/123' );
        $http->respond(
            response(
                429, { retry_after => 4 },
                'X-RateLimit-Scope' => 'shared',
                'X-RateLimit-Remaining' => 9,
                'X-RateLimit-Reset-After' => 1
            )
        );

        # The shared restriction must remain authoritative after the bucket reset.
        $clock->advance(3.99);
        T2->is( $http->count, 1, 'shared retry_after respected after bucket reset' );
        $clock->advance(0.01);
        T2->is( $http->count, 2, 'resource restriction expires' );
        $http->respond( response( 200, {} ) );
        T2->ok( $request_future->is_done, 'request completes' );
        $rest->close;
    }
);

T2->subtest(
    'header fallback and retry budget',
    sub {
        my ( $rest, $http, $clock ) = client( max_retries => 1 );

        # Use a non-JSON rejection first, then exhaust the configured retry budget.
        my $request_future = $rest->request( 'GET', '/channels/123' );
        $http->respond( HTTP::Response->new( 429, undef, [ 'Retry-After' => 0.5 ], 'not JSON' ) );
        $clock->advance(0.5);
        $http->respond( response( 429, { retry_after => 1 } ) );
        T2->is( error($request_future)->category, 'rate_limit', 'retry budget exhausted' );
        T2->is( error($request_future)->status, 429, 'last HTTP status retained' );
        $clock->advance(100);
        T2->is( $http->count, 2, 'retry count bounded' );
        T2->is( $clock->timer_count, 0, 'no timer after failure' );

        # A zero retry delay must fail rather than repeatedly scheduling immediate work.
        my $bad = $rest->request( 'GET', '/channels/999' );
        $http->respond( response( 429, { retry_after => 0 } ) );
        T2->is( error($bad)->category, 'rate_limit', 'invalid delay cannot busy-loop' );
        $rest->close;
    }
);

T2->subtest(
    'absolute reset fallback and safe missing headers',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Map a wall-clock reset to monotonic time while another request waits.
        my $first_request = $rest->request( 'GET', '/guilds/123' );
        my $second_request = $rest->request( 'GET', '/guilds/123' );
        $http->respond( response( 200, {}, 'X-RateLimit-Remaining' => 0, 'X-RateLimit-Reset' => 1002 ) );
        $clock->advance(1.99);
        T2->is( $http->count, 1, 'absolute reset mapped to monotonic clock' );
        $clock->advance(0.01);
        $http->respond( response( 200, {}, 'X-RateLimit-Remaining' => 0 ) );

        # Missing reset metadata must allow a probe instead of permanently blocking the route.
        my $next_request = $rest->request( 'GET', '/guilds/123' );
        T2->is( $http->count, 3, 'missing reset does not wedge route' );
        $http->respond( response( 200, {} ) );
        T2->ok( $first_request->is_done && $second_request->is_done && $next_request->is_done, 'completes' );
        $rest->close;
    }
);

T2->subtest(
    'zero retries and global header detection',
    sub {
        my ( $rest, $http, $clock ) = client( max_retries => 0 );

        # Even an unretried 429 must publish the global limit for later requests.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        $http->respond( response( 429, { retry_after => 1 }, 'X-RateLimit-Global' => 'true' ) );
        T2->is( error($first_request)->category, 'rate_limit', 'zero retries fails immediately' );
        my $second_request = $rest->request( 'GET', '/guilds/999' );
        T2->is( $http->count, 1, 'global header still restricts subsequent routes' );
        $clock->advance(1);
        T2->is( $http->count, 2, 'new route waits for global reset' );
        $http->respond( response( 200, {} ), 1 );
        T2->ok( $second_request->is_done, 'new request completes without retrying original' );
        $rest->close;
    }
);

T2->subtest(
    'webhook ID and token partition',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Discover matching server hashes under different webhook tokens.
        my $first_request = $rest->request( 'POST', '/webhooks/123/ONE' );
        my $second_request = $rest->request( 'POST', '/webhooks/123/TWO' );
        T2->is( $http->count, 2, 'different tokens discover independently' );
        $http->respond(
            response(
                200, {},
                'X-RateLimit-Bucket' => 'w',
                'X-RateLimit-Remaining' => 0,
                'X-RateLimit-Reset-After' => 5
            ),
            0
        );
        $http->respond( response( 200, {}, 'X-RateLimit-Bucket' => 'w', 'X-RateLimit-Remaining' => 1 ), 1 );

        # Exhaust one token without delaying the other, then release the waiting timer.
        my $blocked = $rest->request( 'POST', '/webhooks/123/ONE' );
        my $free = $rest->request( 'POST', '/webhooks/123/TWO' );
        T2->is( $http->count, 3, 'same bucket hash has independent webhook-token quota' );
        $http->respond( response( 200, {} ), 2 );
        $blocked->cancel;
        T2->is( $clock->timer_count, 0, 'cancel removes last waiting timer' );
        $rest->close;
    }
);

T2->done_testing;
