use v5.26;
use warnings;
use Test2::V1;
use Future;
use IO::Async::Loop;
use IO::Async::Listener;
use Net::Async::HTTP;
use Discord::Client::REST;

# Control the adapter's deadline without replacing its HTTP transport or socket I/O.
{

    package Local::HTTPTestLoop;
    use parent 'IO::Async::Loop::Select';
    our $deadline;

    sub timeout_future {
        return $deadline if $deadline;
        return shift->SUPER::timeout_future(@_);
    }
}

# Serve HTTP only on an ephemeral loopback port; no Discord connection is involved.
my $loop = Local::HTTPTestLoop->new;
my $silent_received = $loop->new_future;
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
                if ( $request =~ m{^GET /api/v10/silent } ) {
                    $silent_received->done unless $silent_received->is_ready;
                    return 0;
                }
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
await_http( $listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } ),
    'HTTP listener setup' )->get;

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
    await_http( $rest->request( 'GET', '/users/@me', query => { limit => 1 } ), 'GET response' )->get,
    { id => '18446744073709551615' },
    'real HTTP transport decodes response'
);
T2->like( $requests[0], qr{^GET /api/v10/users/\@me\?limit=1 HTTP/1\.1\r\n}, 'actual request target' );
T2->like( $requests[0], qr/^Authorization: Bot FAKE_TEST_TOKEN\r$/m, 'actual auth header' );
await_http( $rest->request( 'POST', '/channels/123/messages', json => { content => 'hello' } ), 'POST response' )->get;
T2->like( $requests[1], qr{^POST /api/v10/channels/123/messages HTTP/1\.1\r\n}, 'actual POST target' );
T2->like( $requests[1], qr/\r\n\r\n\{"content":"hello"\}\z/, 'actual POST body' );
await_http( $rest->close, 'owned REST shutdown' )->get;
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
my $deadline = $loop->new_future;
my $timeout;
{
    local $Local::HTTPTestLoop::deadline = $deadline;
    $timeout = $injected->request( 'GET', '/silent' );
}

# Expire the adapter timeout only after the server has received the complete request.
await_http( $silent_received, 'silent request receipt' );
T2->ok( $silent_received->is_done, 'silent request reaches the server before timeout' );
$deadline->fail('Timeout');
await_http( $timeout, 'HTTP timeout propagation' );
my ( undef, $category ) = $timeout->failure;
T2->is( $category, 'timeout', 'real HTTP timeout classified' );
T2->is( scalar(@requests), 3, 'timeout not retried' );
await_http( $injected->close, 'injected REST shutdown' )->get;
T2->ref_is( $http->loop, $loop, 'injected HTTP remains caller-owned' );
$loop->remove($http);

# Release caller-owned server connections as well as the listener.
for my $stream (@streams) {
    $stream->close;
    $loop->remove($stream) if $stream->loop;
}
$listener->close;
T2->done_testing;

sub await_http {
    my ( $future, $description ) = @_;

    # Bound broken I/O and shutdown independently of the controlled adapter deadline.
    my $watchdog = $loop->timeout_future( after => 5 );
    $loop->await( Future->wait_any( $future, $watchdog ) );
    $watchdog->cancel unless $watchdog->is_ready;

    # wait_any cancels the losing Future, so its readiness alone cannot prove completion.
    die "Timed out waiting for $description\n" if $watchdog->is_failed;
    return $future;
}
