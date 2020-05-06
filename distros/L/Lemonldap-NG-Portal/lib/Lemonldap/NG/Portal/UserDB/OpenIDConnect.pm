package Lemonldap::NG::Portal::UserDB::OpenIDConnect;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_OK
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Common::Module',
  'Lemonldap::NG::Portal::Lib::OpenIDConnect';

# INITIALIZATION

sub init {
    my ($self) = @_;
    return $self->loadOPs;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req ) = @_;
    my $op = $req->data->{_oidcOPCurrent};

    # This is likely to happen when running getUser without extractFormInfo
    # see #1980
    unless ($op) {
        $self->logger->warn("No OP found in current session");
        return PE_ERROR;
    }

    my $access_token = $req->data->{access_token};

    my $userinfo_content = $self->getUserInfo( $op, $access_token );

    unless ($userinfo_content) {
        $self->logger->warn("No User Info content");
        return PE_OK;
    }

    $self->logger->debug("UserInfo received: $userinfo_content");

    $req->data->{OpenIDConnect_user_info} =
      $self->decodeJSON($userinfo_content);

    # Check that received sub is the same than current user
    unless ( $req->data->{OpenIDConnect_user_info}->{sub} eq $req->{user} ) {
        $self->logger->error("Received sub do not match current user");
        return PE_BADCREDENTIALS;
    }

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

    PE_OK;
}

# Does nothing
sub setGroups {
    PE_OK;
}

1;
