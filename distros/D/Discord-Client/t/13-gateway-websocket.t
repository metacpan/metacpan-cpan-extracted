use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordLoop qw(await_future);
use TestDiscordTLS qw(certificate_directory);
use TestDiscordREST ();
use Future;
use Scalar::Util qw(weaken);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use IO::Async::Loop;
use IO::Async::Listener;
use IO::Async::SSL;
use JSON::PP;
use Net::Async::WebSocket::Server;
use Protocol::WebSocket::Frame;
use Discord::Client::REST;
use Discord::Client::Gateway;

# Create a temporary CA and matching loopback server certificate for real WSS verification.
my @timing_origin;
checkpoint('certificate generation begins');
my $dir = certificate_directory('127.0.0.1');
checkpoint('certificates generated');

# Script a local Gateway that accepts Identify and later Resume on a new connection.
my $loop = IO::Async::Loop->new;
my $clock = TestDiscordREST::Clock->new;
my $heartbeat_received = $loop->new_future;
my ( @clients, @handshakes, @payloads, @http_streams, @errors );
my $gateway_url;
my $server = Net::Async::WebSocket::Server->new(
    on_handshake => sub {
        checkpoint('server TLS and upgrade request received');
        push @handshakes, $_[2]->req->resource_name;
        $_[3]->(1);
    },
    on_client => sub {
        my ( undef, $client ) = @_;
        checkpoint('server WebSocket upgrade completed');
        push @clients, $client;
        $client->configure(
            on_text_frame => sub {
                my ( undef, $text ) = @_;
                my $packet = JSON::PP->new->decode($text);
                push @payloads, $packet;
                if ( $packet->{op} == 2 ) {
                    checkpoint('server Identify received');
                    $client->send_text_frame(
                        JSON::PP->new->encode(
                            {
                                op => 0,
                                s => 42,
                                t => 'READY',
                                d => {
                                    session_id => 'wire-session',
                                    resume_gateway_url => $gateway_url,
                                    user => { id => '123' }
                                }
                            }
                        )
                    );
                    checkpoint('server READY queued');

                    # Bypass the server helper frame cap to exercise the client's larger inbound allowance.
                    my $large =
                        JSON::PP->new->encode( { op => 0, s => 43, t => 'LARGE_EVENT', d => { text => 'x' x 70000 } } );
                    checkpoint('server 70KB JSON encoded');
                    my $frame = Protocol::WebSocket::Frame->new(
                        type => 'text',
                        buffer => $large,
                        max_payload_size => 100000
                    )->to_bytes;
                    if ( $ENV{DISCORD_CLIENT_TEST_TIMING} ) {
                        $client->write($frame)->on_done( sub { checkpoint('server 70KB frame flushed') } );
                    }
                    else {
                        $client->write($frame);
                    }
                    checkpoint('server 70KB frame queued');
                }
                elsif ( $packet->{op} == 6 ) {
                    $client->send_text_frame(
                        JSON::PP->new->encode( { op => 0, s => 44, t => 'RESUMED', d => {} } ) );
                }

                # Withhold ACKs only on the first connection to force a real transport reconnect.
                elsif ( $packet->{op} == 1 ) {
                    if ( @clients > 1 ) {
                        $client->send_text_frame('{"op":11}');
                    }
                    else {
                        $heartbeat_received->done unless $heartbeat_received->is_ready;
                    }
                }
            },
            on_close_frame => sub { $client->close }
        );
        $client->send_text_frame('{"op":10,"d":{"heartbeat_interval":80}}');
    },
);
$loop->add($server);
await_wire(
    $server->listen(
        addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
        extensions => ['SSL'],
        SSL_cert_file => "$dir/cert.pem",
        SSL_key_file => "$dir/key.pem"
    ),
    'WSS listener setup'
)->get;
$gateway_url = 'wss://127.0.0.1:' . $server->read_handle->sockport;

# Serve Gateway discovery locally and advertise the ephemeral WSS endpoint.
my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my ( undef, $stream ) = @_;
        push @http_streams, $stream;
        $stream->configure(
            on_read => sub {
                my ( $stream, $buffer ) = @_;
                return 0 unless $$buffer =~ /\r\n\r\n/;
                T2->like( $$buffer, qr{^GET /api/v10/gateway/bot HTTP/1\.1}, 'actual REST Gateway discovery' );
                $$buffer = '';
                my $body = JSON::PP->new->encode(
                    {
                        url => $gateway_url,
                        shards => 1,
                        session_start_limit => {
                            total => 10,
                            remaining => 10,
                            reset_after => 0,
                            max_concurrency => 1
                        }
                    }
                );
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
await_wire( $listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } ),
    'HTTP discovery listener setup' )->get;

