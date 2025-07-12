package t::OidcHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_SENDRESPONSE);
use Data::Dumper;
use Test::More;

has confEnabled => (
    is      => 'rw',
    default => 1,
);

has alg => (
    is      => 'rw',
    default => 'HS512',
);

has callCount => (
    is      => 'rw',
    default => 0,
);

use constant hook => {
    oidcGenerateCode                  => 'modifyRedirectUri',
    oidcGenerateIDToken               => 'addClaimToIDToken',
    oidcGenerateUserInfoResponse      => 'addClaimToUserInfo',
    oidcGotRequest                    => 'addScopeToRequest',
    oidcResolveScope                  => 'addHardcodedScope',
    oidcGenerateAccessToken           => 'addClaimToAccessToken',
    oidcGenerateTokenResponse         => 'addCustomToken',
    oidcGotClientCredentialsGrant     => 'oidcGotClientCredentialsGrant',
    oidcGenerateAuthenticationRequest => 'genAuthRequest',
    oidcGenerateTokenRequest          => 'genTokenRequest',
    oidcGotUserInfo                   => 'modifyUserInfo',
    oidcGotIDToken                    => 'modifyIDToken',
    oidcGotOnlineRefresh              => 'refreshHook',
    oidcGotOfflineRefresh             => 'refreshHook',
    oidcGotTokenExchange              => 'tokenExchange',
    getOidcRpConfig                   => 'getRp',
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

sub addCustomToken {
    my ( $self, $req, $rp, $response, $codeSession, $userSession ) = @_;
    $response->{custom_token} = 'CustomToken';
    return PE_OK;
}

sub oidcGotClientCredentialsGrant {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"hooked_username"} = "hook";
    $payload->{"_scope"} .= " cc_hooked";
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

sub tokenExchange {
    my ( $self, $req, $rp ) = @_;
    if ( $req->param("testtokenexchange") ) {
        $req->response( $self->p->sendJSONresponse( $req, { result => 1 } ) );
        return PE_SENDRESPONSE;
    }
    return PE_OK;
}

sub getRp {
    my ( $self, $req, $client_id, $config ) = @_;

    $self->callCount( $self->callCount + 1 );

    $config->{ttl} = 600;

    return unless $client_id eq "hookclient" and $self->confEnabled;

    %$config = (
        confKey    => "hook.hookclient",
        attributes => {
            email    => "mail",
            fullname => "myfullname",
        },
        options => {
            oidcRPMetaDataOptionsDisplayName           => "RP",
            oidcRPMetaDataOptionsIDTokenExpiration     => 120,
            oidcRPMetaDataOptionsIDTokenSignAlg        => $self->alg,
            oidcRPMetaDataOptionsClientSecret          => "hookclient",
            oidcRPMetaDataOptionsAccessTokenExpiration => 120,
            oidcRPMetaDataOptionsBypassConsent         => 1,
            oidcRPMetaDataOptionsRedirectUris          => "http://hook.com/",
            oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
            oidcRPMetaDataOptionsJwks                        =>
'{ "keys": [ {"use":"sig","e":"AQAB","kty":"RSA","n":"s2jsmIoFuWzMkilJaA8__5_T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV-BTAU9TLz7Jzd_iJ5GJ6B8TrH1PHFmHpy8_qE_S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ_SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y_N2j6At2HjkxntbtGQ"}] }',
        },
        macros => {
            myfullname => '"I am ". $cn',
        },
        scopeRules => {
            mydynscope => "1",
        },
        extraClaims => {
            mydynscope => "fullname",
        },
        ttl => 600,
    );

    return PE_OK;
}

1;
