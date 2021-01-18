package t::OidcHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
use Data::Dumper;
use Test::More;

use constant hook => {
    oidcGenerateIDToken          => 'addClaimToIDToken',
    oidcGenerateUserInfoResponse => 'addClaimToUserInfo',
    oidcGotRequest               => 'addScopeToRequest',
};

sub init {
    my ($self) = @_;
    return 1;
}

sub addClaimToIDToken {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"id_token_hook"} = 1;
    return PE_OK;
}

sub addClaimToUserInfo {
    my ( $self, $req, $userinfo ) = @_;
    $userinfo->{"userinfo_hook"} = 1;
    return PE_OK;
}

sub addScopeToRequest {
    my ( $self, $req, $oidc_request ) = @_;
    $oidc_request->{scope} = $oidc_request->{scope} . " my_hooked_scope";

    return PE_OK;
}

1;

