package Lemonldap::NG::Common::Conf::Backends::MongoDB;

use 5.010;
use utf8;
use strict;
use Lemonldap::NG::Common::Conf::Serializer;

our $VERSION = '2.0.1';
our $initDone;

sub prereq {
    my $self = shift;
    unless ($initDone) {
        eval "use MongoDB";
        if ($@) {
            $Lemonldap::NG::Common::Conf::msg .= "Unable to load MongoDB: $@\n";
            return 0;
        }
        $self->{dbName}         ||= 'llConfDB';
        $self->{collectionName} ||= 'configuration';
        $initDone++;
    }
    1;
}

sub Lemonldap::NG::Common::Conf::_mongoDB {
    my $self = shift;
    return $self->{_mongoDB} if ( $self->{_mongoDB} );
    my $conn_args = {};
    foreach my $w (
        qw(host auth_mechanism auth_mechanism_properties bson_codec connect_timeout_ms db_name heartbeat_frequency_ms j local_threshold_ms max_time_ms password port read_pref_mode read_pref_tag_sets replica_set_name server_selection_timeout_ms server_selection_try_once socket_check_interval_ms socket_timeout_ms ssl username w wtimeout read_concern_level)
      )
    {
        $conn_args->{$w} = $self->{$w} if ( defined $self->{$w} );
    }
    return $self->{_mongoDB} =
      MongoDB::MongoClient->new($conn_args)->get_database( $self->{dbName} );
}

sub Lemonldap::NG::Common::Conf::_mongoColl {
    my $self = shift;
    return $self->{_coll} if ( $self->{_coll} );
    return $self->{_coll} =
      $self->_mongoDB->get_collection( $self->{collectionName} );
}

sub Lemonldap::NG::Common::Conf::run_command {
    my $self = shift;
    $self->_mongoDB->run_command(@_);
}

sub available {
    my $self = shift;
    my $c    = $self->_mongoColl or return 0;
    my $res  = $self->run_command(
        [ distinct => $self->{collectionName}, key => '_id' ] );
    unless ( ref($res) ) {
        $Lemonldap::NG::Common::Conf::msg .= $res;
        return ();
    }
    return sort { $a <=> $b } @{ $res->{values} } if ( $res->{ok} );
    return ();
}

sub lastCfg {
    my $self  = shift;
    my @avail = $self->available;
    return $avail[$#avail];
}
sub lock     { 1 }
sub isLocked { 0 }
sub unlock   { 1 }

sub store {
    my ( $self, $fields ) = @_;
    $fields = $self->serialize($fields);
    $fields->{_id} = $fields->{cfgNum};
    my $res = eval { $self->_mongoColl->insert_one($fields) };
    if ($@) {
        $Lemonldap::NG::Common::Conf::msg .= "Unable to store conf: $@\n";
        return 0;
    }
    return $fields->{cfgNum};
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    my $res =
      $self->unserialize( $self->_mongoColl->find_one( { _id => $cfgNum } ) );
    return $res;
}

sub delete {
    my ( $self, $cfgNum ) = @_;
    die "cfgNum required" unless ($cfgNum);
    $self->_mongoColl->remove( { _id => $cfgNum } );
}

1;
