package Lemonldap::NG::Portal::UserDB::OpenIDConnect;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OIDC_AUTH_ERROR
  PE_BADCREDENTIALS
  PE_ERROR
  PE_OK
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Common::Module
  Lemonldap::NG::Portal::Lib::OpenIDConnect
);

# INITIALIZATION

sub init {
    my ($self) = @_;
    return $self->loadOPs;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req ) = @_;

    my ( $op, $access_token ) = $self->getUserInfoParams($req);

    # This is likely to happen when running getUser without extractFormInfo
    # see #1980
    unless ($op) {
        $self->logger->warn("No OP found in current session");
        return PE_ERROR;
    }

    unless ($access_token) {
        $self->logger->warn("Could not get Access Token for User Info request");
        return PE_ERROR;
    }

    my $userinfo_content = $self->getUserInfo( $op, $access_token );

    unless ($userinfo_content) {
        $self->logger->warn("No User Info content");
        return PE_OK;
    }

    # call oidcGotUserInfo hook
    my $h =
      $self->p->processHook( $req, 'oidcGotUserInfo', $op, $userinfo_content, );
    return PE_OIDC_AUTH_ERROR if ( $h != PE_OK );

    $req->data->{OpenIDConnect_user_info} = $userinfo_content;

    # Check that received sub is the same than current user
    unless ( $req->data->{OpenIDConnect_user_info}->{sub} eq $req->{user} ) {
        $self->logger->error("Received sub do not match current user");
        return PE_BADCREDENTIALS;
    }

    return PE_OK;
}

sub findUser {

    # Nothing to do here
    return PE_OK;
}

# Get all required attributes
sub setSessionInfo {
    my ( $self, $req ) = @_;
    my $op = $req->data->{_oidcOPCurrent};

    my %vars = (
        %{ $self->conf->{exportedVars} },
        %{ $self->conf->{oidcOPMetaDataExportedVars}->{$op} }
    );

    while ( my ( $k, $v ) = each %vars ) {
        $req->{sessionInfo}->{$k} = $req->data->{OpenIDConnect_user_info}->{$v};
    }

    return PE_OK;
}

# Does nothing
sub setGroups {
    return PE_OK;
}

1;
