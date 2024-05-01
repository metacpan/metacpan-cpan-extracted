package Lemonldap::NG::Common::OpenIDConnect::Metadata;

use strict;
use Lemonldap::NG::Common::OpenIDConnect::Constants;
use JSON;
use Mouse::Role;

our $VERSION = '2.19.0';

sub metadataDoc {
    my ( $self, $issuer, $conf, $path ) = @_;
    $conf //= $self->conf;
    my $issuerDBOpenIDConnectPath = $conf->{issuerDBOpenIDConnectPath};
    my $authorize_uri             = $conf->{oidcServiceMetaDataAuthorizeURI};
    my $token_uri                 = $conf->{oidcServiceMetaDataTokenURI};
    my $userinfo_uri              = $conf->{oidcServiceMetaDataUserInfoURI};
    my $jwks_uri                  = $conf->{oidcServiceMetaDataJWKSURI};
    my $registration_uri          = $conf->{oidcServiceMetaDataRegistrationURI};
    my $endsession_uri            = $conf->{oidcServiceMetaDataEndSessionURI};
    my $checksession_uri          = $conf->{oidcServiceMetaDataCheckSessionURI};
    my $introspection_uri = $conf->{oidcServiceMetaDataIntrospectionURI};

    $path ||= $self->path . '/';
    $path = "/" . $path unless ( $issuer =~ /\/$/ );
    my $baseUrl = $issuer . $path;

    my @acr = keys %{ $conf->{oidcServiceMetaDataAuthnContext} };

    # List response types depending on allowed flows
    my $response_types = [];
    my $grant_types    = [];
    if ( $conf->{oidcServiceAllowAuthorizationCodeFlow} ) {
        push( @$response_types, "code" );
        push( @$grant_types,    "authorization_code" );
    }
    if ( $conf->{oidcServiceAllowImplicitFlow} ) {
        push( @$response_types, "id_token", "id_token token" );
        push( @$grant_types, "implicit" );
    }

    # If one of the RPs has password grant enabled
    if (
        grep {
            $conf->{oidcRPMetaDataOptions}->{$_}
              ->{oidcRPMetaDataOptionsAllowPasswordGrant}
        } keys %{ $conf->{oidcRPMetaDataOptions} // {} }
      )
    {
        push( @$grant_types, "password" );
    }

    # If one of the RPs has client credentials grant enabled
    if (
        grep {
            $conf->{oidcRPMetaDataOptions}->{$_}
              ->{oidcRPMetaDataOptionsAllowClientCredentialsGrant}
        } keys %{ $conf->{oidcRPMetaDataOptions} // {} }
      )
    {
        push( @$grant_types, "client_credentials" );
    }

    # If one of the RPs has refresh tokens enabled
    if (
        grep {
            $conf->{oidcRPMetaDataOptions}->{$_}
              ->{oidcRPMetaDataOptionsRefreshToken}
              or $conf->{oidcRPMetaDataOptions}->{$_}
              ->{oidcRPMetaDataOptionsAllowOffline}
        }
        keys %{ $conf->{oidcRPMetaDataOptions} // {} }
      )
    {
        push( @$grant_types, "refresh_token" );
    }

    if ( $conf->{oidcServiceAllowHybridFlow} ) {
        push( @$response_types,
            "code id_token",
            "code token", "code id_token token" );
        push( @$grant_types, "hybrid" );
    }

    my @supportedSigAlg = qw/none HS256 HS384 HS512/;
    if ( $conf->{oidcServiceKeyTypeSig} eq 'EC' ) {
        push @supportedSigAlg, qw/ES256 ES256K ES384 ES512 EdDSA/;
    }
    else {
        push @supportedSigAlg, qw/RS256 RS384 RS512 PS256 PS384 PS512/;
    }

    # Create OpenID configuration hash;
    return {
        issuer => $issuer,

        # Endpoints
        authorization_endpoint => $baseUrl . $authorize_uri,
        token_endpoint         => $baseUrl . $token_uri,
        userinfo_endpoint      => $baseUrl . $userinfo_uri,
        jwks_uri               => $baseUrl . $jwks_uri,
        (
            $conf->{oidcServiceAllowDynamicRegistration}
            ? ( registration_endpoint => $baseUrl . $registration_uri )
            : ()
        ),
        end_session_endpoint => $baseUrl . $endsession_uri,

        #check_session_iframe   => $baseUrl . $checksession_uri,
        introspection_endpoint => $baseUrl . $introspection_uri,

        # Scopes
        scopes_supported         => [qw/openid profile email address phone/],
        response_types_supported => $response_types,
        response_modes_supported => [ "query", "fragment", "form_post", ],
        grant_types_supported    => $grant_types,
        acr_values_supported     => \@acr,
        subject_types_supported  => ["public"],
        token_endpoint_auth_methods_supported =>
          [qw/client_secret_post client_secret_basic/],
        introspection_endpoint_auth_methods_supported =>
          [qw/client_secret_post client_secret_basic/],
        claims_supported                 => [qw/sub iss auth_time acr sid/],
        request_parameter_supported      => JSON::true,
        request_uri_parameter_supported  => JSON::true,
        require_request_uri_registration => JSON::true,

        # Algorithms
        id_token_signing_alg_values_supported => \@supportedSigAlg,

        id_token_encryption_alg_values_supported => ENC_ALG_SUPPORTED,
        id_token_encryption_enc_values_supported => ENC_SUPPORTED,
        userinfo_signing_alg_values_supported    => \@supportedSigAlg,

        userinfo_encryption_alg_values_supported => ENC_ALG_SUPPORTED,
        userinfo_encryption_enc_values_supported => ENC_SUPPORTED,

        # PKCE
        code_challenge_methods_supported => [qw/plain S256/],

        # Logout supported methods
        frontchannel_logout_supported         => JSON::true,
        frontchannel_logout_session_supported => JSON::true,
        backchannel_logout_supported          => JSON::true,
        backchannel_logout_session_supported  => JSON::true,

        # request_object_signing_alg_values_supported
        # request_object_encryption_alg_values_supported
        # request_object_encryption_enc_values_supported

        # token_endpoint_auth_signing_alg_values_supported
        # display_values_supported
        # claim_types_supported
        # service_documentation
        # claims_locales_supported
        # ui_locales_supported
        # claims_parameter_supported

        # op_policy_uri
        # op_tos_uri
    };
}

1;
