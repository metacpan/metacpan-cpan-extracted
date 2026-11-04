use v5.26;
use warnings;
use Test2::V1;
use IO::Async::Loop;
use IO::Async::Listener;
use Net::Async::HTTP;
use Discord::Client::REST;

# Serve HTTP only on an ephemeral loopback port; no Discord connection is involved.
my $loop = IO::Async::Loop->new;
my ( @requests, @streams );
my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my ( undef, $stream ) = @_;
        push @streams, $stream;
        $stream->configure(
            on_read => sub {
                my ( $stream, $buffer, $eof ) = @_;

                # Wait for a complete header and declared body before recording a wire request.
                return 0 unless $$buffer =~ /\r\n\r\n/;
                my $end = index( $$buffer, "\r\n\r\n" ) + 4;
                my ($length) = substr( $$buffer, 0, $end ) =~ /^Content-Length: (\d+)/mi;
                $length //= 0;
                return 0 if length($$buffer) < $end + $length;
                my $request = substr( $$buffer, 0, $end + $length, '' );
                push @requests, $request;

                # Deliberately leave one route unanswered to exercise the real adapter timeout.
                return 0 if $request =~ m{^GET /api/v10/silent };
                my $body = '{"id":"18446744073709551615"}';
                $stream->write( "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "
                        . length($body)
                        . "\r\nConnection: close\r\n\r\n$body" );
                $stream->close_when_empty;
                return 0;
            }
        );
        $loop->add($stream);
    }
);
$loop->add($listener);
$listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;

# Point the real HTTP adapter at the local server while retaining the API path prefix.
my $base = 'http://127.0.0.1:' . $listener->read_handle->sockport . '/api/v10';
my $rest = Discord::Client::REST->new(
    token => 'FAKE_TEST_TOKEN',
    loop => $loop,
    base_url => $base,
    timeout => 2
);

# Verify request targets, headers and JSON against bytes received by the server.
T2->ref_is( $rest->loop, $loop, 'caller loop retained' );
T2->is(
    $rest->request( 'GET', '/users/@me', query => { limit => 1 } )->get,
    { id => '18446744073709551615' },
    'real HTTP transport decodes response'
);
T2->like( $requests[0], qr{^GET /api/v10/users/\@me\?limit=1 HTTP/1\.1\r\n}, 'actual request target' );
T2->like( $requests[0], qr/^Authorization: Bot FAKE_TEST_TOKEN\r$/m, 'actual auth header' );
$rest->request( 'POST', '/channels/123/messages', json => { content => 'hello' } )->get;
T2->like( $requests[1], qr{^POST /api/v10/channels/123/messages HTTP/1\.1\r\n}, 'actual POST target' );
T2->like( $requests[1], qr/\r\n\r\n\{"content":"hello"\}\z/, 'actual POST body' );
$rest->close->get;
T2->ok( !grep( $_->isa('Net::Async::HTTP'), $loop->notifiers ), 'owned HTTP notifier removed on close' );

# An injected transport remains caller-owned even after timeout and SDK shutdown.
my $http = Net::Async::HTTP->new( fail_on_error => 0, pipeline => 0 );
$loop->add($http);
my $injected = Discord::Client::REST->new(
    token => 'FAKE_TEST_TOKEN',
    loop => $loop,
    http => $http,
    base_url => $base,
    timeout => 0.05
);
my $timeout = $injected->request( 'GET', '/silent' );
$loop->await($timeout);
my ( undef, $category ) = $timeout->failure;
T2->is( $category, 'timeout', 'real HTTP timeout classified' );
T2->is( scalar(@requests), 3, 'timeout not retried' );
$injected->close->get;
T2->ref_is( $http->loop, $loop, 'injected HTTP remains caller-owned' );
$loop->remove($http);

# Release caller-owned server connections as well as the listener.
for my $stream (@streams) {
    $stream->close;
    $loop->remove($stream) if $stream->loop;
}
$listener->close;
T2->done_testing;
