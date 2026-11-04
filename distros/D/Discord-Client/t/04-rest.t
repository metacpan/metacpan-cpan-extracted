use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use HTTP::Response;
use lib 't/lib';
use TestDiscordREST qw(client response error);

T2->subtest(
    'JSON requests use API v10, Bot authorization and verified HTTPS',
    sub {
        my ( $rest, $http ) = client();
        T2->is( $http->count, 0, 'construction performs no HTTP I/O' );

        # Send Unicode through the fake transport and inspect the actual request envelope.
        my $future = $rest->request( 'POST', '/channels/123/messages', json => { content => "hello \x{2603}" } );

        T2->isa_ok( $future, 'Future' );
        my $transport = $http->call;
        my $request = $transport->{request};
        T2->is( $request->uri, 'https://discord.com/api/v10/channels/123/messages', 'the URL selects API v10' );
        T2->is( $transport->{host}, 'discord.com', 'the transport receives the Discord hostname' );
        T2->ok( $transport->{SSL}, 'HTTPS is explicitly enabled' );
        T2->is( $request->header('Authorization'), 'Bot FAKE_TEST_TOKEN', 'the request uses Bot authorization' );
        my $version = $Discord::Client::VERSION;
        T2->like(
            $request->header('User-Agent'),
            qr/^DiscordBot \(https:\/\/.+, \Q$version\E\)$/,
            'User-Agent identifies the SDK version'
        );
        T2->is( $request->content_type, 'application/json', 'JSON content type is sent' );
        T2->is(
            JSON::PP->new->utf8->decode( $request->content ),
            { content => "hello \x{2603}" },
            'non-ASCII content is transmitted as UTF-8 JSON'
        );
        T2->is( $transport->{max_redirects}, 0, 'credentials cannot follow a redirect' );

        # Return a uint64-sized string ID and unknown fields without narrowing either.
        my $message = { id => '18446744073709551615', extra => [ 1, 2 ] };
        $http->respond( response( 200, $message ) );
        T2->is( scalar( $future->get ), $message, 'large snowflakes and unknown fields survive decoding' );
        $rest->close;
    }
);

T2->subtest(
    'array-valued query parameters are repeated and array responses stay arrays',
    sub {
        my ( $rest, $http ) = client();

        # Exercise repeated query values and preserve the response collection shape.
        my $future =
            $rest->request( 'GET', '/users/@me', query => { id => [ '123', '456' ], limit => 2 } );

        T2->is( $http->call->{request}->uri->query,
            'id=123&id=456&limit=2', 'each query value is encoded separately' );
        $http->respond( response( 200, [ 1, 2 ] ) );
        T2->is( scalar( $future->get ), [ 1, 2 ], 'JSON array responses are preserved' );
        $rest->close;
    }
);

T2->subtest(
    'HTTP 204 and HEAD do not require JSON bodies',
    sub {
        my ( $rest, $http ) = client();

        # A successful deletion has no JSON document to decode.
        my $deletion = $rest->request( 'DELETE', '/channels/123/messages/456' );
        $http->respond( response( 204, undef ) );
        T2->is( scalar( $deletion->get ), undef, 'HTTP 204 resolves without JSON' );

        # HEAD also omits the body even when the status is 200.
        my $head = $rest->request( 'HEAD', '/users/@me' );
        $http->respond( HTTP::Response->new(200) );
        T2->is( scalar( $head->get ), undef, 'HEAD resolves without JSON' );
        $rest->close;
    }
);

T2->subtest(
    'raw responses expose headers without retaining credential-bearing requests',
    sub {
        my ( $rest, $http ) = client();
        my $future = $rest->request( 'GET', '/users/@me', raw_response => 1 );

        # Attach a credential-bearing request to the response as a real transport might.
        my $original = response( 200, { id => '12' }, 'X-Example' => 'value' );
        $original->request( $http->call->{request} );
        $http->respond($original);

        # Expose detached response metadata without retaining or mutating the source request.
        my $raw = $future->get;
        T2->isa_ok( $raw, 'HTTP::Response' );
        T2->is( $raw->header('X-Example'), 'value', 'server headers are available' );
        T2->is( $raw->request, undef, 'the authorization-bearing request is detached' );
        $raw->header( 'X-Example' => 'changed' );
        T2->is( $original->header('X-Example'), 'value', 'caller edits do not mutate the injected response' );
        $rest->close;
    }
);

