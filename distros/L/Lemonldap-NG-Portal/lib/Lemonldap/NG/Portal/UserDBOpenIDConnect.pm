## @file
# OpenIDConnect userDB mechanism

## @class
# OpenIDConnect userDB mechanism class
package Lemonldap::NG::Portal::UserDBOpenIDConnect;

use strict;
use Lemonldap::NG::Portal::Simple;

our @ISA     = (qw(Lemonldap::NG::Portal::_OpenIDConnect));
our $VERSION = '1.9.1';

## @apmethod int userDBInit()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    PE_OK;
}

## @apmethod int getUser()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;
    my $op   = $self->{_oidcOPCurrent};

    my $access_token = $self->{tmp}->{access_token};

    my $userinfo_content = $self->getUserInfo( $op, $access_token );

    unless ($userinfo_content) {
        $self->lmLog( "No User Info content", 'warn' );
        return PE_OK;
    }

    $self->lmLog( "UserInfo received: $userinfo_content", 'debug' );

    $self->{tmp}->{OpenIDConnect_user_info} =
      $self->decodeJSON($userinfo_content);

    # Check that received sub is the same than current user
    unless ( $self->{tmp}->{OpenIDConnect_user_info}->{sub} eq $self->{user} ) {
        $self->lmLog( "Received sub do not match current user", 'error' );
        return PE_BADCREDENTIALS;
    }

    PE_OK;
}

## @apmethod int setSessionInfo()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;
    my $op   = $self->{_oidcOPCurrent};

    my %vars = (
        %{ $self->{exportedVars} },
        %{ $self->{oidcOPMetaDataExportedVars}->{$op} }
    );

    while ( my ( $k, $v ) = each %vars ) {
        $self->{sessionInfo}->{$k} =
          $self->{tmp}->{OpenIDConnect_user_info}->{$v}
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

