## @file
# Demo userDB mechanism

## @class
# Demo userDB mechanism class
package Lemonldap::NG::Portal::UserDBDemo;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check AuthDemo use
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    if ( $self->get_module('auth') =~ /^Demo/ ) {

        # Call authInit if demo accounts not found
        $self->authInit() unless defined $self->{_demoAccounts};

        return PE_OK;
    }
    else {
        $self->lmLog( "Use UserDBDemo only with AuthDemo", 'error' );
        return PE_ERROR;
    }

    PE_OK;
}

## @apmethod int getUser()
# Check known accounts
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;

    # Search by login
    if ( $self->{user} ) {
        return PE_OK
          if ( defined $self->{_demoAccounts}->{ $self->{user} } );
    }

    # Search by mail
    if ( $self->{mail} ) {
        foreach my $user ( keys %{ $self->{_demoAccounts} } ) {
            if ( $self->{_demoAccounts}->{$user}->{mail} eq $self->{mail} ) {
                $self->{user} = $user;
                return PE_OK;
            }
        }
    }

    PE_USERNOTFOUND;
}

## @apmethod int setSessionInfo()
# Get sample data
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{demoExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        $self->{sessionInfo}->{$k} =
          $self->{_demoAccounts}->{ $self->{user} }->{$v}
          || "";
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

