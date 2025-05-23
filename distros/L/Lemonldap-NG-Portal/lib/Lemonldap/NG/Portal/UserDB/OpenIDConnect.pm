package Lemonldap::NG::Portal::UserDB::OpenIDConnect;

use strict;
use Mouse;
use Lemonldap::NG::Common::JWT 'getJWTPayload';
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OIDC_AUTH_ERROR
  PE_BADCREDENTIALS
  PE_ERROR
  PE_OK
);

our $VERSION = '2.21.0';

extends qw(
  Lemonldap::NG::Portal::Main::UserDB
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

    my $userinfo_content;
    my $source = $self->opOptions->{$op}->{oidcOPMetaDataOptionsUserinfoSource}
      || 'userinfo';
    if ( $source eq 'id_token' ) {
        $userinfo_content = getJWTPayload( $req->data->{id_token} );
        $self->logger->error(
            "Unable to read ID token content: " . $req->data->{id_token} )
          unless ($userinfo_content);
    }
    elsif ( $source eq 'access_token' ) {
        my $tmp = getJWTPayload($access_token);
        if ($tmp) {
            $userinfo_content = { %{ $userinfo_content || {} }, %$tmp };
        }
        else {
            $self->logger->error(
                "Unable to read ID token content: $access_token");
        }
    }
    unless ($userinfo_content) {
        unless ( $source eq 'userinfo' ) {
            $self->logger->error(
                "Failed to get user info from $source, trying userinfo endpoint"
            );
        }
        $userinfo_content = $self->getUserInfo( $op, $access_token );
    }

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
    my $id_token_sub =
      $req->data->{id_token_sub} || $req->userData->{_oidc_sub};
    my $received_sub = $req->data->{OpenIDConnect_user_info}->{'sub'};
    unless ( $received_sub eq $id_token_sub ) {
        $self->logger->error(
"Received sub $received_sub does not match current user $id_token_sub"
        );
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

    my %vars =
      ( %{ $self->conf->{exportedVars} }, %{ $self->opAttributes->{$op} } );

    while ( my ( $k, $v ) = each %vars ) {
        my $value = $req->data->{OpenIDConnect_user_info}->{$v};
        if ( ref($value) and ref($value) eq "ARRAY" ) {
            $req->{sessionInfo}->{$k} =
              join( $self->conf->{multiValuesSeparator}, @$value );
        }
        else {
            $req->{sessionInfo}->{$k} = $value;
        }
    }

    return PE_OK;
}

1;
