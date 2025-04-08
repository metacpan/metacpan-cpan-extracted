package Lemonldap::NG::Common::MessageBroker::Pg;

use strict;
use JSON;
use POSIX qw(:signal_h);

our $VERSION = '2.21.0';

sub new {
    my ( $class, $conf, $logger ) = @_;
    require DBI;
    my $args = $conf->{messageBrokerOptions};
    unless ($args
        and $args->{dbiChain}
        and $args->{dbiUser}
        and $args->{dbiPassword} )
    {
        $logger->error('MISSING OPTIONS FOR PG PUB/SUB');
        return undef;
    }
    my $self = bless { %{$args}, logger => $logger }, $class;
    return $self;
}

sub publish {
    my ( $self, $channel, $msg ) = @_;
    die 'Not a hash msg' unless ref $msg eq 'HASH';
    my $j = eval { JSON::to_json($msg) };
    die "MessageBroker publish only hashes! $@" if $@;
    $self->_dbh->do( "NOTIFY $channel, ?", undef, $j );
}

sub subscribe {
    my ( $self, $channel ) = @_;
    $self->{messages}{$channel} = [];
    $self->_dbh->do("LISTEN $channel");
}

sub getNextMessage {
    my ( $self, $channel, $delay ) = @_;
    return undef
      unless $self->{messages}{$channel};
    if ( my $notify = $self->_dbh->pg_notifies ) {
        my ( $name, $pid, $payload ) = @$notify;
        $payload = eval { JSON::from_json($payload) };
        if ($@) {
            $self->{logger}->error("Bad message from Pg: $@");
        }
        else {
            push @{ $self->{messages}{$name} }, $payload;
        }
    }
    return shift( @{ $self->{messages}{$channel} } )
      if @{ $self->{messages}{$channel} };
}

sub waitForNextMessage {
    my ( $self, $channel ) = @_;
    return undef unless $self->{messages}{$channel};

    # Infinite loop until one message is seen
    my $res;
    while ( not( $res = $self->getNextMessage($channel) ) ) {
        sleep 1;
    }
}

sub _dbh {
    my ($self) = @_;
    return $self->{_dbh} if ( $self->{_dbh} and $self->{_dbh}->ping );
    $self->{_dbh} = undef;

    # This timeout is inspired from example given by DBI(3)
    my $mask = POSIX::SigSet->new(SIGALRM);
    my $action =
      POSIX::SigAction->new( sub { die "connect timeout\n" }, $mask );
    my $oldaction = POSIX::SigAction->new();
    sigaction( SIGALRM, $action, $oldaction );
    eval {
        eval {
            alarm(10);
            $self->{_dbh} =
              DBI->connect( $self->{dbiChain}, $self->{dbiUser},
                $self->{dbiPassword}, { RaiseError => 1, AutoCommit => 1, } );

            # Re subscribe to all channels when reconnecting
            $self->subscribe($_) foreach ( keys %{ $self->{messages} || {} } );
        };
        alarm(0);
    };
    return $self->{_dbh} ||= bless {}, 'Lemonldap::NG::DBI::Failed';
}

package Lemonldap::NG::DBI::Failed;

sub AUTOLOAD {
    print STDERR "MsgBroker: Unable to load DBI\n";
    return undef;
}

1;
