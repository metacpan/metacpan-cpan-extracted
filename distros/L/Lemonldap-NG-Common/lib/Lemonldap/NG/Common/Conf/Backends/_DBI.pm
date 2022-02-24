package Lemonldap::NG::Common::Conf::Backends::_DBI;

use strict;
use utf8;
use DBI;
use Lemonldap::NG::Common::Conf::Constants;    #inherits

our $VERSION = '2.0.12';
our @ISA     = qw(Lemonldap::NG::Common::Conf::Constants);
our ( @EXPORT, %EXPORT_TAGS );

BEGIN {
    *Lemonldap::NG::Common::Conf::_dbh = \&_dbh;
    push @EXPORT, @Lemonldap::NG::Common::Conf::Constants::EXPORT;
    %EXPORT_TAGS = %Lemonldap::NG::Common::Conf::Constants::EXPORT_TAGS;
    push @EXPORT,
      qw(prereq available lastCfg _dbh lock isLocked unlock delete logError);
}

sub prereq {
    my $self = shift;
    unless ( $self->{dbiChain} ) {
        $Lemonldap::NG::Common::Conf::msg =
          '"dbiChain" is required in *DBI configuration type';
        return 0;
    }
    $Lemonldap::NG::Common::Conf::msg .=
      'Warning: "dbiUser" parameter is not set'
      unless ( $self->{dbiUser} );
    $self->{dbiTable} ||= "lmConfig";
    1;
}

sub available {
    my $self = shift;
    my $sth =
      $self->_dbh->prepare( "SELECT DISTINCT cfgNum from "
          . $self->{dbiTable}
          . " order by cfgNum" )
      or $self->logError;
    $sth->execute() or $self->logError;
    my @conf;
    while ( my @row = $sth->fetchrow_array ) {
        push @conf, $row[0];
    }
    return @conf;
}

sub lastCfg {
    my $self = shift;
    my @row  = $self->_dbh->selectrow_array(
        "SELECT max(cfgNum) from " . $self->{dbiTable} );
    return $row[0];
}

sub _dbh {
    my $self = shift;
    $self->{dbiTable} ||= "lmConfig";
    return $self->{_dbh} if ( $self->{_dbh} and $self->{_dbh}->ping );
    $self->{_dbh} = DBI->connect_cached( $self->{dbiChain}, $self->{dbiUser},
        $self->{dbiPassword}, { RaiseError => 1, AutoCommit => 1, } );
    if ( $self->{dbiChain} =~ /^dbi:sqlite/i ) {
        $self->{_dbh}->{sqlite_unicode} = 1;
    }
    elsif ( $self->{dbiChain} =~ /^dbi:mysql/i ) {
        eval {
            $self->{_dbh}->{mysql_enable_utf8} = 1;
            $self->{_dbh}->do("set names 'utf8'");
        };
    }
    elsif ( $self->{dbiChain} =~ /^dbi:pg/i ) {
        $self->{_dbh}->{pg_enable_utf8} = 1;
    }

    # DBD::MariaDB should have o problem here
    return $self->{_dbh};
}

sub lock {
    my $self = shift;
    if ( $self->{dbiChain} =~ /^dbi:(?:MariaDB|mysql):/i ) {
        my @row = $self->_dbh->selectrow_array("SELECT GET_LOCK('lmconf', 0)");
        return $row[0] || 0;
    }
    return 1;
}

sub isLocked {
    my $self = shift;
    if ( $self->{dbiChain} =~ /^dbi:(?:MariaDB|mysql):/i ) {
        my @row = $self->_dbh->selectrow_array("SELECT IS_FREE_LOCK('lmconf')");
        return $row[0] ? 0 : 1;
    }
    return 0;
}

sub unlock {
    my $self = shift;
    if ( $self->{dbiChain} =~ /^dbi:(?:MariaDB|mysql):/i ) {
        my @row = $self->_dbh->selectrow_array("SELECT RELEASE_LOCK('lmconf')");
        return $row[0] || 0;
    }
    return 1;
}

sub delete {
    my ( $self, $cfgNum ) = @_;
    my $req =
         $self->_dbh->prepare("DELETE FROM $self->{dbiTable} WHERE cfgNum=?")
      or $self->logError;
    my $res = $req->execute($cfgNum) or $self->logError;
    $Lemonldap::NG::Common::Conf::msg .=
      "Unable to find conf $cfgNum (" . $self->_dbh->errstr . ")"
      unless ($res);
    return $res;
}

sub logError {
    my $self = shift;
    $Lemonldap::NG::Common::Conf::msg .=
      "Database error: " . $DBI::errstr . "\n";
}

1;
