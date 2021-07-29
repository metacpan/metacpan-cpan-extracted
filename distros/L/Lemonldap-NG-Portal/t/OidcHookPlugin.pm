package t::OidcHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
use Data::Dumper;
use Test::More;

use constant hook => {
    oidcGenerateCode              => 'modifyRedirectUri',
    oidcGenerateIDToken           => 'addClaimToIDToken',
    oidcGenerateUserInfoResponse  => 'addClaimToUserInfo',
    oidcGotRequest                => 'addScopeToRequest',
    oidcResolveScope              => 'addHardcodedScope',
    oidcGenerateAccessToken       => 'addClaimToAccessToken',
    oidcGotClientCredentialsGrant => 'oidcGotClientCredentialsGrant',
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

sub addHardcodedScope {
    my ( $self, $req, $scopeList, $rp ) = @_;
    push @{$scopeList}, "myscope";

    return PE_OK;
}

sub modifyRedirectUri {
    my ( $self, $req, $oidc_request, $rp, $code_payload ) = @_;
    my $original_uri = $oidc_request->{redirect_uri};
    $oidc_request->{redirect_uri} = "$original_uri?hooked=1";
    return PE_OK;
}

sub addClaimToAccessToken {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"access_token_hook"} = 1;
    return PE_OK;
}

sub oidcGotClientCredentialsGrant {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"hooked_username"} = "hook";
    return PE_OK;
}

1;

