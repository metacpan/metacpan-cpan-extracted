package t::OidcHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_SENDRESPONSE PE_DONE);
use Data::Dumper;
use Test::More;

our $generateRefreshTokenCalled = '';
our $lastTokenResponseGrantType = '';
our $refreshSendResponse        = 0;

has confEnabled => (
    is      => 'rw',
    default => 1,
);

has alg => (
    is      => 'rw',
    default => 'HS512',
);

has rule => (
    is      => 'rw',
    default => '1',
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
    oidcGotOnlineRefresh              => 'refreshHook',
    oidcGotOfflineRefresh             => 'refreshHook',
    oidcGotTokenExchange              => 'tokenExchange',
    getOidcRpConfig                   => 'getRp',
    oidcValidateRedirectUri           => 'allowOnlyLocalhost',
    oidcGenerateAuthorizationResponse => 'buildAuthzResponse',
    oidcGenerateIntrospectionResponse => 'buildIntrospectionResponse',
    oidcGotTokenRequest               => 'gotTokenRequest',
    oidcGenerateRefreshToken          => 'generateRefreshToken',
    oidcGotRegistrationRequest        => 'gotRegistrationRequest',
    oidcRegisterClient                => 'registerClient',
    oidcGenerateMetadata              => 'addCustomMetadata',
};

sub addClaimToIDToken {
    my ( $self, $req, $payload, $rp, $sessionInfo, $extra_headers ) = @_;
    $payload->{"id_token_hook"}     = 1;
    $payload->{"id_token_hook_rp"}  = $rp;
    $payload->{"id_token_hook_uid"} = $sessionInfo->{uid};

    $extra_headers->{"id_token_hook_header"} = 1;

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
    my ( $self, $req, $payload, $rp, $extra_headers ) = @_;

    $payload->{"access_token_hook"} = 1;

    $extra_headers->{typ} = "at+JWT+hook";

    return PE_OK;
}

sub addCustomToken {
    my ( $self, $req, $rp, $response, $codeSession, $userSession, $grant_type )
      = @_;
    $response->{custom_token} = 'CustomToken';
    $lastTokenResponseGrantType = $grant_type || '';
    return PE_OK;
}

sub oidcGotClientCredentialsGrant {
    my ( $self, $req, $payload, $rp ) = @_;
    $payload->{"hooked_username"} = "hook";
    $payload->{"_scope"} .= " cc_hooked";
    return PE_OK;
}

sub refreshHook {
    my ( $self, $req, $rp, $refreshInfo, $sessionInfo ) = @_;

    # Test PE_SENDRESPONSE support
    if ($refreshSendResponse) {
        $req->response(
            [ 200, [ 'Content-Type' => 'text/plain' ], ['Direct response'] ] );
        return PE_SENDRESPONSE;
    }

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

    return PE_OK unless $client_id eq "hookclient" and $self->confEnabled;

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
            oidcRPMetaDataOptionsRule                  => $self->rule,
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

sub allowOnlyLocalhost {
    my ( $self, $req, $rp, $uri, $endpoint, $state ) = @_;

    like(
        $endpoint,
        qr/^(?:end_session|authorization)/,
        "Allowed value in endpoint"
    );
    main::count(1);

    # If this RP is used by devs, allow all localhost urls
    if ( $rp =~ /^dev-/ ) {

        my $parsed_uri = URI->new($uri);
        $state->{result} = ( $parsed_uri->host eq "localhost" );
        return PE_DONE;
    }

    # Returning PE_OK means that we defer the decision to
    # LemonLDAP::NG's built-in logic, which is to only allow
    # explicitely declared URIs

    return PE_OK;
}

sub buildAuthzResponse {
    my ( $self, $req, $oidc_request, $rp, $response_params ) = @_;

    # Add a custom parameter to the authorization response
    $response_params->{authz_hook} = "hooked";

    return PE_OK;
}

sub buildIntrospectionResponse {
    my ( $self, $req, $response, $rp, $token_data ) = @_;

    # Add custom claim to introspection response
    $response->{introspection_hook} = "hooked";

    return PE_OK;
}

sub gotTokenRequest {
    my ( $self, $req, $rp, $grant_type ) = @_;

    # Handle a custom grant type for testing
    if ( $grant_type eq 'urn:test:custom_grant' ) {
        $req->response(
            $self->p->sendJSONresponse(
                $req,
                {
                    custom_grant => 1,
                    grant_type   => $grant_type,
                    rp           => $rp,
                }
            )
        );
        return PE_SENDRESPONSE;
    }

    return PE_OK;
}

sub generateRefreshToken {
    my ( $self, $req, $info, $rp, $offline ) = @_;

    # Add custom data to refresh token
    $info->{refresh_hook} = "hooked_$rp";

    # Mark that this hook was called
    $generateRefreshTokenCalled = 1;

    return PE_OK;
}

sub gotRegistrationRequest {
    my ( $self, $req, $client_metadata ) = @_;

    # Deny registration for clients with a specific redirect_uri pattern
    my $redirect_uris = $client_metadata->{redirect_uris} || [];
    for my $uri (@$redirect_uris) {
        if ( $uri =~ /^https:\/\/denied\.example\.com\// ) {
            $req->response(
                $self->p->sendError( $req, 'registration_not_allowed', 403 ) );
            return PE_SENDRESPONSE;
        }
    }

    return PE_OK;    # Defer to default behavior
}

sub registerClient {
    my ( $self, $req, $newRp, $client_metadata ) = @_;

    # Add a custom option to the new RP
    $newRp->{options}->{oidcRPMetaDataOptionsBypassConsent} = 1;

    return PE_OK;
}

sub addCustomMetadata {
    my ( $self, $req, $metadata ) = @_;
    $metadata->{custom_metadata_hook} = 'hooked';
    push @{ $metadata->{grant_types_supported} }, 'urn:test:custom_grant';
    return PE_OK;
}

1;
