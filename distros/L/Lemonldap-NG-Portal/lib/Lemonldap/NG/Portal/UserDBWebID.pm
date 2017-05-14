## @file
# UserDB WebID module

## @class
# UserDB WebID module
package Lemonldap::NG::Portal::UserDBWebID;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check if authentication module is WebID
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;

    unless ( $self->get_module('auth') =~ /^WebID/ ) {
        $self->lmLog(
'UserDBWebID isn\'t useable unless authentication module is set to WebID',
            'error'
        );
        return PE_ERROR;
    }
    PE_OK;
}

## @apmethod int getUser()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub getUser {
    PE_OK;
}

## @apmethod int setSessionInfo()
# Get attributes from FOAF
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    my $self = shift;

    unless ( $self->{_webid} ) {
        $self->lmLog( 'No webid object found', 'error' );
        return PE_ERROR;
    }

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{webIDExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr = $k;
        my $req;
        $attr =~ s/^!// and $req = 1;
        eval { $self->{sessionInfo}->{$attr} = $self->{_webid}->get($v) };
        $self->lmLog( "Unable to get $v from FOAF document: $@", 'error' )
          if ($@);
        if ( $req and not $self->{sessionInfo}->{$attr} ) {
            $self->_sub( 'userNotice',
                "Required attribute $v is missing (user: $self->{user})" );
            return PE_MISSINGREQATTR;
        }
    }
    PE_OK;
}

## @apmethod int setGroups()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub setGroups {
    PE_OK;
}

1;
