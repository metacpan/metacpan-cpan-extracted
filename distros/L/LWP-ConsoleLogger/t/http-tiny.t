use strict;
use warnings;

use HTTP::Tiny               ();
use LWP::ConsoleLogger::Easy qw( debug_ua );
use Log::Dispatch            ();
use Log::Dispatch::Array     ();
use Plack::Loader            ();
use Ref::Util                qw( is_hashref );
use Test::More import => [qw( done_testing is like ok unlike )];
use Test::TCP;

# Unit assertions (no network).
{
    my $logger = debug_ua( HTTP::Tiny->new );
    ok(
        $logger->isa('LWP::ConsoleLogger'),
        'debug_ua returns a configured LWP::ConsoleLogger'
    );
    ok( $logger->dump_content, 'dump_content defaults on' );

    my $silent = debug_ua( HTTP::Tiny->new, 0 );
    ok( !$silent->dump_content, 'verbosity 0 turns dump_content off' );
    ok( !$silent->dump_headers, 'verbosity 0 turns dump_headers off' );
}

# Request-object translation edge cases (no network). These exercise the
# header synthesis that mirrors what HTTP::Tiny puts on the wire.
{
    my $ua = HTTP::Tiny->new;

    # An IPv6 literal with a non-default port must be bracketed in the Host
    # header, matching HTTP::Tiny's host_port (e.g. [::1]:8080). URI->host
    # returns the address without brackets.
    my $ipv6 = LWP::ConsoleLogger::Easy::_http_tiny_request_object(
        $ua, 'GET',
        'http://[::1]:8080/x', {}
    );
    is(
        $ipv6->header('Host'), '[::1]:8080',
        'IPv6 host with custom port is bracketed in the Host header'
    );

    # An empty-body POST/PUT gets an explicit Content-Length: 0, as HTTP::Tiny
    # sends so servers do not wait for a body.
    for my $method (qw( POST PUT )) {
        my $req = LWP::ConsoleLogger::Easy::_http_tiny_request_object(
            $ua,
            $method, 'http://example.com/', {}
        );
        is(
            $req->header('Content-Length'), 0,
            "empty $method logs Content-Length: 0"
        );
    }

    # A coderef (streaming) body is not an empty body: HTTP::Tiny uses chunked
    # transfer-encoding, so no zero Content-Length should be synthesized.
    my $stream = LWP::ConsoleLogger::Easy::_http_tiny_request_object(
        $ua, 'POST', 'http://example.com/',
        { content => sub { q{} } }
    );
    ok(
        !defined $stream->header('Content-Length'),
        'coderef POST body does not get a zero Content-Length'
    );

    # A GET with no body is untouched.
    my $get = LWP::ConsoleLogger::Easy::_http_tiny_request_object(
        $ua, 'GET',
        'http://example.com/', {}
    );
    ok(
        !defined $get->header('Content-Length'),
        'empty GET has no Content-Length'
    );
}

# Multiple loggers instrumenting one HTTP::Tiny instance must both fire; an
# earlier debug_ua() call must not be overwritten by a later one. Uses the
# synthetic 599 file:// path so no network is required.
{
    my $ua = HTTP::Tiny->new;

    my @outputs;
    for my $i ( 0, 1 ) {
        my $logger = debug_ua($ua);
        $logger->text_pre_filter( sub { shift } );
        my $output = [];
        my $ld     = Log::Dispatch->new;
        $ld->add(
            Log::Dispatch::Array->new(
                name      => "multi$i",
                min_level => 'debug',
                array     => $output,
            )
        );
        $logger->logger($ld);
        push @outputs, $output;
    }

    $ua->get('file:///no/such');

    for my $i ( 0, 1 ) {
        my $log = join "\n", map { $_->{message} } @{ $outputs[$i] };
        like(
            $log, qr{599},
            "logger $i attached to the same UA still fires"
        );
    }
}

