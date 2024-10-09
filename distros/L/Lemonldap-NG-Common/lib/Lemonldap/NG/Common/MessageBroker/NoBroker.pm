package Lemonldap::NG::Common::MessageBroker::NoBroker;

# This pseudo message broker only dispatch messages into current node.
# It also inserts periodically "newConf" into llng_events to permit- to
# detect configuration changes usng the checkTime parameter.

use strict;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.20.0';

our $lastCheck = time;

our $channels = {};

sub new {
    my ( $class, $conf, $logger ) = @_;
    $channels->{ $conf->{eventQueueName} } //= [];
    $channels->{ $conf->{statusQueueName} } = 'no';
    return bless {
        checkTime      => $conf->{checkTime},
        eventQueueName => $conf->{eventQueueName},
        logger         => $logger,
    }, $class;
}

sub publish {
    my ( $self, $channel, $msg ) = @_;
    die 'eventStatus not authorized without broker'
      if $channels->{$channel} eq 'no' and $ENV{FORCE_STATUS} ne 'force status';
    die unless $channel and $msg;
    $channels->{$channel} = []
      unless ref( $channels->{$channel} );
    push @{ $channels->{$channel} }, $msg;
}

sub subscribe { }

sub getNextMessage {
    my ( $self, $channel, $delay ) = @_;
    if ( time >= $lastCheck + $self->{checkTime} ) {
        $self->publish( $self->{eventQueueName}, { action => 'newConf' } );
        $lastCheck = time;
    }
    if ( ref( $channels->{$channel} )
        and @{ $channels->{$channel} } )
    {
        return shift @{ $channels->{$channel} };
    }
}

sub waitForNextMessage {
    my ( $self, $channel ) = @_;
    while (1) {
        if ( my $msg = $self->getNextMessage($channel) ) {
            return $msg;
        }
        sleep 1;
    }
}

1;
