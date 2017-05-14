## @file
# DBI userDB mechanism

## @class
# DBI userDB mechanism class
package Lemonldap::NG::Portal::UserDBDBI;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_DBI;    #inherits

our $VERSION = '1.9.3';

## @apmethod int userDBInit()
# Set default values
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    # DBI access to user is the same as authentication by default
    $self->{dbiUserChain}    ||= $self->{dbiAuthChain};
    $self->{dbiUserUser}     ||= $self->{dbiAuthUser};
    $self->{dbiUserPassword} ||= $self->{dbiAuthPassword};
    $self->{dbiUserTable}    ||= $self->{dbiAuthTable};
    $self->{userPivot}       ||= $self->{dbiAuthLoginCol};

    PE_OK;
}

## @apmethod int getUser()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiUserChain}, $self->{dbiUserUser},
        $self->{dbiUserPassword} );
    return PE_ERROR unless $dbh;

    my $table = $self->{dbiUserTable};
    my $pivot = $self->{userPivot};
    my $user  = $self->{user};

    # If in mailProcess, adapt search criteriums
    if ( $self->{mail} ) {
        $pivot = $self->{dbiPasswordMailCol};
        $user  = $self->{mail};
    }

    $user =~ s/'/''/g;
    my $sth;

    eval {
        $sth = $dbh->prepare("SELECT * FROM $table WHERE $pivot=?");
        $sth->execute($user);
    };
    if ($@) {
        $self->lmLog( "DBI error: $@", 'error' );
        return PE_ERROR;
    }

    unless ( $self->{entry} = $sth->fetchrow_hashref() ) {
        $self->_sub( 'userNotice', "User $user not found" );
        return PE_BADCREDENTIALS;
    }

    # In mail process, get user value
    if ( $self->{mail} ) {
        $table = $self->{dbiAuthTable};
        $pivot = $self->{dbiAuthLoginCol};
        $user  = $self->{entry}->{ $self->{userPivot} };
        eval {
            $sth = $dbh->prepare("SELECT * FROM $table WHERE $pivot=?");
            $sth->execute($user);
        };
        if ($@) {
            $self->lmLog( "DBI error: $@", 'error' );
            return PE_ERROR;
        }

        my $results;

        unless ( $results = $sth->fetchrow_hashref() ) {
            $self->_sub( 'userNotice', "User $user not found" );
            return PE_BADCREDENTIALS;
        }

        $self->{user} = $results->{$pivot};
    }

    PE_OK;
}

## @apmethod int setSessionInfo()
# Get columns for each exportedVars
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    # Set _user unless already defined
    $self->{sessionInfo}->{_user} ||= $self->{user};

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{dbiExportedVars} } );
    while ( my ( $var, $attr ) = each %vars ) {
        $self->{sessionInfo}->{$var} = $self->{entry}->{$attr}
          if ( defined $self->{entry}->{$attr} );
    }

    PE_OK;
}

## @apmethod int setGroups()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    PE_OK;
}

1;