# Live capture through a real HTTP server (HTTP::Tiny does not support
# file:// URLs).
test_tcp(
    client => sub {
        my $port = shift;
        my $base = "http://127.0.0.1:$port/";

        my $ua     = HTTP::Tiny->new;
        my $logger = debug_ua($ua);

        my $output = [];
        my $ld     = Log::Dispatch->new;
        $ld->add(
            Log::Dispatch::Array->new(
                name      => 'test',
                min_level => 'debug',
                array     => $output,
            )
        );
        $logger->logger($ld);

        # Neutralize any Lynx-based text filter so body assertions are
        # environment-independent.
        $logger->text_pre_filter( sub { shift } );

        # GET
        my $get = $ua->get($base);
        is( $get->{status}, 200, 'GET returns 200' );

        my $get_log = join "\n", map { $_->{message} } @{$output};
        like( $get_log, qr{GET},       'logs the GET method' );
        like( $get_log, qr{\Q$base\E}, 'logs the request URL' );
        like( $get_log, qr{200},       'logs the 200 status' );
        like( $get_log, qr{flywheel},  'logs a response header value' );
        like( $get_log, qr{banana},    'logs a body token' );

        # POST with a form body
        @{$output} = ();
        my $post = $ua->post_form( $base, { quux => 'zap' } );
        is( $post->{status}, 200, 'POST returns 200' );

        my $post_log = join "\n", map { $_->{message} } @{$output};
        like( $post_log, qr{POST}, 'logs the POST method' );
        like( $post_log, qr{quux}, 'params table shows the form key' );

        # Per-request headers override default_headers (last-wins), and the
        # overridden header appears exactly once with no duplicate row.
        @{$output} = ();
        my $dup_ua = HTTP::Tiny->new(
            default_headers => { 'X-Dup' => 'from-default' } );
        my $dup_logger = debug_ua($dup_ua);
        $dup_logger->text_pre_filter( sub { shift } );

        my $dup_output = [];
        my $dup_ld     = Log::Dispatch->new;
        $dup_ld->add(
            Log::Dispatch::Array->new(
                name      => 'dup',
                min_level => 'debug',
                array     => $dup_output,
            )
        );
        $dup_logger->logger($dup_ld);

        my $dup_get = $dup_ua->get(
            $base,
            { headers => { 'X-Dup' => 'from-request' } }
        );
        is( $dup_get->{status}, 200, 'override GET returns 200' );

        my $dup_log = join "\n", map { $_->{message} } @{$dup_output};
        like(
            $dup_log, qr{from-request},
            'per-request header value is logged'
        );
        unlike(
            $dup_log, qr{from-default},
            'default header value is overridden, not duplicated'
        );

        # The logger prints two request-header tables (before and after
        # sending). 'X-Dup' must appear as a single row in each, i.e. exactly
        # twice overall and never with a duplicate/merged value row.
        my @dup_rows = ( $dup_log =~ /^\|\s*X-Dup\s.*$/mg );
        is( scalar(@dup_rows), 2, 'X-Dup is a single row per request table' );
        unlike(
            join( "\n", @dup_rows ),
            qr{from-default},
            'no X-Dup row carries the overridden default value'
        );
    },
    server => sub {
        my $port = shift;
        my $app  = sub {
            return [
                200,
                [
                    'Content-Type' => 'text/html',
                    'X-LWPCL-Test' => 'flywheel',
                ],
                ['<html><body>banana</body></html>'],
            ];
        };
        Plack::Loader->auto( port => $port, host => '127.0.0.1' )->run($app);
    },
);

# Error/599 resilience: HTTP::Tiny returns a synthetic 599 response for an
# unsupported URL scheme rather than dying. The logging wrapper must translate
# that error response and must not crash the caller.
{
    my $ua     = HTTP::Tiny->new;
    my $logger = debug_ua($ua);
    $logger->text_pre_filter( sub { shift } );

    my $output = [];
    my $ld     = Log::Dispatch->new;
    $ld->add(
        Log::Dispatch::Array->new(
            name      => 'err',
            min_level => 'debug',
            array     => $output,
        )
    );
    $logger->logger($ld);

    my $res = $ua->get('file:///no/such');
    ok(
        is_hashref($res),
        'error request does not die and returns a hashref'
    );
    is( $res->{status}, 599, 'HTTP::Tiny returns a 599 error response' );

    my $err_log = join "\n", map { $_->{message} } @{$output};
    like( $err_log, qr{599}, 'logger captured the 599 status' );
}

done_testing();
