package Lemonldap::NG::Common::Conf::Backends::_DBI;

use strict;
no strict 'refs';
use utf8;
use DBI;
use Lemonldap::NG::Common::Conf::Constants;

our $VERSION = '2.22.0';
our @ISA     = qw(Lemonldap::NG::Common::Conf::Constants);
our ( @EXPORT, %EXPORT_TAGS );

BEGIN {
    *Lemonldap::NG::Common::Conf::_dbh     = \&_dbh;
    *Lemonldap::NG::Common::Conf::_execute = \&_execute;
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
      $self->_execute( "SELECT DISTINCT cfgNum from "
          . $self->{dbiTable}
          . " order by cfgNum" );
    my @conf;
    while ( my @row = $sth->fetchrow_array ) {
        push @conf, $row[0];
    }
    return @conf;
}

sub lastCfg {
    my $self = shift;
    my $sth = $self->_execute( "SELECT max(cfgNum) from " . $self->{dbiTable} );
    my @row = $sth->fetchrow_array();
    return $row[0];
}

sub _dbh {
    my $self = shift;
    $self->{dbiTable} ||= "lmConfig";
    return $self->{_dbh} if ( $self->{_dbh} and $self->{_dbh}->ping );
    eval {
        $self->{_dbh} =
          DBI->connect_cached( $self->{dbiChain}, $self->{dbiUser},
            $self->{dbiPassword}, { RaiseError => 1, AutoCommit => 1, } );
    };
    if ( $@ and &{ $self->{type} . "::beforeRetry" }($self) ) {
        eval {
            $self->{_dbh} =
              DBI->connect_cached( $self->{dbiChain}, $self->{dbiUser},
                $self->{dbiPassword}, { RaiseError => 1, AutoCommit => 1, } );
        };
    }
    if ($@) {
        die $@;
    }
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
    return 1;
}

sub isLocked {
    my $self = shift;
    return 0;
}

sub unlock {
    my $self = shift;
    return 1;
}

sub delete {
    my ( $self, $cfgNum ) = @_;
    my $res = $self->_execute( "DELETE FROM $self->{dbiTable} WHERE cfgNum=?",
        $cfgNum );
    return ( $res > 0 );
}

sub logError {
    my $self = shift;
    $Lemonldap::NG::Common::Conf::msg .=
      "Database error: " . $DBI::errstr . "\n";
}

sub _execute {
    my ( $self, $query, @prms ) = @_;
    my $req = $self->_dbh->prepare($query);
    unless ($req) {
        $self->logError;
        return UNKNOWN_ERROR;
    }
    my $execute = eval { $req->execute(@prms) };
    if ( !$execute and &{ $self->{type} . "::beforeRetry" }($self) ) {
        $req     = $self->_dbh->prepare($query);
        $execute = eval { $req->execute(@prms) };
    }
    unless ($execute) {
        $self->logError;
        return UNKNOWN_ERROR;
    }
    return ( 1, $req );
}

sub beforeRetry {
    return !$_[0]->{noRetry};
}

1;
