package Finance::BitStamp::Socket;

use 5.014002;
use strict;
use warnings;
our $VERSION = '0.01';

use AnyEvent::Socket;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Frame;

use JSON;
use URI;
use Data::Dumper;

use constant VERBOSE => 1;
use constant DEBUG   => 0;

use constant CHANNELS => qw(
    order_book
    live_trades
);

use constant ATTRIBUTES => qw(protocol app_key channels ssl);
use constant PROTOCOL   => 6;
use constant APP_KEY    => 'de504dc5763aeef9ff52';

# TODO: test SSL. This didnt seem to work for me last time I set it... 
use constant SSL        => 0;

# cleartext...
use constant PORT       => 80;
use constant SCHEME     => 'ws';
use constant TLS        => undef;
use constant HOST       => 'ws.pusherapp.com';

# ssl...
use constant SSL_PORT   => 443;
use constant SSL_SCHEME => 'wws';
use constant SSL_TLS    => 'connect';
use constant SSL_HOST   => 'wws.pusherapp.com';

# THESE two methods: trade() and order_book() are the main methods you will want to move and rewrite into your own module.
# within these subroutines you will have access to the json response in a hash format.
sub trade { 
    my $self = shift;
    my $data = shift;
    warn Data::Dumper->Dump([$data]);
    warn "*** I am the default trade()... you should overwride this method in your own package\n";
}

sub order_book {
    my $self = shift;
    my $data = shift;
    warn Data::Dumper->Dump([$data]);
    warn "** I am the default order_book()... you should overwride this method in your own package\n";
}
# end the methods you should definately override.


# This module is meant to be used as a base for your own module.
# Your own module will decide what to do with the incoming message through the
# trade() and order_book() routines.
#
# You should look at "test.pl" to see a basic example.

sub new { (bless {} => shift)->init(@_) }

sub init {
    my $self = shift;
    my %args = @_;
    foreach my $attribute ($self->attributes) {
        $self->$attribute($args{$attribute}) if exists $args{$attribute};
    }
    return $self;
}

sub setup {
    my $self = shift;
    $self->channels([CHANNELS]) unless $self->channels;
    $self->protocol( PROTOCOL ) unless $self->protocol;
    $self->app_key ( APP_KEY  ) unless $self->app_key;
    $self->ssl     ( SSL      ) unless $self->ssl;
}

sub go {
    my $self = shift;
    $self->setup;
    $self->handle;
    $self->wait;
}

sub handle {
    my $self = shift;
    $self->client(Protocol::WebSocket::Handshake::Client->new(url => $self->uri->as_string));
    $self->frame(Protocol::WebSocket::Frame->new);
    $self->{handle} = AnyEvent::Handle->new(
        connect     => [$self->host, $self->port],
        tls         => $self->tls,
        tls_ctx     => {verify => 0},
        keepalive   => 1,
        wtimeout    => 50,
        on_connect  => $self->on_connect,
        on_read     => $self->on_read,
        on_wtimeout => $self->on_wtimeout,
        on_error    => $self->on_error,
        on_eof      => $self->on_eof,
    );
}

sub on_read {
    my $self = shift;
    return sub {
        my $handle = shift;
        my $chunk = $handle->{rbuf};
        $handle->{rbuf} = undef;
        if (!$self->client->is_done) {
            $self->client->parse($chunk);
        }

        $self->frame->append($chunk);
        if ($self->frame->is_ping()) {
            $handle->push_write(
                $self->frame->new(buffer => '', type => 'pong')->to_bytes
            );
        }
        while (my $msg = $self->frame->next) {
            my $d;
            eval {
                $d = $self->json->decode($msg);
            } or do {
                my $e = $@;
                warn $self->now . ' - error: ' . $e;
                next;
            };
            given ($d->{event}) {

                when ('pusher:connection_established') {
                    say $self->now . ' - subscribing to events' if VERBOSE;
                    foreach my $channel (@{$self->channels}) {
                        say $self->now . ' - requesting channel: ' . $channel if VERBOSE;
                        $handle->push_write(
                            $self->frame->new($self->json->encode({
                                event => 'pusher:subscribe',
                                data  => {
                                    channel => $channel,
                                },
                            }))->to_bytes
                        );
                    }
                }
                when ('pusher_internal:subscription_succeeded') {
                    printf("%s - subscribed to channel: %s\n", $self->now, $d->{channel}) if VERBOSE;
                }


                when ('trade') {
                    printf("%s - got %s request on channel: %s\n", $self->now, @{$d}{qw(event channel)}) if VERBOSE;
                    if ($d->{channel} eq 'live_trades') {
                        my $data = $self->json->decode($d->{data});
                        $self->trade($data);
                    }
                    else {
                        printf "%s - got event: %s", $self->now, Dumper $d if VERBOSE;
                    }
                }
                when ('data') {
                    printf("%s - got %s request on channel: %s\n", $self->now, @{$d}{qw(event channel)}) if VERBOSE;
                    if ($d->{channel} eq 'order_book') {
                        my $data = $self->json->decode($d->{data});
                        $self->order_book($data);
                    }
                    else {
                        printf '%s - got event: %s', $self->now, Dumper $d if VERBOSE;
                    }
                }

                default {
                    printf '%s - got event: %s', $self->now, Dumper $d if VERBOSE;
                }
            }
        }
    }
}

