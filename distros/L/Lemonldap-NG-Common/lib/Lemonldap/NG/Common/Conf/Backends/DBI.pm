package Lemonldap::NG::Common::Conf::Backends::DBI;

use strict;
use utf8;
use Lemonldap::NG::Common::Conf::Serializer;
use Lemonldap::NG::Common::Conf::Backends::_DBI;

our $VERSION = '2.0.0';
our @ISA     = qw(Lemonldap::NG::Common::Conf::Backends::_DBI);

sub store {
    my ( $self, $fields ) = @_;
    return DEPRECATED unless ( $self->{forceUpload} );
    $fields = $self->serialize($fields);
    my $tmp =
      $self->_dbh->do( "insert into "
          . $self->{dbiTable} . " ("
          . join( ",", keys(%$fields) )
          . ") values ("
          . join( ",", values(%$fields) )
          . ")" );
    unless ($tmp) {
        $self->logError;
        return UNKNOWN_ERROR;
    }
    eval { $self->dbh->do("COMMIT"); };
    return $fields->{cfgNum};
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    $fields = $fields ? join( ",", @$fields ) : '*';
    my $row = $self->_dbh->selectrow_hashref(
        "SELECT $fields from " . $self->{dbiTable} . " WHERE cfgNum=?",
        {}, $cfgNum );
    unless ($row) {
        $self->logError;
        return 0;
    }
    return $self->unserialize($row);
}

1;
__END__
