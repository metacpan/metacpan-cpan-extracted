package Lemonldap::NG::Common::MessageBroker::Web;

use strict;
use IO::Socket::INET;
use IO::Socket::SSL;
use IO::Select;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::UserAgent;
use JSON;
use Protocol::WebSocket::Client;

our $VERSION = '2.22.0';

use constant DEFAULTWS => 'localhost:8080';
our $pr = '::MessageBroker::Web:';

sub new {
    my ( $class, $conf, $logger ) = @_;
    my $args = $conf->{messageBrokerOptions} // {};
    my $ssl  = '';
    unless ( $args->{server} ) {
        $args->{server} = DEFAULTWS;
        $logger->info("$pr no server given");
    }
    elsif ( $args->{server} =~ m#^(?:(?:http|ws)(s)?://)?(.+?)/*$# ) {
        $args->{server} = $2;
        $ssl = 's' if $1;
    }
    else {
        $logger->error("$pr unparsable server '$args->{server}'");
        $args->{server} = DEFAULTWS;
    }
    $logger->debug("$pr using server $args->{server}");
    my $self = bless {
        logger   => $logger,
        server   => $args->{server},
        messages => {},
        ssl      => $ssl,
        token    => $args->{token},
        ua       => $args->{ua} || Lemonldap::NG::Common::UserAgent->new($conf),
    }, $class;
    $self->{ua}->env_proxy();
    return $self;
}

sub publish {
    my ( $self, $channel, $msg ) = @_;
    die 'Not a hash msg' unless ref $msg eq 'HASH';
    $msg->{channel} = $channel;
    my $j = eval { JSON::to_json($msg) };
    if ($@) {
        $self->logger->error("$pr message error: $@");
        return;
    }
    my $req = HTTP::Request->new(
        POST => "http$self->{ssl}://$self->{server}/publish",
        [
            'Content-Length' => length($j),
            (
                $self->{token}
                ? ( Authorization => "Bearer $self->{token}" )
                : ()
            )
        ],
        $j
    );
    my $resp = $self->ua->request($req);
    $resp->is_success
      ? ( $self->logger->debug("$pr publish $msg->{action}") )
      : ( $self->logger->error( "$pr publish error: " . $resp->status_line ) );
}

sub subscribe {
    my ( $self, $channel ) = @_;
    return
      if $self->{channels}
      and $self->{channels} =~ /^(?:.*,)?$channel(?:,.*)?$/;
    $self->{channels} =
      $self->{channels} ? "$self->{channels},$channel" : $channel;
    $self->{messages}{$channel} = [];
    $self->logger->debug("$pr subscribe to $self->{channels}");
    my $sock = $self->_connect;
}

sub getNextMessage {
    my ( $self, $channel ) = @_;
    return undef
      unless $self->{ws} and defined $self->{messages}{$channel};
    return shift( @{ $self->{messages}{$channel} } )
      if @{ $self->{messages}{$channel} };
    $self->_read_socket;
    return shift( @{ $self->{messages}{$channel} } )
      if @{ $self->{messages}{$channel} };
}

sub waitForNextMessage {
    my ( $self, $channel ) = @_;
    return undef
      unless $self->{messages}{$channel};
    my $res;
    do {
        $res = $self->getNextMessage($channel);
        sleep 1 unless $res;
    } while ( !$res );
    return $res;
}

sub _connect {
    my ($self) = @_;
    my ( $host, $port ) = split /:/, $self->{server}, 2;

    # If port is not defined, use 80 or 443
    $port =
      ( $port && $port =~ /^(\d+)/ ) ? $1 : $self->{ssl} eq 's' ? 443 : 80;
    $host =~ s|/.*$||;
    my $sock = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
      )
      or do {
        $self->logger->error("$pr Failed to connect to $self->{server}: $!");
        $self->{connected} = 0;
        return;
      };
    $self->logger->debug("$pr connected");

    if ( $self->{ssl} ) {
        $sock = IO::Socket::SSL->start_SSL( $sock, SSL_verify_mode => 0 )
          or do {
            $self->logger->error("$pr SSL error: $!");
            $self->{connected} = 0;
            return;
          };
        $self->logger->debug("$pr connection upgraded to TLS");
    }
    my $url = "ws$self->{ssl}://$self->{server}/subscribe?"
      . build_urlencoded( channels => $self->{channels} );
    $self->logger->debug("$pr connects to $url");
    my $client = Protocol::WebSocket::Client->new( url => $url );

    $client->on(
        read => sub {
            my ( $c, $buf ) = @_;
            if ( $buf =~ /^{.*}$/ ) {
                eval {
                    my $data = JSON::decode_json($buf);
                    if ( $data->{channel}
                        && defined $self->{messages}->{ $data->{channel} } )
                    {
                        push @{ $self->{messages}->{ $data->{channel} } },
                          $data;
                    }
                    else {
                        $self->logger->info(
                            "$pr received a message for an unknown channel");
                    }
                };
                $self->logger->error("$pr unable to read websocket: $@")
                  if ($@);
            }
            else {
                $self->logger->warn("$pr received an unreadable message: $buf");
            }
        }
    );

    $client->on(
        write => sub {
            my ( $c, $buf ) = @_;
            print $sock $buf;
        }
    );

    $client->on(
        error => sub {
            $self->logger->error("$pr websocket error: $_[1]");
        }
    );

    $client->{hs}->{req}->{headers} =
      [ Authorization => "Bearer $self->{token}", ]
      if $self->{token};

    $client->connect();

    my $buf;
    $sock->sysread( $buf, 4096 );
    $client->read($buf);

    $self->{socket}    = $sock;
    $self->{selector}  = IO::Select->new($sock);
    $self->{ws}        = $client;
    $self->{connected} = 1;
}

sub _read_socket {
    my ($self) = @_;
    return unless $self->{connected};
    return unless $self->{selector}->can_read(0.01);
    my $sock = $self->{socket};
    my $buf;
    my $n = sysread( $sock, $buf, 4096 );

    if ( !defined $n || $n == 0 ) {
        warn "Connection lost, trying to reconnect...\n";
        $self->{connected} = 0;
        $self->_connect;
        return;
    }

    $self->{ws}->read($buf);
}

# Accessors
sub logger {
    return $_[0]->{logger};
}

sub ua {
    return $_[0]->{ua};
}

1;