sub on_connect {
    my $self = shift;
    return sub {
        my $handle = shift;
        say $self->now . ' - connected to pusher' if VERBOSE;
        $handle->push_write($self->client->to_string);
    }
}

sub on_wtimeout {
    my $self = shift;
    return sub {
        my $handle = shift;
        $handle->push_write(
            $self->frame->new(buffer => '', type => 'ping')->to_bytes
        );
    }
}

sub on_error {
    my $self = shift;
    return sub {
        my ($handle, $fatal, $msg) = @_;
        warn $self->now . " - fatal($fatal): $msg" if VERBOSE or DEBUG;
        $handle->destroy;
        $self->setup;
    }
}

sub on_eof {
    my $self = shift;
    return sub {
        my $handle = shift;
        warn $self->now . " - lost connection, reconnecting" if VERBOSE or DEBUG;
        $self->setup;
    }
}

sub attributes { ATTRIBUTES }
sub wait       { AnyEvent->condvar->wait }
sub json       { shift->{json} ||= JSON->new }
sub host       { shift->ssl ? SSL_HOST   : HOST   }
sub port       { shift->ssl ? SSL_PORT   : PORT   }
sub tls        { shift->ssl ? SSL_TLS    : TLS    }
sub scheme     { shift->ssl ? SSL_SCHEME : SCHEME }
sub client     { my $self = shift; $self->get_set(@_) }
sub frame      { my $self = shift; $self->get_set(@_) }
sub channels   { my $self = shift; $self->get_set(@_) }
sub protocol   { my $self = shift; $self->get_set(@_) }
sub app_key    { my $self = shift; $self->get_set(@_) }
sub ssl        { my $self = shift; $self->get_set(@_) }
sub now        { sprintf '%4d-%02d-%02d %02d:%02d:%02d', (localtime(time))[5] + 1900, (localtime(time))[4,3,2,1,0] }

sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

sub uri {
    my $self = shift;
    unless ($self->{uri}) {
        my $uri = URI->new;
        $uri->scheme('http');
        $uri->host($self->host);
        $uri->path(sprintf '/app/%s' => $self->app_key);
        $uri->query_form(protocol => $self->protocol);
        $uri->scheme($self->scheme);
        $self->{uri} = $uri;
    }
    return $self->{uri};
}



1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

BitStamp::Socket - Perl extension for connecting to the BitStamp exchange
socket through the Pusher service.

=head1 SYNOPSIS

  # this will dump the socket messages to the terminal...

  use BitStamp::Socket;
  BitStamp::Socket->new->go;

  ... or just type this at the command prompt:

  $ perl -e 'use base qw(BitStamp::Socket); main->new->go'

  =======================
  But instead do this:
  =======================

  use base qw(BitStamp::Socket);
  main->new->go;
  
  sub order_book {
      my $self = shift;
      my $data = shift;
      # I just got new order book socket data
      # ... your code goes here ... #
  }

  sub trade {
      my $self = shift;
      my $data = shift;
      # I just got new trade socket data
      # ... your code goes here ... #
  }


=head1 DESCRIPTION

The BitStamp socket is the fastest any most bandwidth efficient way
to maintain your own up to date tracking of all trades and market
changes.

This module will save you some time since the connection and
communication negotiations are done for you. All you need to do
is write the code to handle the messages. For example: to store
into a database.


=head1 SEE ALSO

AnyEvent::Socket, AnyEvent::Handle

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

