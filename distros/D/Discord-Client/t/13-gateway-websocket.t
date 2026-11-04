use v5.26;
use warnings;
use Test2::V1;
use lib 't/lib';
use TestDiscordTLS qw(certificate_directory);
use Future;
use Scalar::Util qw(weaken);
use IO::Async::Loop;
use IO::Async::Listener;
use IO::Async::SSL;
use JSON::PP;
use Net::Async::WebSocket::Server;
use Protocol::WebSocket::Frame;
use Discord::Client::REST;
use Discord::Client::Gateway;

# Create a temporary CA and matching loopback server certificate for real WSS verification.
my $dir = certificate_directory('127.0.0.1');

# Script a local Gateway that accepts Identify and later Resume on a new connection.
my $loop = IO::Async::Loop->new;
my ( @clients, @handshakes, @payloads, @http_streams, @errors );
my $gateway_url;
my $server = Net::Async::WebSocket::Server->new(
    on_handshake => sub {
        push @handshakes, $_[2]->req->resource_name;
        $_[3]->(1);
    },
    on_client => sub {
        my ( undef, $client ) = @_;
        push @clients, $client;
        $client->configure(
            on_text_frame => sub {
                my ( undef, $text ) = @_;
                my $packet = JSON::PP->new->decode($text);
                push @payloads, $packet;
                if ( $packet->{op} == 2 ) {
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

                    # Bypass the server helper frame cap to exercise the client's larger inbound allowance.
                    my $large =
                        JSON::PP->new->encode( { op => 0, s => 43, t => 'LARGE_EVENT', d => { text => 'x' x 70000 } } );
                    $client->write(
                        Protocol::WebSocket::Frame->new(
                            type => 'text',
                            buffer => $large,
                            max_payload_size => 100000
                        )->to_bytes
                    );
                }
                elsif ( $packet->{op} == 6 ) {
                    $client->send_text_frame(
                        JSON::PP->new->encode( { op => 0, s => 44, t => 'RESUMED', d => {} } ) );
                }

                # Withhold ACKs only on the first connection to force a real transport reconnect.
                elsif ( $packet->{op} == 1 && @clients > 1 ) {
                    $client->send_text_frame('{"op":11}');
                }
            },
            on_close_frame => sub { $client->close }
        );
        $client->send_text_frame('{"op":10,"d":{"heartbeat_interval":80}}');
    },
);
$loop->add($server);
$server->listen(
    addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
    extensions => ['SSL'],
    SSL_cert_file => "$dir/cert.pem",
    SSL_key_file => "$dir/key.pem"
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
$listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;

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
    on_error => sub { push @errors, $_[0] }
);

# Bound the integration wait so handshake or heartbeat regressions cannot hang CI.
my $resumed = $loop->new_future;
my $large;
$gateway->on( RESUMED => sub { $resumed->done unless $resumed->is_ready } );
$gateway->on( LARGE_EVENT => sub { $large = length( $_[0]{text} ) } );
my $start = $gateway->connect;
my $wait = Future->wait_any( $resumed, $loop->timeout_future( after => 5 ) );
$loop->await($wait);
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
$gateway->close->get;
T2->is( $gateway->state, 'closed', 'real transport closes cleanly' );
T2->ok( !grep( $_->isa('Net::Async::WebSocket::Client'), $loop->notifiers ), 'SDK WebSocket notifier removed' );
my $weak = $gateway;
weaken($weak);
undef $start;
undef $gateway;
T2->ok( !defined($weak), 'closed driver has no retained callback or completed Future cycle' );

# Release the separately owned REST client and all local server connections.
$rest->close->get;
$_->close for @clients, @http_streams;
$server->close;
$listener->close;
T2->done_testing;
