## @file
# UserDB Google module

## @class
# UserDB Google module
package Lemonldap::NG::Portal::UserDBGoogle;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Regexp;

our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Check if authentication module is Google
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;

    unless ( $self->get_module('auth') =~ /^Google/ ) {
        $self->lmLog(
'UserDBGoogle isn\'t useable unless authentication module is set to Google',
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
# Since the job is done by AuthGoogle, here just check that required
# attributes are not null
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    my $self = shift;

    my %vars = ( %{ $self->{exportedVars} }, %{ $self->{googleExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr = $k;
        next
          unless ( $attr =~ s/^!//
            and $v =~ Lemonldap::NG::Common::Regexp::GOOGLEAXATTR() );

        unless ( defined( $self->{sessionInfo}->{$attr} ) ) {
            $self->lmLog(
"Required parameter $attr is not provided by Google server, aborted",
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

