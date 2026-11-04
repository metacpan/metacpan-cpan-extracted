package TestDiscordGateway;

use v5.26;
use warnings;
use Exporter 'import';
use Future;
use IO::Async::Loop;
use JSON::PP;
use Scalar::Util ();
use TestDiscordREST ();
use Discord::Client::Gateway;

our @EXPORT_OK = qw(rig gateway_info ready_socket);

sub gateway_info {
    my (%limit) = @_;
    return {
        url => 'wss://gateway.test/',
        shards => 2,
        session_start_limit => {
            total => 10,
            remaining => 10,
            reset_after => 10000,
            max_concurrency => 1,
            %limit
        }
    };
}

sub rig {
    my (%args) = @_;

    # Use one controlled clock for protocol timers and deferred application delivery.
    my $clock = bless { now => 0, timers => [], deferred => [] }, 'TestDiscordGateway::Clock';
    my $rest = $args{rest} // bless { calls => [], responses => [ $args{info} // gateway_info() ] },
        'TestDiscordGateway::REST';
    my $rig = { clock => $clock, rest => $rest, sockets => [], errors => [], diagnostics => [] };
    $rig->{gateway} = Discord::Client::Gateway->new(
        token => 'FAKE_GATEWAY_TOKEN',
        loop => IO::Async::Loop->new,
        intents => ['GUILDS'],
        rest => $rest,
        clock => sub { $clock->{now} },
        delay => sub { $clock->delay( $_[0] ) },
        defer => sub { push @{ $clock->{deferred} }, $_[0] },
        random => sub { 0.25 },
        websocket_factory => sub {
            my $websocket = bless { options => {@_}, frames => [], writes => [], active => 0 },
                'TestDiscordGateway::WebSocket';
            push @{ $rig->{sockets} }, $websocket;
            return $websocket;
        },
        on_error => sub { push @{ $rig->{errors} }, $_[0] },
        on_diagnostic => sub { push @{ $rig->{diagnostics} }, $_[0] },
        %args,
    );
    return $rig;
}

sub ready_socket {
    my ( $rig, %args ) = @_;
    my $websocket = $rig->{sockets}[-1];

    # Complete the handshake through received frames rather than changing session internals.
    $websocket->open;
    $websocket->emit( { op => 10, d => { heartbeat_interval => $args{interval} // 1000 } } );
    $websocket->emit(
        {
            op => 0,
            s => 42,
            t => 'READY',
            d => {
                session_id => 'session-test',
                resume_gateway_url => 'wss://resume.test/',
                user => { id => '123', bot => JSON::PP::true }
            }
        }
    );
    return $websocket;
}

package TestDiscordGateway::Clock;
our @ISA = ('TestDiscordREST::Clock');

sub run_deferred {
    my ($self) = @_;

    # Drain callbacks added by earlier callbacks, but fail instead of looping forever.
    my $count = 0;
    while ( @{ $self->{deferred} } ) {
        die 'Deferred callback loop' if ++$count > 10000;
        shift( @{ $self->{deferred} } )->();
    }
}

package TestDiscordGateway::REST;

sub request {
    my ( $self, $method, $path ) = @_;
    push @{ $self->{calls} }, [ $method, $path ];
    my $response = shift @{ $self->{responses} };

    # Permit a pending discovery Future as well as immediate metadata responses.
    return $response if Scalar::Util::blessed($response) && $response->isa('Future');
    return Future->done( $response // TestDiscordGateway::gateway_info() );
}

package TestDiscordGateway::WebSocket;

sub connect {
    my ( $self, $url ) = @_;

    # Keep the handshake pending until the test opens or fails this socket.
    $self->{url} = $url;
    return $self->{connect} = Future->new;
}
sub open { $_[0]->{connect}->done( $_[0] ) }
sub emit { $_[0]->text( JSON::PP->new->encode( $_[1] ) ) }
sub text { $_[0]->{options}{on_text}->( $_[1] ) }
sub remote_close { $_[0]->{options}{on_close}->( $_[1] ) }

sub send {
    my ( $self, $text ) = @_;
    push @{ $self->{frames} }, JSON::PP->new->decode($text);

    # Track concurrent writes and optionally hold them pending to simulate backpressure.
    my $future = Future->new;
    push @{ $self->{writes} }, $future;
    ++$self->{active};
    $self->{max_active} = $self->{active} if $self->{active} > ( $self->{max_active} // 0 );
    $future->on_ready( sub { --$self->{active} } );
    $future->done unless $self->{block_writes};
    $self->{on_send}->( $self->{frames}[-1] ) if $self->{on_send};
    return $future;
}

sub abort {
    $_[0]->{aborted}++;
    return Future->done;
}

sub close {
    my ( $self, $code ) = @_;

    # Most scenarios close immediately; lifecycle tests can hold the handshake pending.
    $self->{close_code} = $code;
    return $self->{close_future} // Future->done;
}

1;
