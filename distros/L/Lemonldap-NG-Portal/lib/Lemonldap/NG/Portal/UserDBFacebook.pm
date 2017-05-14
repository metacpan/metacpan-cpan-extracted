## @file
# UserDB Facebook module

## @class
# UserDB Facebook module
#
# To know attributes that can be asked, take a look at
# https://developers.facebook.com/tools/explorer
package Lemonldap::NG::Portal::UserDBFacebook;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check if authentication module is Facebook
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;

    unless ( $self->get_module('auth') =~ /^Facebook/ ) {
        $self->lmLog(
'UserDBFacebook isn\'t useable unless authentication module is set to Facebook',
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
# Since the job is done by AuthFacebook, here just check that required
# attributes are not null
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    my $self = shift;

    my %vars =
      ( %{ $self->{exportedVars} }, %{ $self->{facebookExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr = $k;
        my $required = ( $attr =~ s/^!// ) ? 1 : 0;
        $self->{sessionInfo}->{$attr} = $self->{_facebookDatas}->{$v};
        if ( $required and not( defined $self->{sessionInfo}->{$attr} ) ) {
            $self->lmLog(
"Required parameter $v is not provided by Facebook server, aborted",
                'warn'
            );

            $self->{mustRedirect} = 0;
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

