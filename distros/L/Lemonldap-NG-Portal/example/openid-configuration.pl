#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use JSON;
use strict;

my $portal = Lemonldap::NG::Portal::SharedConf->new();

my $issuerDBOpenIDConnectPath = $portal->{issuerDBOpenIDConnectPath};
my $authorize_uri             = $portal->{oidcServiceMetaDataAuthorizeURI};
my $token_uri                 = $portal->{oidcServiceMetaDataTokenURI};
my $userinfo_uri              = $portal->{oidcServiceMetaDataUserInfoURI};
my $jwks_uri                  = $portal->{oidcServiceMetaDataJWKSURI};
my $registration_uri          = $portal->{oidcServiceMetaDataRegistrationURI};
my $endsession_uri            = $portal->{oidcServiceMetaDataEndSessionURI};
my $checksession_uri          = $portal->{oidcServiceMetaDataCheckSessionURI};

my ($path) = ( $issuerDBOpenIDConnectPath =~ /(\w+)/ );
my $issuer = $portal->{oidcServiceMetaDataIssuer};
my @acr    = keys %{ $portal->{oidcServiceMetaDataAuthnContext} };

# Add a slash to path value if issuer has no trailing slash
$path = "/" . $path unless ( $issuer =~ /\/$/ );

# Create OpenID configuration hash;
my $configuration = {};
$configuration->{issuer} = $issuer;
$configuration->{authorization_endpoint} =
  $issuer . $path . "/" . $authorize_uri;
$configuration->{token_endpoint}    = $issuer . $path . "/" . $token_uri;
$configuration->{userinfo_endpoint} = $issuer . $path . "/" . $userinfo_uri;
$configuration->{jwks_uri}          = $issuer . $path . "/" . $jwks_uri;
$configuration->{registration_endpoint} =
  $issuer . $path . "/" . $registration_uri
  if ( $portal->{oidcServiceAllowDynamicRegistration} );
$configuration->{end_session_endpoint} =
  $issuer . $path . "/" . $endsession_uri;
$configuration->{check_session_iframe} =
  $issuer . $path . "/" . $checksession_uri;
$configuration->{scopes_supported} = [qw/openid profile email address phone/];
$configuration->{response_types_supported} = [
    "code",
    "id_token",
    "id_token token",
    "code id_token",
    "code token",
    "code id_token token"
];

# $configuration->{response_modes_supported}
$configuration->{grant_types_supported} =
  [qw/authorization_code implicit hybrid/];
$configuration->{acr_values_supported}    = \@acr;
$configuration->{subject_types_supported} = ["public"];
$configuration->{id_token_signing_alg_values_supported} =
  [qw/none HS256 HS384 HS512 RS256 RS384 RS512/];

# $configuration->{id_token_encryption_alg_values_supported}
# $configuration->{id_token_encryption_enc_values_supported}
$configuration->{userinfo_signing_alg_values_supported} =
  [qw/none HS256 HS384 HS512 RS256 RS384 RS512/];

# $configuration->{userinfo_encryption_alg_values_supported}
# $configuration->{userinfo_encryption_enc_values_supported}
# $configuration->{request_object_signing_alg_values_supported}
# $configuration->{request_object_encryption_alg_values_supported}
# $configuration->{request_object_encryption_enc_values_supported}
$configuration->{token_endpoint_auth_methods_supported} =
  [qw/client_secret_post client_secret_basic/];

# $configuration->{token_endpoint_auth_signing_alg_values_supported}
# $configuration->{display_values_supported}
# $configuration->{claim_types_supported}
$configuration->{claims_supported} = [qw/sub iss auth_time acr/];

# $configuration->{service_documentation}
# $configuration->{claims_locales_supported}
# $configuration->{ui_locales_supported}
# $configuration->{claims_parameter_supported}
$configuration->{request_parameter_supported}      = JSON::true;
$configuration->{request_uri_parameter_supported}  = JSON::true;
$configuration->{require_request_uri_registration} = JSON::false;

# $configuration->{op_policy_uri}
# $configuration->{op_tos_uri}

my $json = to_json( $configuration, { pretty => 1 } );

print $portal->header('application/json; charset=utf-8');
print $json;