# Cover status classification and actionable Discord diagnostics with fresh clients.
my @http_failures = (
    { name => 'permission denied', status => 403, category => 'permission' },
    { name => 'resource missing', status => 404, category => 'not_found' },
    { name => 'internal server failure', status => 500, category => 'server' },
    { name => 'upstream server failure', status => 502, category => 'server' },
    { name => 'invalid request rejected by Discord', status => 400, category => 'http' },
);
for my $case (@http_failures) {
    T2->subtest(
        "$case->{name} preserves actionable HTTP/Discord details",
        sub {
            my ( $rest, $http ) = client();
            my $future = $rest->request( 'POST', '/channels/123/messages', json => { content => 'test' } );
            $http->respond(
                response(
                    $case->{status},
                    { code => 50035, message => 'failure', errors => { content => 'invalid' } },
                    'X-Request-ID' => 'req1'
                )
            );

            T2->ok( $future->is_failed, 'the HTTP rejection fails the request Future' );
            my $error = error($future);
            T2->isa_ok( $error, 'Discord::Client::REST::Error' );
            T2->is( $error->category, $case->{category}, 'failure category' );
            T2->is( $error->status, $case->{status}, 'HTTP status' );
            T2->is( $error->discord_code, 50035, 'Discord error code' );
            T2->is( $error->request_id, 'req1', 'server request identifier' );
            T2->is( $error->details->{errors}, { content => 'invalid' }, 'structured validation detail' );
            $rest->close;
        }
    );
}

T2->subtest(
    'malformed successful JSON fails without exposing the response body',
    sub {
        my ( $rest, $http ) = client();

        # Place a token in malformed content to check the parser failure cannot disclose it.
        my $future = $rest->request( 'GET', '/users/@me' );
        $http->respond( HTTP::Response->new( 200, undef, [], '{broken FAKE_TEST_TOKEN' ) );

        T2->is( error($future)->category, 'json', 'a successful status still needs valid JSON' );
        T2->unlike( join( ' ', $future->failure ),
            qr/FAKE_TEST_TOKEN/, 'parser diagnostics omit response content' );
        $rest->close;
    }
);

T2->subtest(
    'non-JSON server errors retain the HTTP failure category',
    sub {
        my ( $rest, $http ) = client();

        # A server error page must keep its HTTP category even though it is not JSON.
        my $future = $rest->request( 'GET', '/users/@me' );
        $http->respond( HTTP::Response->new( 503, undef, [], '<html>unavailable</html>' ) );

        T2->is( error($future)->category, 'server', 'HTTP failure takes precedence over JSON decoding' );
        T2->is( error($future)->status, 503, 'the server status remains available' );
        $rest->close;
    }
);

T2->subtest(
    'failure details redact Bot, webhook and nested authorization credentials',
    sub {
        my ( $rest, $http ) = client();

        # Simulate credentials echoed in message text, named fields and nested structures.
        my $future = $rest->request( 'POST', '/webhooks/123/WEBHOOK_SECRET', json => {} );
        $http->respond(
            response(
                400,
                {
                    code => 50035,
                    message => 'FAKE_TEST_TOKEN WEBHOOK_SECRET',
                    token => 'other secret',
                    nested => [ { authorization => 'other secret' } ]
                }
            )
        );

        T2->unlike(
            JSON::PP->new->encode( error($future)->details ),
            qr/FAKE_TEST_TOKEN|WEBHOOK_SECRET|other secret/,
            'structured errors omit all credentials'
        );
        T2->unlike(
            join( ' ', $future->failure ),
            qr/SECRET|FAKE_TEST_TOKEN/,
            'failure strings are also sanitized'
        );
        $rest->close;
    }
);

# Reject paths that could change the intended API destination before calling HTTP.
my @invalid_paths = (
    { name => 'absolute URL', path => 'https://evil.test/a' },
    { name => 'scheme-relative URL', path => '//evil.test/a' },
    { name => 'parent directory traversal', path => '/a/../b' },
    { name => 'control character', path => "/a\n" },
    { name => 'URL fragment', path => '/a#frag' },
);
for my $case (@invalid_paths) {
    T2->subtest(
        "reject $case->{name} before sending HTTP",
        sub {
            my ( $rest, $http ) = client();
            my $future = $rest->request( 'GET', $case->{path} );

            T2->is( error($future)->category, 'request', 'invalid paths produce a failed Future' );
            T2->is( $http->count, 0, 'the transport was not called' );
            $rest->close;
        }
    );
}

T2->subtest(
    'unencodable bodies fail before sending HTTP',
    sub {
        my ( $rest, $http ) = client();

        # Serialization failure is local and must not consume a request slot.
        my $future = $rest->request( 'GET', '/users/@me', json => sub { } );

        T2->is( error($future)->category, 'request', 'invalid JSON bodies produce a failed Future' );
        T2->is( $http->count, 0, 'the transport was not called' );
        $rest->close;
    }
);

T2->done_testing;
