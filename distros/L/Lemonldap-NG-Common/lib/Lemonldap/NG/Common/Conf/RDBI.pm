package Lemonldap::NG::Common::Conf::RDBI;

use strict;
use utf8;
use Lemonldap::NG::Common::Conf::Serializer;
use Lemonldap::NG::Common::Conf::_DBI;

our $VERSION = '1.9.1';
our @ISA     = qw(Lemonldap::NG::Common::Conf::_DBI);

sub store {
    my ( $self, $fields ) = @_;
    my $cfgNum = $fields->{cfgNum};
    $self->{noQuotes} = 1;
    $fields = $self->serialize($fields);

    my $req;
    my $lastCfg = $self->lastCfg;

    $self->_dbh->begin_work;
    eval { $self->_dbh->do("BEGIN") };
    if ( $lastCfg == $cfgNum ) {
        $req = $self->_dbh->prepare(
"UPDATE $self->{dbiTable} SET field=?, value=? WHERE cfgNum=? AND field=?"
        );

    }
    else {
        $req = $self->_dbh->prepare(
            "INSERT INTO $self->{dbiTable} (cfgNum,field,value) VALUES (?,?,?)"
        );
    }
    unless ($req) {
        $self->logError;
        return UNKNOWN_ERROR;
    }
    while ( my ( $k, $v ) = each %$fields ) {
        my @execValues;
        if ( $lastCfg == $cfgNum ) {
            @execValues = ( $k, $v, $cfgNum, $k );
        }
        else { @execValues = ( $cfgNum, $k, $v ); }
        unless ( $req->execute(@execValues) ) {
            $self->logError;
            $self->_dbh->do("ROLLBACK");
            return UNKNOWN_ERROR;
        }
    }
    eval { $self->_dbh->do("COMMIT") };
    return $cfgNum;
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    $fields = $fields ? join( ",", @$fields ) : '*';
    my $sth =
      $self->_dbh->prepare( "SELECT cfgNum,field,value from "
          . $self->{dbiTable}
          . " WHERE cfgNum=?" );
    $sth->execute($cfgNum);
    my ( $res, @row );
    while ( @row = $sth->fetchrow_array ) {
        $res->{ $row[1] } = $row[2];
    }
    unless ($res) {
        $Lemonldap::NG::Common::Conf::msg .=
          "No configuration $cfgNum found \n";
        return 0;
    }
    $res->{cfgNum} = $cfgNum;
    return $self->unserialize($res);
}

1;
__END__
