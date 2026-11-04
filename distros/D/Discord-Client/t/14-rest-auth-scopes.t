use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordREST qw(client response error);

T2->subtest(
    'interaction requests bypass bot global limit and authorization',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Rate-limit Bot authorization before sending an interaction-token callback.
        my $bot = $rest->request( 'GET', '/users/@me' );
        $http->respond( response( 429, { retry_after => 2, global => 1 } ) );
        my $reply = $rest->request(
            'POST', '/interactions/123/INTERACTION_SECRET/callback',
            auth => 0,
            json => { type => 4 }
        );
        T2->is( $http->count, 2, 'token-only request bypasses bot global pause' );
        T2->ok( !defined( $http->call->{request}->header('Authorization') ),
            'Bot credentials not attached to interaction' );
        $http->respond( response( 204, undef ), 1 );
        T2->ok( $reply->is_done, 'interaction can acknowledge while bot is rate limited' );

        # The Bot retry still waits for its own global window.
        $clock->advance(2);
        $http->respond( response( 200, {} ), 2 );
        T2->ok( $bot->is_done, 'bot retry respects its own pause' );
        $rest->close;
    }
);

T2->subtest(
    'token-only global 429 pauses its own scope',
    sub {
        my ( $rest, $http, $clock ) = client();

        # Reverse the scopes: a token-only global pause must leave Bot traffic available.
        my $reply = $rest->request( 'POST', '/webhooks/123/INTERACTION_SECRET', auth => 0 );
        $http->respond( response( 429, { retry_after => 1, global => 1 } ) );
        my $bot = $rest->request( 'GET', '/users/@me' );
        T2->is( $http->count, 2, 'unauthenticated global pause does not pause Bot requests' );
        $http->respond( response( 200, {} ), 1 );
        $clock->advance(0.99);
        T2->is( $http->count, 2, 'received 429 delay still enforced' );
        $clock->advance(0.01);
        $http->respond( response( 200, {} ), 2 );
        T2->ok( $reply->is_done && $bot->is_done, 'both scopes finish' );
        $rest->close;
    }
);

T2->subtest(
    '401 only invalidates the credential actually used',
    sub {
        my ( $rest, $http ) = client();

        # Reject an interaction token without invalidating the independent Bot credential.
        my $bad = $rest->request( 'POST', '/interactions/123/TOKEN/callback', auth => 0 );
        $http->respond( response( 401, { code => 0 } ) );
        T2->is( error($bad)->category, 'authentication', '401 still categorized' );
        my $bot = $rest->request( 'GET', '/users/@me' );
        T2->is( $http->count, 2, 'interaction rejection does not invalidate Bot token' );
        $http->respond( response( 401, { code => 0 } ), 1 );

        # After Bot rejection, another interaction token must still be usable.
        my $followup = $rest->request( 'POST', '/webhooks/123/VALID_INTERACTION_TOKEN', auth => 0 );
        T2->is( $http->count, 3, 'rejected Bot token does not stop token-only operations' );
        $http->respond( response( 200, {} ), 2 );
        T2->ok( $followup->is_done, 'followup remains available' );
        $rest->close;
    }
);

T2->subtest(
    'HTTP interaction applications need no Bot token',
    sub {
        my ( $rest, $http ) = client( auth => 0, token => undef );

        # Exercise token-only requests and redact both escaped and unescaped token forms.
        my $request_future = $rest->request( 'POST', '/webhooks/123/URL%2FSECRET' );
        T2->ok( !defined( $http->call->{request}->header('Authorization') ), 'tokenless client supported' );
        $http->respond( response( 400, { message => 'URL/SECRET URL%2FSECRET' } ) );
        T2->unlike( error($request_future)->details->{message},
            qr/SECRET/, 'encoded and decoded URL credentials redacted' );

        # Numeric-looking tokens are opaque secrets, not resource IDs.
        $request_future = $rest->request( 'POST', '/interactions/123/987654321/callback' );
        $http->respond( response( 400, { message => 'invalid 987654321' } ) );
        T2->unlike( error($request_future)->details->{message},
            qr/987654321/, 'opaque numeric interaction token is still redacted' );
        T2->is( error( $rest->request( 'GET', '/users/@me', auth => 1 ) )->category,
            'request', 'Bot authorization still requires token' );
        $rest->close;
    }
);

T2->done_testing;
