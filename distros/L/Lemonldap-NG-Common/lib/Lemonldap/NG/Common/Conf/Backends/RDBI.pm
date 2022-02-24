package Lemonldap::NG::Common::Conf::Backends::RDBI;

use strict;
use utf8;
use Lemonldap::NG::Common::Conf::Serializer;
use Lemonldap::NG::Common::Conf::Backends::_DBI;

our $VERSION = '2.0.12';
our @ISA     = qw(Lemonldap::NG::Common::Conf::Backends::_DBI);

sub store {
    my ( $self, $fields ) = @_;
    my $cfgNum = $fields->{cfgNum};
    $self->{noQuotes} = 1;
    $fields = $self->serialize($fields);

    my $req;
    my $lastCfg = $self->lastCfg;
    $req = $self->_dbh->prepare(
        "INSERT INTO $self->{dbiTable} (cfgNum,field,value) VALUES (?,?,?)");

    _delete( $self, $cfgNum ) if $lastCfg == $cfgNum;
    unless ($req) {
        $self->logError;
        return UNKNOWN_ERROR;
    }
    while ( my ( $k, $v ) = each %$fields ) {
        my @execValues = ( $cfgNum, $k, $v );
        my $execute;
        eval { $execute = $req->execute(@execValues); };
        print STDERR $@ if $@;
        unless ($execute) {
            $self->logError;
            _delete( $self, $cfgNum ) if $lastCfg != $cfgNum;
            $self->_dbh->do("ROLLBACK");
            return UNKNOWN_ERROR;
        }
    }
    return $cfgNum;
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    $fields = $fields ? join( ",", @$fields ) : '*';
    my $sth =
      $self->_dbh->prepare(
        "SELECT field,value from " . $self->{dbiTable} . " WHERE cfgNum=?" )
      or $self->logError;
    $sth->execute($cfgNum) or $self->logError;
    my ( $res, @row );
    while ( @row = $sth->fetchrow_array ) {
        $res->{ $row[0] } = $row[1];
    }
    unless ($res) {
        $Lemonldap::NG::Common::Conf::msg .=
          "No configuration $cfgNum found \n";
        return 0;
    }
    $res->{cfgNum} = $cfgNum;
    return $self->unserialize($res);
}

sub _delete {
    my ( $self, $cfgNum ) = @_;
    my $r =
      $self->_dbh->prepare("DELETE FROM $self->{dbiTable} where cfgNum=?");
    $r->execute($cfgNum);
}

1;
