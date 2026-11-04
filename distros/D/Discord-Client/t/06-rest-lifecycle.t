use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordREST qw(client response error);

T2->subtest(
    'queue bounds and cancellation',
    sub {
        my ( $rest, $http, $clock ) = client( max_pending => 2 );

        # Fill capacity with one active and one waiting request before testing rejection.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        my $second_request = $rest->request( 'GET', '/channels/123' );
        my $full = $rest->request( 'GET', '/channels/123' );
        T2->is( error($full)->category, 'queue_full', 'active and queued requests bounded together' );

        # Replace a cancelled queued request and confirm it never reaches the transport.
        $second_request->cancel;
        my $replacement_request = $rest->request( 'GET', '/channels/123' );
        T2->ok( !$replacement_request->is_ready, 'cancellation frees queue capacity' );
        $http->respond( response( 200, {} ), 0 );
        T2->is( $http->count, 2, 'cancelled queued request never sent' );
        $http->respond( response( 200, {} ), 1 );
        T2->ok( $replacement_request->is_done, 'replacement completes' );
        $rest->close;
    }
);

T2->subtest(
    'in-flight cancellation releases concurrency',
    sub {
        my ( $rest, $http ) = client( max_in_flight => 1 );

        # Use a single global slot so cancellation is the only way another route can start.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        my $second_request = $rest->request( 'GET', '/channels/999' );
        T2->is( $http->count, 1, 'global in-flight limit' );

        # Cancellation must reach HTTP and release the concurrency reservation.
        $first_request->cancel;
        T2->ok( $http->call(0)->{future}->is_cancelled, 'cancellation propagates to HTTP' );
        T2->is( $http->count, 2, 'next route makes progress' );
        $http->respond( response( 200, {} ), 1 );
        T2->ok( $second_request->is_done, 'next request completes' );
        $rest->close;
    }
);

T2->subtest(
    'transport and timeout failures do not retry POST',
    sub {
        for my $category ( 'timeout', 'stall_timeout', 'http' ) {
            my ( $rest, $http ) = client();

            # Fail ambiguous POST delivery with private diagnostics and verify it is never replayed.
            my $request_future = $rest->request( 'POST', '/channels/123/messages', json => {} );
            $http->call->{future}
                ->fail( 'FAKE_TEST_TOKEN request failed', $category, undef, $http->call->{request} );
            T2->is(
                error($request_future)->category,
                $category eq 'http' ? 'transport' : 'timeout',
                'failure classified'
            );
            T2->unlike( join( ' ', $request_future->failure ), qr/FAKE_TEST_TOKEN/, 'transport failure sanitized' );
            T2->is( $http->count, 1, 'ambiguous POST not retried' );
            $rest->close;
        }
    }
);

T2->subtest(
    'invalid token halts queued and future requests',
    sub {
        my ( $rest, $http ) = client( max_in_flight => 1 );

        # Queue unrelated routes behind a request that will invalidate Bot authorization.
        my $first_request = $rest->request( 'GET', '/users/@me' );
        my $second_request = $rest->request( 'GET', '/channels/123' );
        my $extra = $rest->request( 'GET', '/guilds/123' );
        $http->respond( response( 401, { code => 0, message => '401: Unauthorized' } ) );
        T2->is( error($first_request)->status, 401, '401 status' );
        T2->is( error($first_request)->category, 'authentication', '401 authentication category' );
        T2->is( error($second_request)->category, 'authentication', 'queued request halted' );
        T2->is( error($extra)->category, 'authentication', 'all queued requests halted' );

        # Future admission must also stop without generating an invalid-request storm.
        my $replacement_request = $rest->request( 'GET', '/guilds/999' );
        T2->is( error($replacement_request)->category, 'authentication', 'subsequent request halted' );
        T2->is( $http->count, 1, 'no invalid-request storm' );
        $rest->close;
    }
);

T2->subtest(
    'in-flight 429 cannot retry after another request invalidates token',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Deliver an authentication failure before a concurrent request returns a retryable 429.
        my $first_request = $rest->request( 'GET', '/users/@me' );
        my $second_request = $rest->request( 'POST', '/channels/123/messages' );
        $http->respond( response( 401, { code => 0 } ), 0 );
        $http->respond( response( 429, { retry_after => 1 } ), 1 );
        T2->is( error($second_request)->category, 'authentication', 'active retry also stops' );
        $clock->advance(100);
        T2->is( $http->count, 2, 'no sends after token invalidation' );
        T2->is( $clock->timer_count, 0, 'no retry timer' );
        $rest->close;
    }
);

T2->subtest(
    'HTTP transports that fail on errors still permit 429 retry',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Inject a transport that reports HTTP rejection through a failed Future.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        $http->call->{future}->fail( '429', 'http', response( 429, { retry_after => 1 } ), $http->call->{request} );
        $clock->advance(1);
        T2->is( $http->count, 2, '429 failure response reaches limiter' );
        $http->respond( response( 200, {} ) );
        T2->ok( $first_request->is_done, 'retry succeeds' );
        $rest->close;
    }
);

T2->subtest(
    'close cancels timers and active I/O',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Keep one request waiting on a retry timer and another active in HTTP.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        $http->respond( response( 429, { retry_after => 10 } ) );
        my $second_request = $rest->request( 'GET', '/guilds/999' );
        T2->is( $clock->timer_count, 1, 'retry timer pending' );

        # Shutdown must settle both requests, cancel I/O and prevent later timer activity.
        $rest->close->get;
        T2->is( error($first_request)->category, 'shutdown', 'waiting request failed on shutdown' );
        T2->is( error($second_request)->category, 'shutdown', 'active request failed on shutdown' );
        T2->ok( $http->call(1)->{future}->is_cancelled, 'active HTTP cancelled' );
        T2->is( $clock->timer_count, 0, 'shutdown timer removed' );
        T2->is( error( $rest->request( 'GET', '/users/@me' ) )->category,
            'shutdown', 'closed client rejects work' );
        $rest->close->get;
        $clock->advance(100);
        T2->is( $http->count, 2, 'no work after shutdown' );
    }
);

T2->subtest(
    'route metadata capacity and eviction',
    sub {
        my ( $rest, $http, $clock ) = client( max_buckets => 1 );

        # Protect the sole metadata slot while its route is active or rate-limited.
        my $first_request = $rest->request( 'GET', '/channels/123' );
        my $second_request = $rest->request( 'GET', '/channels/999' );
        T2->is( error($second_request)->category, 'queue_full', 'active route metadata cannot be evicted' );
        $http->respond(
            response(
                200, {},
                'X-RateLimit-Bucket' => 'one',
                'X-RateLimit-Remaining' => 0,
                'X-RateLimit-Reset-After' => 2
            )
        );
        T2->is( error( $rest->request( 'GET', '/channels/999' ) )->category,
            'queue_full', 'unexpired quota retained' );

        # Once the quota expires, another route can safely replace the old metadata.
        $clock->advance(2);
        my $replacement_request = $rest->request( 'GET', '/channels/999' );
        T2->is( $http->count, 2, 'expired unused route evicted' );
        $http->respond( response( 200, {} ) );
        T2->ok( $replacement_request->is_done, 'replacement route works' );
        $rest->close;
    }
);

T2->done_testing;
