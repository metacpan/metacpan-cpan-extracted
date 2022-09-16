package t::OidcHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);
use Data::Dumper;
use Test::More;

use constant hook => {
    oidcGenerateCode                  => 'modifyRedirectUri',
    oidcGenerateIDToken               => 'addClaimToIDToken',
    oidcGenerateUserInfoResponse      => 'addClaimToUserInfo',
    oidcGotRequest                    => 'addScopeToRequest',
    oidcResolveScope                  => 'addHardcodedScope',
    oidcGenerateAccessToken           => 'addClaimToAccessToken',
    oidcGotClientCredentialsGrant     => 'oidcGotClientCredentialsGrant',
    oidcGenerateAuthenticationRequest => 'genAuthRequest',
    oidcGenerateTokenRequest          => 'genTokenRequest',
    oidcGotUserInfo                   => 'modifyUserInfo',
    oidcGotIDToken                    => 'modifyIDToken',
    oidcGotOnlineRefresh              => 'refreshHook',
    oidcGotOfflineRefresh             => 'refreshHook',
};

sub addClaimToIDToken {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"id_token_hook"} = 1;
    return PE_OK;
}

sub addClaimToUserInfo {
    my ( $self, $req, $userinfo, $rp, $session_data ) = @_;
    $userinfo->{"userinfo_hook"} = 1;
    $userinfo->{"_auth"}         = $session_data->{_auth};
    $userinfo->{"_scope"}        = $session_data->{_scope};
    return PE_OK;
}

sub addScopeToRequest {
    my ( $self, $req, $oidc_request ) = @_;
    $oidc_request->{scope} = $oidc_request->{scope} . " my_hooked_scope";

    return PE_OK;
}

sub addHardcodedScope {
    my ( $self, $req, $scopeList, $rp ) = @_;
    push @{$scopeList}, "myscope" if $rp ne "scopelessrp";

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

sub genTokenRequest {
    my ( $self, $req, $op, $authorize_request_params ) = @_;

    $authorize_request_params->{my_param} = "my value";
    return PE_OK;
}

sub genAuthRequest {
    my ( $self, $req, $op, $token_request_params ) = @_;

    $token_request_params->{my_param} = "my value";
    return PE_OK;
}

sub modifyIDToken {
    my ( $self, $req, $op, $id_token_payload_hash ) = @_;

    # do some post-processing on the `sub` claim
    $req->sessionInfo->{id_token_hook} = "$op/" . $id_token_payload_hash->{sub};
    return PE_OK;
}

sub modifyUserInfo {
    my ( $self, $req, $op, $userinfo_content ) = @_;

    # Custom attribute processing
    $req->sessionInfo->{userinfo_hook} = "$op/" . $userinfo_content->{sub};
    return PE_OK;
}

sub refreshHook {
    my ( $self, $req, $rp, $refreshInfo, $sessionInfo ) = @_;
    my $uid = $refreshInfo->{uid} || ( "online_" . $sessionInfo->{uid} );
    $refreshInfo->{scope} = $refreshInfo->{scope} . " refreshed_" . $uid;
    return PE_OK;
}

1;