# Use the production adapters against the test servers with explicit CA trust.
my $rest = Discord::Client::REST->new(
    token => 'FAKE_WIRE_TOKEN',
    loop => $loop,
    base_url => 'http://127.0.0.1:' . $listener->read_handle->sockport . '/api/v10'
);
my $gateway = Discord::Client::Gateway->new(
    token => 'FAKE_WIRE_TOKEN',
    loop => $loop,
    rest => $rest,
    websocket_options => { tls => { SSL_ca_file => "$dir/ca.pem" } },
    backoff_base => 0.05,
    backoff_max => 0.1,
    connect_timeout => 2,
    random => sub { 0.25 },
    clock => sub { $clock->{now} },
    delay => sub { $clock->delay( $_[0] ) },
    on_error => sub { push @errors, $_[0] }
);

# Bound the integration wait so handshake or heartbeat regressions cannot hang CI.
my $resumed = $loop->new_future;
my $large_received = $loop->new_future;
my $large;
$gateway->on( RESUMED => sub { $resumed->done unless $resumed->is_ready } );
$gateway->on(
    LARGE_EVENT => sub {
        checkpoint('client 70KB dispatch delivered');
        $large = length( $_[0]{text} );
        $large_received->done unless $large_received->is_ready;
    }
);
checkpoint('Gateway connect begins');
my $start = $gateway->connect;
$start->on_done( sub { checkpoint('client READY delivered') } ) if $ENV{DISCORD_CLIENT_TEST_TIMING};

# Receive the large dispatch before starting the missed-ACK scenario. Controlled
# protocol time cannot disconnect a slow peer halfway through the large frame.
await_wire( $large_received, 'large Gateway dispatch' );
$clock->advance(0.02);
await_wire( $heartbeat_received, 'heartbeat receipt' );
T2->ok( $heartbeat_received->is_done, 'the server receives the heartbeat whose ACK is withheld' );
$clock->advance(0.08);
$clock->advance(0.1);
await_wire( $resumed, 'Gateway Resume' );
T2->diag( join( '; ', map { $_->category . ': ' . $_->message } @errors ) ) unless $start->is_done;
T2->ok( $start->is_done, 'real WSS handshake and Identify reach READY' );
T2->ok( $resumed->is_done, 'missing ACK reconnects and resumes over real WSS' );
T2->is( $large, 70000, 'Gateway receives events larger than default WebSocket frame cap' );
T2->is( $handshakes[0], '/?v=10&encoding=json', 'pathless discovery URL uses root for the handshake' );
T2->is( $handshakes[1], '/?v=10&encoding=json', 'pathless resume URL uses root and protocol options' );

# Inspect actual decoded frames for authentication identity and resume sequence.
my ($identify) = grep { $_->{op} == 2 } @payloads;
my ($resume) = grep { $_->{op} == 6 } @payloads;
T2->is( $identify->{d}{token}, 'FAKE_WIRE_TOKEN', 'Identify sent through actual masked WebSocket frame' );
T2->is( $resume->{d}{session_id}, 'wire-session', 'actual Resume session' );
T2->is( $resume->{d}{seq}, 43, 'actual Resume dispatch sequence' );

# Close owned resources and verify no notifier or callback cycle keeps the driver alive.
await_wire( $gateway->close, 'Gateway shutdown' )->get;
T2->is( $gateway->state, 'closed', 'real transport closes cleanly' );
T2->ok( !grep( $_->isa('Net::Async::WebSocket::Client'), $loop->notifiers ), 'SDK WebSocket notifier removed' );
my $weak = $gateway;
weaken($weak);
undef $start;
undef $gateway;
T2->ok( !defined($weak), 'closed driver has no retained callback or completed Future cycle' );

# Release the separately owned REST client and all local server connections.
await_wire( $rest->close, 'REST shutdown' )->get;
$_->close for @clients, @http_streams;
$server->close;
$listener->close;
checkpoint('shutdown completed');
T2->done_testing;

sub checkpoint {
    my ($description) = @_;
    return unless $ENV{DISCORD_CLIENT_TEST_TIMING};

    # Report cumulative wall and process CPU time without including payloads or keys.
    my ( $user, $system ) = times;
    my $wall = clock_gettime(CLOCK_MONOTONIC);
    @timing_origin = ( $wall, $user, $system ) unless @timing_origin;
    T2->diag(
        sprintf 'Gateway timing: wall=%.6fs user=%.3fs sys=%.3fs %s',
        $wall - $timing_origin[0],
        $user - $timing_origin[1],
        $system - $timing_origin[2], $description
    );
}

sub await_wire {
    my ( $future, $description ) = @_;

    # Keep socket failures bounded independently of protocol time and wall-clock corrections.
    checkpoint("waiting for $description");
    my $ok = eval {
        await_future( $loop, $future, $description );
        1;
    };
    my $failure = $@;

    # Retain connection state when an integration wait fails.
    checkpoint( $ok ? "finished waiting for $description" : "failed waiting for $description" );
    if ( !$ok && $gateway ) {
        T2->diag( 'Gateway state: ' . $gateway->state . '; accepted WSS connections: ' . scalar(@clients) );
        T2->diag( join( '; ', map { $_->category . ': ' . $_->message } @errors ) ) if @errors;
    }
    die $failure unless $ok;
    return $future;
}
