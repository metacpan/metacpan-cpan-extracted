## @file
# UserDB OpenID module

## @class
# UserDB OpenID module
package Lemonldap::NG::Portal::UserDBOpenID;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Regexp;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check if authentication module is OpenID
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;

    unless ( $self->get_module('auth') =~ /^OpenID/ ) {
        $self->lmLog(
'UserDBOpenID isn\'t useable unless authentication module is set to OpenID',
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
# Check if there are some exportedVars in OpenID response.
# See http://openid.net/specs/openid-simple-registration-extension-1_0.html
# for more
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    my $self = shift;

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{openIdExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr     = $k;
        my $required = ( $attr =~ s/^!// );
        if ( $v =~ Lemonldap::NG::Common::Regexp::OPENIDSREGATTR() ) {
            $self->{sessionInfo}->{$attr} = $self->param("openid.sreg.$v");
        }
        else {
            $self->lmLog(
                'Ignoring attribute '
                  . $v
                  . ' which is not a valid OpenID SREG attribute',
                'warn'
            );
        }

        if ( $required and not defined( $self->{sessionInfo}->{$attr} ) ) {
            $self->lmLog(
"Required parameter $attr is not provided by OpenID server, aborted",
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

