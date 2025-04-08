package Lemonldap::NG::Common::MessageBroker::Redis;

use strict;
use JSON;

our $VERSION = '2.21.0';
our $REDISCLASS = 'Redis::Fast';

sub new {
    my ( $class, $conf, $logger ) = @_;
    my $self = bless { logger => $logger }, $class;
    eval { require Redis::Fast };
    if ($@) {
        print STDERR "Redis::Fast not available, switching to Redis\n";
        $REDISCLASS = 'Redis';
        require Redis;
    }
    my $args = $conf->{messageBrokerOptions} // {};

    # Reconnection parameters
    #  - try to reconnect every 1s up to 3600s
    $args->{reconnect} //= 3600;
    $args->{every}     //= 1000000;
    $self->{redis}    = $REDISCLASS->new(%$args);
    $self->{messages} = {};
    return $self;
}

sub publish {
    my ( $self, $channel, $msg ) = @_;
    die 'Not a hash msg' unless ref $msg eq 'HASH';
    my $j = eval { JSON::to_json($msg) };
    die "MessageBroker publish only hashes! $@" if $@;
    $self->{redis}->publish( $channel, $j );
}

sub subscribe {
    my ( $self, $channel ) = @_;
    $self->{messages}{$channel} = [];
    $self->{redis}->subscribe(
        $channel,
        sub {
            my $tmp = eval { JSON::from_json( $_[0] ) };
            if ($@) {
                $self->{logger}->error("Bad message from Redis: $@");
            }
            else {
                push @{ $self->{messages}{$channel} }, $tmp;
            }
        }
    );
}

sub getNextMessage {
    my ( $self, $channel, $delay ) = @_;
    return undef
      unless $self->{messages}{$channel};
    return shift( @{ $self->{messages}{$channel} } )
      if @{ $self->{messages}{$channel} };
    $self->{redis}->wait_for_messages( $delay || 0.001 );
    return shift( @{ $self->{messages}{$channel} } )
      if @{ $self->{messages}{$channel} };
    return;
}

sub waitForNextMessage {
    my ( $self, $channel ) = @_;
    return undef
      unless $self->{messages}{$channel};

    # Infinite loop until one message is seen
    $self->{redis}->wait_for_messages(1)
      while ( !@{ $self->{messages}{$channel} } );
    return shift( @{ $self->{messages}{$channel} } );
}

1;
