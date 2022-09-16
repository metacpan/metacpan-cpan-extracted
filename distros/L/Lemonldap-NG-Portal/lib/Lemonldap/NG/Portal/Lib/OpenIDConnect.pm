## @file
# Common OpenID Connect functions

## @class
# Common OpenID Connect functions
package Lemonldap::NG::Portal::Lib::OpenIDConnect;

use strict;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::RSA;
use Digest::SHA
  qw/hmac_sha256_base64 hmac_sha384_base64 hmac_sha512_base64 sha256 sha384
  sha512 sha256_base64 sha384_base64 sha512_base64/;
use JSON;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::JWT
  qw(getAccessTokenSessionId getJWTPayload getJWTHeader getJWTSignature getJWTSignedData);
use MIME::Base64
  qw/encode_base64 decode_base64 encode_base64url decode_base64url/;
use Scalar::Util qw/looks_like_number/;
use Mouse;

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_REDIRECT);

our $VERSION = '2.0.15';

# OpenID Connect standard claims
use constant PROFILE => [
    qw/name family_name given_name middle_name nickname preferred_username
      profile picture website gender birthdate zoneinfo locale updated_at/
];
use constant EMAIL   => [qw/email email_verified/];
use constant ADDRESS =>
  [qw/formatted street_address locality region postal_code country/];
use constant PHONE => [qw/phone_number phone_number_verified/];

use constant OIDC_SCOPES => [qw/openid profile email address phone/];

# PROPERTIES

has oidcOPList   => ( is => 'rw', default => sub { {} }, );
has oidcRPList   => ( is => 'rw', default => sub { {} }, );
has rpAttributes => ( is => 'rw', default => sub { {} }, );
has opRules      => ( is => 'rw', default => sub { {} } );
has spRules      => ( is => 'rw', default => sub { {} } );
has spMacros     => ( is => 'rw', default => sub { {} } );
has spScopeRules => ( is => 'rw', default => sub { {} } );

# return LWP::UserAgent object
has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott = $_[0]->{p}->loadModule('::Lib::OneTimeToken');
        return $ott;
    }
);

# METHODS

# Load OpenID Connect Providers and JWKS data
# @param no_cache Disable cache use
# @return boolean result
sub loadOPs {
    my ($self) = @_;

    # Check cache
    # Check presence of at least one identity provider in configuration
    unless ( $self->conf->{oidcOPMetaDataJSON}
        and keys %{ $self->conf->{oidcOPMetaDataJSON} } )
    {
        $self->logger->warn(
            "No OpenID Connect Provider found in configuration");
        return 1;
    }

    # Extract JSON data
    foreach ( keys %{ $self->conf->{oidcOPMetaDataJSON} } ) {
        my $op_conf =
          $self->decodeJSON( $self->conf->{oidcOPMetaDataJSON}->{$_} );
        if ($op_conf) {
            $self->oidcOPList->{$_}->{conf} = $op_conf;
            $self->oidcOPList->{$_}->{jwks} =
              $self->decodeJSON( $self->conf->{oidcOPMetaDataJWKS}->{$_} );
        }
        else {
            $self->logger->warn("Could not parse OIDC metadata for $_");
        }
    }

    # Set rule
    foreach ( keys %{ $self->conf->{oidcOPMetaDataOptions} } ) {
        my $cond = $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsResolutionRule};
        if ( length $cond ) {
            my $rule_sub =
              $self->p->buildRule( $cond, "OIDC provider resolution" );
            if ($rule_sub) {
                $self->opRules->{$_} = $rule_sub;
            }
        }
    }

    return 1;
}

# Load OpenID Connect Relying Parties
# @param no_cache Disable cache use
# @return boolean result
sub loadRPs {
    my ($self) = @_;

    # Check presence of at least one relying party in configuration
    unless ( $self->conf->{oidcRPMetaDataOptions}
        and keys %{ $self->conf->{oidcRPMetaDataOptions} } )
    {
        $self->logger->warn(
            "No OpenID Connect Relying Party found in configuration");
        return 1;
    }

    foreach my $rp ( keys %{ $self->conf->{oidcRPMetaDataOptions} || {} } ) {
        my $valid = 1;

        # Handle attributes
        my $attributes = {
            profile => PROFILE,
            email   => EMAIL,
            address => ADDRESS,
            phone   => PHONE,
        };

        # Additional claims
        my $extraClaims =
          $self->conf->{oidcRPMetaDataOptionsExtraClaims}->{$rp};

        if ($extraClaims) {
            foreach my $claim ( keys %$extraClaims ) {
                $self->logger->debug("Using extra claim $claim for $rp");
                my @extraAttributes = split( /\s/, $extraClaims->{$claim} );
                $attributes->{$claim} = \@extraAttributes;
            }
        }

        # Access rule
        my $rule = $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsRule};
        if ( length $rule ) {
            $rule = $self->p->HANDLER->substitute($rule);
            unless ( $rule = $self->p->HANDLER->buildSub($rule) ) {
                $self->logger->error( "Unable to build access rule for RP $rp: "
                      . $self->p->HANDLER->tsv->{jail}->error );
                $valid = 0;
            }
        }

        # Load per-RP macros
        my $macros         = $self->conf->{oidcRPMetaDataMacros}->{$rp};
        my $compiledMacros = {};
        for my $macroAttr ( keys %{$macros} ) {
            my $macroRule = $macros->{$macroAttr};
            if ( length $macroRule ) {
                $macroRule = $self->p->HANDLER->substitute($macroRule);
                if ( $macroRule = $self->p->HANDLER->buildSub($macroRule) ) {
                    $compiledMacros->{$macroAttr} = $macroRule;
                }
                else {
                    $self->logger->error(
                        "Unable to build macro $macroAttr for RP $rp:"
                          . $self->p->HANDLER->tsv->{jail}->error );
                    $valid = 0;
                }
            }
        }

        # Load per-RP dynamic scopes
        my $scopes         = $self->conf->{oidcRPMetaDataScopeRules}->{$rp};
        my $compiledScopes = {};
        for my $scopeName ( keys %{$scopes} ) {
            my $scopeRule = $scopes->{$scopeName};
            if ( length $scopeRule ) {
                $scopeRule = $self->p->HANDLER->substitute($scopeRule);
                if ( $scopeRule = $self->p->HANDLER->buildSub($scopeRule) ) {
                    $compiledScopes->{$scopeName} = $scopeRule;
                }
                else {
                    $self->logger->error(
                        "Unable to build scope $scopeName for RP $rp:"
                          . $self->p->HANDLER->tsv->{jail}->error );
                    $valid = 0;
                }
            }
        }
        if ($valid) {

            # Register RP
            $self->oidcRPList->{$rp} =
              $self->conf->{oidcRPMetaDataOptions}->{$rp};
            $self->rpAttributes->{$rp} = $attributes;
            $self->spMacros->{$rp}     = $compiledMacros;
            $self->spScopeRules->{$rp} = $compiledScopes;
            $self->spRules->{$rp}      = $rule;
        }
        else {
            $self->logger->error(
                "Relaying Party $rp has errors and will be ignored");
        }
    }
    return 1;
}

# Refresh JWKS data if needed
# @param no_cache Disable cache update
# @return boolean result
sub refreshJWKSdata {
    my ($self) = @_;

    unless ( $self->conf->{oidcOPMetaDataJSON}
        and keys %{ $self->conf->{oidcOPMetaDataJSON} } )
    {
        $self->logger->debug(
            "No OpenID Provider configured, JWKS data will not be refreshed");
        return 1;
    }

    foreach ( keys %{ $self->conf->{oidcOPMetaDataJSON} } ) {

        # Refresh JWKS data if
        # 1/ oidcOPMetaDataOptionsJWKSTimeout > 0
        # 2/ jwks_uri defined in metadata

        my $jwksTimeout =
          $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsJWKSTimeout};
        my $jwksUri = $self->oidcOPList->{$_}->{conf}->{jwks_uri};

        unless ($jwksTimeout) {
            $self->logger->debug(
                "No JWKS refresh timeout defined for $_, skipping...");
            next;
        }

        unless ($jwksUri) {
            $self->logger->debug("No JWKS URI defined for $_, skipping...");
            next;
        }

        if ( $self->oidcOPList->{$_}->{jwks}->{time} + $jwksTimeout > time ) {
            $self->logger->debug("JWKS data still valid for $_, skipping...");
            next;
        }

        $self->logger->debug("Refresh JWKS data for $_ from $jwksUri");

        my $response = $self->ua->get($jwksUri);

        if ( $response->is_error ) {
            $self->logger->warn(
                "Unable to get JWKS data for $_ from $jwksUri: "
                  . $response->message );
            $self->logger->debug( $response->content );
            next;
        }

        my $content = $self->decodeJSON( $response->decoded_content );

        $self->oidcOPList->{$_}->{jwks} = $content;
        $self->oidcOPList->{$_}->{jwks}->{time} = time;

    }
    return 1;
}

# Get Relying Party corresponding to a Client ID
# @param client_id Client ID
# @return String result
sub getRP {
    my ( $self, $client_id ) = @_;
    my $rp;

    foreach ( keys %{ $self->oidcRPList } ) {
        if ( $client_id eq
            $self->oidcRPList->{$_}->{oidcRPMetaDataOptionsClientID} )
        {
            $rp = $_;
            last;
        }
    }
    return $rp;
}

# Compute callback URI
# @return String Callback URI
sub getCallbackUri {
    my ( $self, $req ) = @_;

    my $callback_get_param = $self->conf->{oidcRPCallbackGetParam};

    my $callback_uri = $self->conf->{portal};
    $callback_uri .=
      ( $self->conf->{portal} =~ /\?/ )
      ? '&' . $callback_get_param . '=1'
      : '?' . $callback_get_param . '=1';

    $self->logger->debug("OpenIDConnect Callback URI: $callback_uri");
    return $callback_uri;
}

# Build Authentication Request URI for Authorization Code Flow
# @param op OpenIP Provider configuration key
# @param state State
# return String Authentication Request URI
sub buildAuthorizationCodeAuthnRequest {
    my ( $self, $req, $op, $state ) = @_;

    my $authorize_uri =
      $self->oidcOPList->{$op}->{conf}->{authorization_endpoint};

    unless ($authorize_uri) {
        $self->logger->error(
            "Could not build Authorize request: no
            'authorization_endpoint'" . " in JSON metadata for OP $op"
        );
        return undef;
    }
    my $client_id =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsClientID};
    my $scope =
      $self->conf->{oidcOPMetaDataOptions}->{$op}->{oidcOPMetaDataOptionsScope};
    my $use_nonce =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsUseNonce};
    my $response_type = "code";
    my $redirect_uri  = $self->getCallbackUri($req);
    my $display =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsDisplay};
    my $prompt =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsPrompt};
    my $max_age =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsMaxAge};
    my $ui_locales =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsUiLocales};
    my $acr_values =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsAcrValues};

    my $nonce;
    $nonce = $self->ott->createToken if ($use_nonce);

    my $authorize_request_params = {
        response_type => $response_type,
        client_id     => $client_id,
        scope         => $scope,
        redirect_uri  => $redirect_uri,
        ( defined $state      ? ( state      => $state )      : () ),
        ( defined $nonce      ? ( nonce      => $nonce )      : () ),
        ( defined $display    ? ( display    => $display )    : () ),
        ( defined $prompt     ? ( prompt     => $prompt )     : () ),
        ( $max_age            ? ( max_age    => $max_age )    : () ),
        ( defined $ui_locales ? ( ui_locales => $ui_locales ) : () ),
        ( defined $acr_values ? ( acr_values => $acr_values ) : () )
    };

    # Call oidcGenerateAuthenticationRequest
    my $h = $self->p->processHook(
        $req, 'oidcGenerateAuthenticationRequest',
        $op,  $authorize_request_params
    );
    return if ( $h != PE_OK );

    my $authn_uri =
        $authorize_uri
      . ( $authorize_uri =~ /\?/ ? '&' : '?' )
      . build_urlencoded(%$authorize_request_params);

    $self->logger->debug(
        "OpenIDConnect Authorization Code Flow Authn Request: $authn_uri");

    return $authn_uri;
}

# Build Authentication Response URI for Authorization Code Flow
# @param redirect_uri Redirect URI
# @param code Code
# @param state State
# @param session_state Session state
# return String Authentication Response URI
sub buildAuthorizationCodeAuthnResponse {
    my ( $self, $redirect_uri, $code, $state, $session_state ) = @_;

    my $response_url =
        $redirect_uri
      . ( $redirect_uri =~ /\?/ ? '&' : '?' )
      . build_urlencoded(
        code => $code,
        ( $state         ? ( state         => $state )         : () ),
        ( $session_state ? ( session_state => $session_state ) : () )
      );

    return $response_url;
}

# Build Authentication Response URI for Implicit Flow
# @param redirect_uri Redirect URI
# @param access_token Access token
# @param id_token ID token
# @param expires_in Expiration of access token
# @param state State
# @param session_state Session state
# return String Authentication Response URI
sub buildImplicitAuthnResponse {
    my ( $self, $redirect_uri, $access_token, $id_token, $expires_in,
        $state, $session_state, $scope )
      = @_;

    my $response_url = "$redirect_uri#"
      . build_urlencoded(
        id_token => $id_token,
        (
            $access_token
            ? ( token_type => 'bearer', access_token => $access_token )
            : ()
        ),
        ( $expires_in    ? ( expires_in    => $expires_in )    : () ),
        ( $state         ? ( state         => $state )         : () ),
        ( $scope         ? ( scope         => $scope )         : () ),
        ( $session_state ? ( session_state => $session_state ) : () )
      );
    return $response_url;
}

# Build Authentication Response URI for Hybrid Flow
# @param redirect_uri Redirect URI
# @param code Code
# @param access_token Access token
# @param id_token ID token
# @param expires_in Expiration of access token
# @param state State
# @param session_state Session state
# return String Authentication Response URI
sub buildHybridAuthnResponse {
    my (
        $self,       $redirect_uri, $code,          $access_token, $id_token,
        $expires_in, $state,        $session_state, $scope
    ) = @_;

    my $response_url = "$redirect_uri#"
      . build_urlencoded(
        code => $code,
        (
            $access_token
            ? ( token_type => 'bearer', access_token => $access_token )
            : ()
        ),
        (
            $id_token ? ( id_token => $id_token )
            : ()
        ),
        ( $expires_in    ? ( expires_in    => $expires_in )    : () ),
        ( $state         ? ( state         => $state )         : () ),
        ( $scope         ? ( scope         => $scope )         : () ),
        ( $session_state ? ( session_state => $session_state ) : () )
      );
    return $response_url;
}

sub getAccessTokenFromTokenEndpoint {
    my ( $self, $req, $op, $grant_type, $grant_options ) = @_;

    $grant_options ||= {};

    my $client_id =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsClientID};
    my $client_secret =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsClientSecret};
    my $access_token_uri =
      $self->oidcOPList->{$op}->{conf}->{token_endpoint};

    unless ($access_token_uri) {
        $self->logger->error(
            "Could not build Token request: no
            'token_endpoint'" . " in JSON metadata for OP $op"
        );
        return 0;
    }

    my $auth_method =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsTokenEndpointAuthMethod}
      || 'client_secret_post';

    unless ( $auth_method =~ /^client_secret_(basic|post)$/o ) {
        $self->logger->error(
            "Bad authentication method on token endpoint for OP $op");
        return 0;
    }

    $self->logger->debug(
        "Using auth method $auth_method to token endpoint $access_token_uri");

    my $response;
    my $token_request_params = {
        grant_type => $grant_type,
        %{$grant_options}
    };

    # Call oidcGenerateTokenRequest
    my $h = $self->p->processHook( $req, 'oidcGenerateTokenRequest',
        $op, $token_request_params );
    return 0 if ( $h != PE_OK );

    if ( $auth_method eq "client_secret_basic" ) {
        $response = $self->ua->post(
            $access_token_uri, $token_request_params,
            "Authorization" => "Basic "
              . encode_base64( "$client_id:$client_secret", '' ),
            "Content-Type" => 'application/x-www-form-urlencoded',
        );
    }
    elsif ( $auth_method eq "client_secret_post" ) {
        $token_request_params->{client_id}     = $client_id;
        $token_request_params->{client_secret} = $client_secret;

        $response = $self->ua->post( $access_token_uri, $token_request_params,
            "Content-Type" => 'application/x-www-form-urlencoded' );
    }
    else {
        $self->logger->error("Unknown auth method $auth_method");
    }

    if ( $response->is_error ) {
        $self->logger->error( "Bad token response: " . $response->message );
        $self->logger->debug( $response->content );
        return 0;
    }
    return $response->decoded_content;
}

# Get Token response with authorization code
# @param op OpenIP Provider configuration key
# @param code Code
# @param auth_method Authentication Method (optional)
# return String Token response decoded content
sub getAuthorizationCodeAccessToken {
    my ( $self, $req, $op, $code ) = @_;

    my $redirect_uri = $self->getCallbackUri($req);

    return $self->getAccessTokenFromTokenEndpoint( $req, $op,
        "authorization_code",
        { code => $code, redirect_uri => $redirect_uri } );
}

# Check validity of Token Response
# return boolean 1 if the response is valid, 0 else
sub checkTokenResponseValidity {
    my ( $self, $json ) = @_;

    # token_type MUST be Bearer
    unless ( $json->{token_type} =~ /^Bearer$/i ) {
        $self->logger->error(
            "Token type is " . $json->{token_type} . " but must be Bearer" );
        return 0;
    }

    # id_token MUST be present
    unless ( $json->{id_token} ) {
        $self->logger->error("No id_token");
        return 0;
    }

    return 1;
}

# Check validity of ID Token
# return boolean 1 if the token is valid, 0 else
sub checkIDTokenValidity {
    my ( $self, $op, $id_token ) = @_;

    my $client_id =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsClientID};
    my $acr_values =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsAcrValues};
    my $max_age =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsMaxAge};
    my $id_token_max_age =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsIDTokenMaxAge};
    my $use_nonce =
      $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsUseNonce};

    # Check issuer
    unless ( $id_token->{iss} eq $self->oidcOPList->{$op}->{conf}->{issuer} ) {
        $self->logger->error("Issuer mismatch");
        return 0;
    }

    # Check audience
    if ( ref $id_token->{aud} ) {
        my @audience = @{ $id_token->{aud} };
        unless ( grep $_ eq $client_id, @audience ) {
            $self->logger->error("Client ID not found in audience array");
            return 0;
        }

        if ( $#audience > 1 ) {
            unless ( $id_token->{azp} eq $client_id ) {
                $self->logger->error(
                    "More than one audience, and azp not equal to client ID");
                return 0;
            }
        }
    }
    else {
        unless ( $id_token->{aud} eq $client_id ) {
            $self->logger->error("Audience mismatch");
            return 0;
        }
    }

    # Check time
    unless ( time < $id_token->{exp} ) {
        $self->logger->error("ID token expired");
        return 0;
    }

    # Check iat
    my $iat = $id_token->{iat};
    if ($id_token_max_age) {
        unless ( $iat + $id_token_max_age > time ) {
            $self->logger->error(
                "ID token too old (Max age: $id_token_max_age)");
            return 0;
        }
    }

    # Check nonce
    if ($use_nonce) {
        my $nonce = $id_token->{nonce};
        unless ($nonce) {
            $self->logger->error("Nonce was not returned by OP $op");
            return 0;
        }
        else {
            # Get nonce session
            unless ( $self->ott->getToken($nonce) ) {
                $self->logger->error("Nonce $nonce verification failed");
                return 0;
            }
        }
    }

    # Check acr
    my $acr = $id_token->{acr};
    if ( defined $acr_values ) {
        unless ($acr) {
            $self->logger->error("ACR was not returned by OP $op");
            return 0;
        }
        unless ( $acr_values =~ /\b$acr\b/i ) {
            $self->logger->error(
                "ACR $acr not listed in request ACR values ($acr_values)");
            return 0;
        }
    }

    # Check auth_time
    my $auth_time = $id_token->{auth_time};
    if ($max_age) {
        unless ($auth_time) {
            $self->logger->error("Auth time was not returned by OP $op");
            return 0;
        }
        if ( time > $auth_time + $max_age ) {
            $self->userLogger->error(
"Authentication time ($auth_time) is too old (Max age: $max_age)"
            );
            return 0;
        }
    }

    return 1;
}

# Returns the current OP and a valid Access token
sub getUserInfoParams {
    my ( $self, $req ) = @_;

    my $op = $req->data->{_oidcOPCurrent};

    if ($op) {

        # We are in the middle of an auth process,
        # access token has just been fetched already
        my $access_token = $req->data->{access_token};
        return ( $op, $access_token );
    }
    else {
        # Get OP and access token from existing session (refresh)
        return $self->getUserInfoParamsFromSession($req);
    }
}

sub getUserInfoParamsFromSession {
    my ( $self, $req ) = @_;
    my $op = $req->userData->{_oidc_OP};

    # Save current OP, we will need it for setSessionInfo & friends
    $req->data->{_oidcOPCurrent} = $op;

    if ($op) {
        my $access_token     = $req->userData->{_oidc_access_token};
        my $access_token_eol = $req->userData->{_oidc_access_token_eol};
        if ($access_token_eol) {
            return $self->refreshAccessTokenIfExpired( $req, $op );
        }
        else {
            # We don't know the TTL for this access token,
            # so we can only hope that it works
            return ( $op, $access_token );
        }
    }
    else {
        $self->logger->warn("No OP found in session");
        return ( $op, undef );
    }
}

sub refreshAccessTokenIfExpired {
    my ( $self, $req, $op, $session ) = @_;

    # Handle unauthenticated OIDC calls
    my $data = $session ? $session->data : $req->userData;

    my $access_token     = $data->{_oidc_access_token};
    my $access_token_eol = $data->{_oidc_access_token_eol};
    if ( time < $access_token_eol ) {

        # Access Token is still valid, return it
        return ( $op, $access_token );
    }
    else {
        # Refresh Access Token
        return ( $op, $self->refreshAccessToken( $req, $op, $session ) );
    }
}

sub refreshAccessToken {
    my ( $self, $req, $op, $session ) = @_;

    # Handle unauthenticated OIDC calls
    my $data       = $session ? $session->data : $req->userData;
    my $session_id = $session ? $session->id   : $req->id;

    my $refresh_token = $data->{_oidc_refresh_token};

    if ($refresh_token) {

        my $content =
          $self->getAccessTokenFromTokenEndpoint( $req, $op, 'refresh_token',
            { refresh_token => $refresh_token } );

        if ($content) {
            my $token_response = $self->decodeTokenResponse($content);
            if ($token_response) {

                my $access_token  = $token_response->{access_token};
                my $expires_in    = $token_response->{expires_in};
                my $refresh_token = $token_response->{refresh_token};

                undef $expires_in unless looks_like_number($expires_in);

                $self->logger->debug("Access token: $access_token");
                $self->logger->debug( "Access token expires in: "
                      . ( $expires_in || "<unknown>" ) );
                $self->logger->debug(
                    "Refresh token: " . ( $refresh_token || "<none>" ) );

                my $updateSession;

                # Remember tokens
                $updateSession->{_oidc_access_token}  = $access_token;
                $updateSession->{_oidc_refresh_token} = $refresh_token
                  if $refresh_token;

                # If access token TTL is given save expiration date
                # (with security margin)
                if ($expires_in) {
                    $updateSession->{_oidc_access_token_eol} =
                      time + ( $expires_in * 0.9 );
                }

                $self->p->updateSession( $req, $updateSession, $session_id );

                return ($access_token);
            }
            else {
                $self->logger->warn("Could not decode Token Response for $op");
                return undef;
            }
        }
        else {
            $self->logger->warn("Could not fetch new Access Token for $op");
            return undef;
        }
    }
    else {
        $self->logger->warn("No Refresh Token was found for $op");
        return undef;
    }
}

# Get UserInfo response
# return String UserInfo response decoded content
sub getUserInfo {
    my ( $self, $op, $access_token ) = @_;

    my $userinfo_uri =
      $self->oidcOPList->{$op}->{conf}->{userinfo_endpoint};

    unless ($userinfo_uri) {
        $self->logger->error("UserInfo URI not found in $op configuration");
        return 0;
    }

    $self->logger->debug(
        "Request User Info on $userinfo_uri with access token $access_token");

    my $response = $self->ua->get( $userinfo_uri,
        "Authorization" => "Bearer $access_token" );

    if ( $response->is_error ) {
        $self->logger->error( "Bad userinfo response: " . $response->message );
        $self->logger->debug( $response->content );
        return 0;
    }

    my $userinfo_content = $response->decoded_content;

    $self->logger->debug("UserInfo received: $userinfo_content");

    my $content_type = $response->header('Content-Type');
    if ( $content_type =~ /json/ ) {
        return $self->decodeUserInfo($userinfo_content);
    }
    elsif ( $content_type =~ /jwt/ ) {
        return unless $self->verifyJWTSignature( $userinfo_content, $op );
        return getJWTPayload($userinfo_content);
    }
}

# Convert JSON to HashRef
# @return HashRef JSON decoded content
sub decodeJSON {
    my ( $self, $json ) = @_;
    my $json_hash;

    eval { $json_hash = from_json( $json, { allow_nonref => 1 } ); };
    return undef if ($@);

    return $json_hash;
}

sub decodeTokenResponse {
    return decodeJSON(@_);
}

sub decodeClientMetadata {
    return decodeJSON(@_);
}

sub decodeUserInfo {
    return decodeJSON(@_);
}

# Create a new Authorization Code
# @param info hashref of session info
# @return new Lemonldap::NG::Common::Session object

sub newAuthorizationCode {
    my ( $self, $rp, $info ) = @_;

    return $self->getOpenIDConnectSession(
        undef,
        "authorization_code",
        $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsAuthorizationCodeExpiration}
          || $self->conf->{oidcServiceAuthorizationCodeExpiration},
        ,
        $info
    );
}

# Get existing Authorization Code
# @param id
# @return new Lemonldap::NG::Common::Session object

sub getAuthorizationCode {
    my ( $self, $id ) = @_;

    return $self->getOpenIDConnectSession( $id, "authorization_code" );
}

# Create a new Access Token
# @param req current request
# @param scope access token scope
# @param rp configuration key of the RP this token is being made for
# @param sessionInfo. Hashref of session info OR session ID for lazy fetching
# @param info hashref of access token session info (offline vs online)
# @return new Lemonldap::NG::Common::Session object

sub newAccessToken {
    my ( $self, $req, $rp, $scope, $sessionInfo, $info ) = @_;

    my $at_info = {

        scope => $scope,
        rp    => $rp,
        %{$info},
    };

    my $session = $self->getOpenIDConnectSession(
        undef,
        "access_token",
        $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsAccessTokenExpiration}
          || $self->conf->{oidcServiceAccessTokenExpiration},
        $at_info,
    );

    if ($session) {
        if ( $self->_wantJWT($rp) ) {
            my $at_jwt =
              $self->makeJWT( $req, $rp, $scope, $session->id, $sessionInfo );
            $at_info->{sha256_hash} = $self->createHash( $at_jwt, 256 );
            $self->updateToken( $session->id, $at_info );
            return $at_jwt;
        }
        else {
            return $session->id;
        }
    }
    else {
        return undef;
    }
}

sub _wantJWT {
    my ( $self, $rp ) = @_;
    return $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenJWT};
}

sub makeJWT {
    my ( $self, $req, $rp, $scope, $id, $sessionInfo ) = @_;

    my $exp =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};
    $exp += time;
    my $client_id = $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID};

    my $access_token_payload = {
        iss       => $self->iss,                  # Issuer Identifier
        exp       => $exp,                        # expiration
        aud       => $self->getAudiences($rp),    # Audience
        client_id => $client_id,                  # Client ID
        iat       => time,                        # Issued time
        jti       => $id,                         # Access Token session ID
        scope     => $scope,                      # Scope
    };

    my $claims =
      $self->buildUserInfoResponseFromData( $req, $scope, $rp, $sessionInfo );

    # Release claims, or only sub
    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsAccessTokenClaims} )
    {
        foreach ( keys %$claims ) {
            $access_token_payload->{$_} = $claims->{$_};
        }
    }
    else {
        $access_token_payload->{sub} = $claims->{sub};
    }

    # Call hook to let the user modify payload
    my $h = $self->p->processHook( $req, 'oidcGenerateAccessToken',
        $access_token_payload, $rp );
    return undef if ( $h != PE_OK );

    # Get signature algorithm
    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenSignAlg} || "RS256";
    $self->logger->debug("Access Token signature algorithm: $alg");

    my $jwt = $self->createJWT( $access_token_payload, $alg, $rp, "at+JWT" );

    return $jwt;
}

# Get an session from the supplied Access Token
# @param id
# @return new Lemonldap::NG::Common::Session object
sub getAccessToken {
    my ( $self, $access_token ) = @_;

    my $id = getAccessTokenSessionId($access_token);
    return unless $id;

    my $session = $self->getOpenIDConnectSession( $id, "access_token" );
    return undef unless $session;

    my $stored_hash = $session->{data}->{sha256_hash};
    if ($stored_hash) {
        my $incoming_hash = $self->createHash( $access_token, 256 );
        if ( $stored_hash eq $incoming_hash ) {
            return $session;
        }
        else {
            $self->logger->error(
                    "Incoming Access token hash $incoming_hash "
                  . "does not match stored hash $stored_hash. "
                  . "The access token might have been tampered with." );
            return undef;
        }
    }
    else {
        return $session;
    }
}

# Create a new Refresh Token
# @param info hashref of session info
# @return new Lemonldap::NG::Common::Session object

sub newRefreshToken {
    my ( $self, $rp, $info, $offline ) = @_;
    my $ttl =
      $offline
      ? ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsOfflineSessionExpiration}
          || $self->conf->{oidcServiceOfflineSessionExpiration} )
      : $self->conf->{timeout};

    return $self->getOpenIDConnectSession( undef, "refresh_token", $ttl,
        $info );
}

# Get existing Refresh Token
# @param id
# @return new Lemonldap::NG::Common::Session object

sub getRefreshToken {
    my ( $self, $id ) = @_;

    return $self->getOpenIDConnectSession( $id, "refresh_token" );
}

sub updateRefreshToken {
    my $self = shift;
    return $self->updateToken(@_);
}

sub updateToken {
    my ( $self, $id, $infos ) = @_;

    my %storage = (
        storageModule        => $self->conf->{oidcStorage},
        storageModuleOptions => $self->conf->{oidcStorageOptions},
    );

    unless ( $storage{storageModule} ) {
        %storage = (
            storageModule        => $self->conf->{globalStorage},
            storageModuleOptions => $self->conf->{globalStorageOptions},
        );
    }

    my $oidcSession = Lemonldap::NG::Common::Session->new( {
            %storage,
            cacheModule        => $self->conf->{localSessionStorage},
            cacheModuleOptions => $self->conf->{localSessionStorageOptions},
            id                 => $id,
            info               => $infos,
        }
    );

    if ( $oidcSession->error ) {
        $self->userLogger->warn(
            "OpenIDConnect session $id isn't yet available");
        return undef;
    }

    return $oidcSession;
}

# Try to recover the OpenID Connect session corresponding to id and return session
# If id is set to undef, return a new session
# @return Lemonldap::NG::Common::Session object
sub getOpenIDConnectSession {
    my ( $self, $id, $type, $ttl, $info ) = @_;
    my %storage = (
        storageModule        => $self->conf->{oidcStorage},
        storageModuleOptions => $self->conf->{oidcStorageOptions},
    );

    $ttl ||= $self->conf->{timeout};

    unless ( $storage{storageModule} ) {
        %storage = (
            storageModule        => $self->conf->{globalStorage},
            storageModuleOptions => $self->conf->{globalStorageOptions},
        );
    }

    my $oidcSession = Lemonldap::NG::Common::Session->new( {
            %storage,
            cacheModule        => $self->conf->{localSessionStorage},
            cacheModuleOptions => $self->conf->{localSessionStorageOptions},
            id                 => $id,
            kind               => $self->sessionKind,
            (
                $info
                ? (
                    info => {
                        _type  => $type,
                        _utime => time + $ttl - $self->conf->{timeout},
                        %{$info}
                    }
                  )
                : ()
            ),
        }
    );

    if ( $oidcSession->error ) {
        if ($id) {
            $self->userLogger->warn(
                "OpenIDConnect session $id isn't yet available");
        }
        else {
            $self->logger->error("Unable to create new OpenIDConnect session");
            $self->logger->error( $oidcSession->error );
        }
        return undef;
    }

    if ( $id and $type ) {
        my $storedType = $oidcSession->{data}->{_type};

        # Only check if a type is set in DB, for backward compatibility
        if ( $storedType and $type ne $storedType ) {
            $self->logger->error( "Wrong OpenID session type: "
                  . $oidcSession->{data}->{_type}
                  . ". Expected: "
                  . $type );
            return undef;
        }

        # Make sure the token is still valid, we already compensated for
        # different TTLs when storing _utime
        if (
            time > ( $oidcSession->{data}->{_utime} + $self->conf->{timeout} ) )
        {
            $self->logger->error("Session $id has expired");
            return undef;
        }
    }

    # Make sure the token is still valid, we already compensated for
    # different TTLs when storing _utime
    if ( time > ( $oidcSession->{data}->{_utime} + $self->conf->{timeout} ) ) {
        $self->logger->error("Session $id has expired");
        return undef;
    }

    return $oidcSession;
}

# Store information in state database and return
# corresponding session_id
# @return State Session ID
sub storeState {
    my ( $self, $req, @data ) = @_;

    # check if there are data to store
    my $infos;
    foreach (@data) {
        $infos->{$_}        = $req->{$_}       if $req->{$_};
        $infos->{"data_$_"} = $req->data->{$_} if $req->data->{$_};
    }
    return unless ($infos);

    # Session type
    $infos->{_type} = "state";

    # Set _utime for session autoremove
    # Use default session timeout and relayState session timeout to compute it
    my $time         = time();
    my $timeout      = $self->conf->{timeout};
    my $stateTimeout = $self->conf->{oidcRPStateTimeout} || $timeout;

    $infos->{_utime} = $time + ( $stateTimeout - $timeout );

    # Create state session and store infos
    return $self->ott->createToken($infos);
}

# Extract state information into $self
sub extractState {
    my ( $self, $req, $state ) = @_;

    return 0 unless $state;

    # Open state session
    my $stateSession = $self->ott->getToken($state);

    return 0 unless $stateSession;

    # Push values in $self
    foreach ( keys %{$stateSession} ) {
        next
          if $_ =~
/^(?:type|_session_id|_session_kind|_utime|tokenTimeoutTimestamp|tokenSessionStartTimestamp)$/;
        my $tmp = $stateSession->{$_};
        if (s/^data_//) {
            $req->data->{$_} = $tmp;
        }
        elsif ( $req->can($_) ) {
            $req->$_($tmp);
        }
        else {
            $self->logger->warn("Unknown request property $_, skipping");
        }
    }

    return 1;
}

# Check signature of a JWT
# @return boolean 1 if signature is verified, 0 else
sub verifyJWTSignature {
    my ( $self, $jwt, $op, $rp ) = @_;

    $self->logger->debug("Verification of JWT signature: $jwt");

    # Extract JWT parts
    my $jwt_header  = getJWTHeader($jwt);
    my $signed_data = getJWTSignedData($jwt);
    my $signature   = getJWTSignature($jwt);

    # Get signature algorithm
    my $alg = $jwt_header->{alg};

    $self->logger->debug("JWT signature algorithm: $alg");

    if ( $alg eq "none" ) {

        # If none alg, signature should be empty
        if ($signature) {
            $self->logger->debug( "Signature "
                  . $signature
                  . " is present but algorithm is 'none'" );
            return 0;
        }
        $self->logger->debug(
            "JWT algorithm is 'none', signature cannot be verified");
        return 0;
    }

    if ( $alg eq "HS256" or $alg eq "HS384" or $alg eq "HS512" ) {

        # Check signature with client secret
        my $client_secret;
        $client_secret =
          $self->conf->{oidcOPMetaDataOptions}->{$op}
          ->{oidcOPMetaDataOptionsClientSecret}
          if ($op);
        $client_secret =
          $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsClientSecret}
          if ($rp);

        my $digest;

        if ( $alg eq "HS256" ) {
            $digest = hmac_sha256_base64( $signed_data, $client_secret );
        }

        if ( $alg eq "HS384" ) {
            $digest = hmac_sha384_base64( $signed_data, $client_secret );
        }

        if ( $alg eq "HS512" ) {
            $digest = hmac_sha512_base64( $signed_data, $client_secret );
        }

        # Convert + and / to get Base64 URL valid (RFC 4648)
        $digest =~ s/\+/-/g;
        $digest =~ s/\//_/g;

        unless ( $digest eq $signature ) {
            $self->logger->debug(
                "Digest $digest not equal to signature " . $signature );
            return 0;
        }
        return 1;
    }

    if ( $alg eq "RS256" or $alg eq "RS384" or $alg eq "RS512" ) {

        if ($rp) {
            $self->logger->debug("Algorithm $alg not supported");
            return 0;
        }

        # The public key is needed
        unless ( $self->oidcOPList->{$op}->{jwks} ) {
            $self->logger->error(
                "Cannot verify $alg signature: no JWKS data found");
            return 0;
        }

        my $keys = $self->oidcOPList->{$op}->{jwks}->{keys};
        my $key_hash;

        # Find Key ID associated with signature
        my $kid = $jwt_header->{kid};

        if ($kid) {
            $self->logger->debug("Search key with id $kid");
            foreach (@$keys) {
                if ( $_->{kid} eq $kid ) {
                    $key_hash = $_;
                    last;
                }
            }
        }
        else {
            $key_hash = shift @$keys;
        }

        unless ($key_hash) {
            $self->logger->error("No key found in JWKS data");
            return 0;
        }

        $self->logger->debug(
            "Found public key parameter n: " . $key_hash->{n} );
        $self->logger->debug(
            "Found public key parameter e: " . $key_hash->{e} );

        # Create public key
        my $n =
          Crypt::OpenSSL::Bignum->new_from_bin(
            decode_base64url( $key_hash->{n} ) );
        my $e =
          Crypt::OpenSSL::Bignum->new_from_bin(
            decode_base64url( $key_hash->{e} ) );

        my $public_key = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e );

        if ( $alg eq "RS256" ) {
            $public_key->use_sha256_hash;
        }

        if ( $alg eq "RS384" ) {
            $public_key->use_sha384_hash;
        }

        if ( $alg eq "RS512" ) {
            $public_key->use_sha512_hash;
        }

        return $public_key->verify( $signed_data,
            decode_base64url($signature) );
    }

    # Other algorithms not managed
    $self->logger->debug("Algorithm $alg not known");

    return 0;
}

### HERE

# Check value hash
# @param value Value
# @param hash Hash
# @param id_token ID Token
# @return boolean 1 if hash is verified, 0 else
sub verifyHash {
    my ( $self, $value, $hash, $id_token ) = @_;

    $self->logger->debug("Verification of value $value with hash $hash");

    my $jwt_header = getJWTHeader($id_token);

    # Get signature algorithm
    my $alg = $jwt_header->{alg};

    $self->logger->debug("ID Token signature algorithm: $alg");

    if ( $alg eq "none" ) {

        # Not supported
        $self->logger->debug("Cannot check hash without signature algorithm");
        return 0;
    }

    if ( $alg =~ /(?:\w{2})(\d{3})/ ) {

        # Hash Level
        my $hash_level = $1;

        $self->logger->debug("Use SHA $hash_level to check hash");

        my $cHash = $self->createHash( $value, $hash_level );

        # Compare values
        unless ( $cHash eq $hash ) {
            $self->logger->debug("Hash $hash not equal to hash $cHash");
            return 0;
        }
        return 1;
    }

    # Other algorithms not managed
    $self->logger->debug("Algorithm $alg not known");

    return 0;
}

# Create Hash
# @param value Value to hash
# @param hash_level SHA Hash level
# @return String hash
sub createHash {
    my ( $self, $value, $hash_level ) = @_;

    $self->logger->debug("Use SHA $hash_level to hash $value");

    my $hash;

    if ( $hash_level eq "256" ) { $hash = sha256($value); }
    if ( $hash_level eq "384" ) { $hash = sha384($value); }
    if ( $hash_level eq "512" ) { $hash = sha512($value); }

    $hash = substr( $hash, 0, length($hash) / 2 );
    $hash = encode_base64url( $hash, "" );

    return $hash;
}

# Create error redirection
# @param redirect_url Redirection URL
# @param error Error code
# @param error_description Human-readable ASCII encoded text description of the error
# @param error_uri URI of a web page that includes additional information about the error
# @param state OAuth 2.0 state value
# @param fragment Set to true to return fragment component
# @return void
sub returnRedirectError {
    my ( $self, $req, $redirect_url, $error, $error_description,
        $error_uri, $state, $fragment )
      = @_;

    my $urldc =
        $redirect_url
      . ( $fragment ? '#' : $redirect_url =~ /\?/ ? '&' : '?' )
      . build_urlencoded(
        error => $error,
        (
            defined $error_description
            ? ( error_description => $error_description )
            : ()
        ),
        ( defined $error_uri ? ( error_uri => $error_uri ) : () ),
        ( defined $state     ? ( state     => $state )     : () )
      );
    $req->urldc($urldc);
    return PE_REDIRECT;
}

#sub returnJSONStatus {
#my ( $self, $req, $content, $status_code ) = @_;
# replace this call by $self->p->sendJSONresponse($req,$content,code=>$status_code)

#sub returnJSONError {
#my ( $self, $error ) = @_;
#replace this by $self->p->sendError($req, $error,400);
sub sendOIDCError {
    my ( $self, $req, $err, $code, $description ) = @_;
    $code ||= 500;

    return $self->sendJSONresponse(
        $req,
        {
            error => $err,
            ( $description ? ( error_description => $description ) : () ),
        },

        code => $code
    );
}

#sub returnJSON {
#my ( $self, $content ) = @_;
#replace this call by $self->p->sendJSONresponse($req,$content)

# Return Bearer error
# @param error_code Error code
# @param error_message Error message
# @return GI response
sub returnBearerError {
    my ( $self, $error_code, $error_message ) = @_;

    my $res = [
        401,
        [
            'WWW-Authenticate' =>
              "error=$error_code,error_description=$error_message"
        ],
        []
    ];

    $self->p->setCorsHeaderFromConfig($res);

    return $res;
}

sub checkEndPointAuthenticationCredentials {
    my ( $self, $req ) = @_;

    # Check authentication
    my ( $client_id, $client_secret ) =
      $self->getEndPointAuthenticationCredentials($req);

    unless ($client_id) {
        $self->logger->error(
"No authentication provided to get token, or authentication type not supported"
        );
        return undef;
    }

    # Verify that client_id is registered in configuration
    my $rp = $self->getRP($client_id);

    unless ($rp) {
        $self->userLogger->error(
            "No registered Relying Party found with client_id $client_id");
        return undef;
    }
    else {
        $self->logger->debug("Client id $client_id match Relying Party $rp");
    }

    # Check client_secret
    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsPublic} )
    {
        $self->logger->debug(
            "Relying Party $rp is public, do not check client secret");
    }
    else {
        unless ($client_secret) {
            $self->logger->error(
"Relying Party $rp is confidential but no client secret was provided to authenticate on token endpoint"
            );
            return undef;
        }
        unless ( $client_secret eq $self->conf->{oidcRPMetaDataOptions}->{$rp}
            ->{oidcRPMetaDataOptionsClientSecret} )
        {
            $self->logger->error("Wrong credentials for $rp");
            return undef;
        }
    }
    return $rp;
}

# Get Client ID and Client Secret
# @return array (client_id, client_secret)
sub getEndPointAuthenticationCredentials {
    my ( $self, $req ) = @_;
    my ( $client_id, $client_secret );

    my $authorization = $req->authorization;
    if ( $authorization and $authorization =~ /^Basic (\w+)/i ) {
        $self->logger->debug("Method client_secret_basic used");
        eval {
            ( $client_id, $client_secret ) =
              split( /:/, decode_base64($1) );
        };
        $self->logger->error("Bad authentication header: $@") if ($@);

        # Using multiple methods is an error
        if ( $req->param('client_id') and $req->param('client_secret') ) {
            $self->logger->error("Multiple client authentication methods used");
            ( $client_id, $client_secret ) = ( undef, undef );
        }
    }
    elsif ( $req->param('client_id') and $req->param('client_secret') ) {
        $self->logger->debug("Method client_secret_post used");
        $client_id     = $req->param('client_id');
        $client_secret = $req->param('client_secret');
    }
    elsif ( $req->param('client_id') and !$req->param('client_secret') ) {
        $self->logger->debug("Method none used");
        $client_id = $req->param('client_id');
    }

    return ( $client_id, $client_secret );
}

# Get Access Token
# @return access_token
sub getEndPointAccessToken {
    my ( $self, $req ) = @_;
    my $access_token;

    my $authorization = $req->authorization;
    if ( $authorization and $authorization =~ /^Bearer ([\w\-\.]+)/i ) {
        $self->logger->debug("Bearer access token");
        $access_token = $1;
    }
    elsif ( $access_token = $req->param('access_token') ) {
        $self->logger->debug("GET/POST access token");
    }

    return $access_token;
}

# Return list of attributes authorized for a claim
# @param rp RP name
# @param claim Claim
# @return arrayref attributes list
sub getAttributesListFromClaim {
    my ( $self, $rp, $claim ) = @_;
    return $self->rpAttributes->{$rp}->{$claim};
}

# Return granted scopes for this request
# @param req current request
# @param req selected RP
# @param scope requested scope
sub getScope {
    my ( $self, $req, $rp, $scope ) = @_;

    my @scope_values = split( /\s+/, $scope );

    # Clean up unknown scopes
    if ( $self->conf->{oidcServiceAllowOnlyDeclaredScopes} ) {
        my @known_scopes = (
            keys( %{ $self->spScopeRules->{$rp} || {} } ),
            @{ OIDC_SCOPES() },
            keys(
                %{
                    $self->conf->{oidcRPMetaDataOptionsExtraClaims}->{$rp} || {}
                }
            )
        );
        my @scope_values_tmp;
        for my $scope_value (@scope_values) {
            if ( grep { $_ eq $scope_value } @known_scopes ) {
                push @scope_values_tmp, $scope_value;
            }
            else {
                $self->logger->warn(
                    "Unknown scope $scope_value requested for service $rp");
            }
        }
        @scope_values = @scope_values_tmp;
    }

    # If this RP has dynamic scopes
    if ( $self->spScopeRules->{$rp} ) {

        # Add dynamic scopes
        for my $dynamicScope ( keys %{ $self->spScopeRules->{$rp} } ) {

            # Set a magic "$requested" variable that contains true if the
            # scope was requested by the application
            my $requested  = grep { $_ eq $dynamicScope } @scope_values;
            my $attributes = { %{ $req->userData }, requested => $requested };

            # If scope is granted by the rule
            if ( $self->spScopeRules->{$rp}->{$dynamicScope}
                ->( $req, $attributes ) )
            {
                # Add to list
                unless ( grep { $_ eq $dynamicScope } @scope_values ) {
                    push @scope_values, $dynamicScope;
                }

            }

            # Else make sure it is not granted
            else {
                @scope_values = grep { $_ ne $dynamicScope } @scope_values;
            }
        }
    }

    $self->p->processHook( $req, 'oidcResolveScope', \@scope_values, $rp );

    my $scope_str = join( ' ', @scope_values );
    $self->logger->debug("Resolved scopes: $scope_str");
    return $scope_str;
}

# Return Hash of UserInfo data
# @param scope OIDC scope
# @param rp Internal Relying Party identifier
# @param user_session_id User session identifier
# @return hashref UserInfo data
sub buildUserInfoResponseFromId {
    my ( $self, $req, $scope, $rp, $user_session_id ) = @_;
    my $session = $self->p->getApacheSession($user_session_id);

    return undef unless ($session);
    return buildUserInfoResponse( $self, $req, $scope, $rp, $session );
}

# Return Hash of UserInfo data
# @param scope OIDC scope
# @param rp Internal Relying Party identifier
# @param session SSO or offline session
# @return hashref UserInfo data
sub buildUserInfoResponse {
    my ( $self, $req, $scope, $rp, $session ) = @_;
    return $self->buildUserInfoResponseFromData( $req, $scope, $rp,
        $session->data );
}

# Return Hash of UserInfo data
# @param scope OIDC scope
# @param rp Internal Relying Party identifier
# @param sessionInfo hash of session data
# @return hashref UserInfo data
sub buildUserInfoResponseFromData {
    my ( $self, $req, $scope, $rp, $session_data ) = @_;
    my $userinfo_response = {};

    my $data = {
        %{$session_data},
        _clientId => $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID},
        _clientConfKey => $rp,
        _scope         => $scope,
    };
    my $user_id = $self->getUserIDForRP( $req, $rp, $data );

    $self->logger->debug("Found corresponding user: $user_id");

    $userinfo_response->{sub} = $user_id;

    # Parse scope and return allowed attributes
    foreach my $claim ( split( /\s/, $scope ) ) {
        next if ( $claim eq "openid" );
        $self->logger->debug("Get attributes linked to claim $claim");
        my $list = $self->getAttributesListFromClaim( $rp, $claim );
        next unless $list;
        foreach my $attribute (@$list) {
            my @attrConf = split /;/,
              ( $self->conf->{oidcRPMetaDataExportedVars}->{$rp}->{$attribute}
                  || "" );
            my $session_key = $attrConf[0];
            if ($session_key) {
                my $type  = $attrConf[1] || 'string';
                my $array = $attrConf[2] || 'auto';

                my $session_value;

                # Lookup attribute in macros first
                if ( $self->spMacros->{$rp}->{$session_key} ) {
                    $session_value =
                      $self->spMacros->{$rp}->{$session_key}->( $req, $data );

                    # If not found, search in session
                }
                else {
                    $session_value = $data->{$session_key};
                }

                # Handle empty values, arrays, type, etc.
                $session_value =
                  $self->_formatValue( $session_value, $type, $array,
                    $attribute, $req->user );

             # From this point on, do NOT touch $session_value or you will break
             # the variable's type.

                # Only release claim if it has a value
                if ( defined $session_value ) {

                    # Address is a JSON object
                    if ( $claim eq "address" ) {
                        $userinfo_response->{address}->{$attribute} =
                          $session_value;
                    }
                    else {
                        $userinfo_response->{$attribute} = $session_value;
                    }
                }
            }
        }
    }

    my $h = $self->p->processHook( $req, 'oidcGenerateUserInfoResponse',
        $userinfo_response, $rp, $data );
    return {} if ( $h != PE_OK );

    return $userinfo_response;
}

sub _formatValue {
    my ( $self, $session_value, $type, $array, $attribute, $user ) = @_;

    # If $session_value is not a scalar, return it as is
    unless ( ref($session_value) ) {
        if ( defined $session_value ) {

            # Empty strings or lists are invalid values
            if ( length($session_value) > 0 ) {

                # Format value for JSON output: multi valuation, JSON type...
                my $separator = $self->conf->{multiValuesSeparator};
                return $self->_applyType( $session_value, $separator, $type,
                    $array, $attribute, $user );
            }
            else {
                return undef;
            }
        }
    }
    return $session_value;
}

sub _applyType {
    my ( $self, $session_value, $separator, $type, $array, $attribute, $user )
      = @_;

    # Array style handling
    # In auto array mode, split as array only if there are multiple values
    if ( $array eq "auto" ) {
        if ( $session_value and $session_value =~ /$separator/ ) {
            $session_value = [
                map { $self->_forceType( $_, $type ) }
                  split( $separator, $session_value )
            ];
        }
        else {
            $session_value = $self->_forceType( $session_value, $type );
        }

        # In always array mode, always split (even on empty values)
    }
    elsif ( $array eq "always" ) {
        $session_value = [
            map { $self->_forceType( $_, $type ) }
              split( $separator, $session_value )
        ];
    }

    # In never array mode, return the string as-is
    else {
        # No type coaxing is possible on a flattened string
        if ( $session_value =~ /$separator/ and $type ne "string" ) {
            $self->logger->warn( "Cannot force type of value $session_value"
                  . " for attribute $attribute of user "
                  . $user
                  . " because it is multi-valued. "
                  . "Use auto or always as array type for this attribute" );
        }
        else {
            $session_value = $self->_forceType( $session_value, $type );
        }
    }

    return $session_value;
}

sub _forceType {
    my ( $self, $val, $type ) = @_;

    # Boolean
    return ( $val ? JSON::true : JSON::false ) if ( $type eq "bool" );

    # Coax into int
    return ( $val + 0 ) if ( $type eq "int" );

    # Coax into string
    return ( $val . "" );
}

# Return JWT
# @param payload JWT content
# @param alg Signature algorithm
# @param rp Internal Relying Party identifier
# @return String jwt JWT
sub createJWT {
    my ( $self, $payload, $alg, $rp, $type ) = @_;

    # Payload encoding
    my $jwt_payload = encode_base64url( to_json($payload), "" );

    # JWT header
    my $typ             = $type || "JWT";
    my $jwt_header_hash = { typ => $typ, alg => $alg };
    if ( $alg eq "RS256" or $alg eq "RS384" or $alg eq "RS512" ) {
        $jwt_header_hash->{kid} = $self->conf->{oidcServiceKeyIdSig}
          if $self->conf->{oidcServiceKeyIdSig};
    }
    my $jwt_header = encode_base64url( to_json($jwt_header_hash), "" );

    if ( $alg eq "none" ) {

        return $jwt_header . "." . $jwt_payload;
    }

    if ( $alg eq "HS256" or $alg eq "HS384" or $alg eq "HS512" ) {

        # Sign with client secret
        my $client_secret =
          $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsClientSecret};
        unless ($client_secret) {
            $self->logger->error(
                "Algorithm $alg needs a Client Secret to sign JWT");
            return;
        }

        my $digest;

        if ( $alg eq "HS256" ) {
            $digest = hmac_sha256_base64( $jwt_header . "." . $jwt_payload,
                $client_secret );
        }

        if ( $alg eq "HS384" ) {
            $digest = hmac_sha384_base64( $jwt_header . "." . $jwt_payload,
                $client_secret );
        }

        if ( $alg eq "HS512" ) {
            $digest = hmac_sha512_base64( $jwt_header . "." . $jwt_payload,
                $client_secret );
        }

        # Convert + and / to get Base64 URL valid (RFC 4648)
        $digest =~ s/\+/-/g;
        $digest =~ s/\//_/g;
        $digest =~ s/=+$//g;

        return $jwt_header . "." . $jwt_payload . "." . $digest;
    }

    elsif ( $alg eq "RS256" or $alg eq "RS384" or $alg eq "RS512" ) {

        # Get signing private key
        my $priv_key = $self->conf->{oidcServicePrivateKeySig};
        unless ($priv_key) {
            $self->logger->error(
                "Algorithm $alg needs a Private Key to sign JWT");
            return;
        }

        my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($priv_key);

        if ( $alg eq "RS256" ) {
            $rsa_priv->use_sha256_hash;
        }

        if ( $alg eq "RS384" ) {
            $rsa_priv->use_sha384_hash;
        }

        if ( $alg eq "RS512" ) {
            $rsa_priv->use_sha512_hash;
        }

        my $digest = encode_base64url(
            $rsa_priv->sign( $jwt_header . "." . $jwt_payload ) );

        return $jwt_header . "." . $jwt_payload . "." . $digest;
    }

    $self->logger->debug("Algorithm $alg not supported to sign JWT");

    return;
}

# Return ID Token
# @param payload ID Token content
# @param rp Internal Relying Party identifier
# @return String id_token ID Token as JWT
sub createIDToken {
    my ( $self, $req, $payload, $rp ) = @_;

    # Get signature algorithm
    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
    $self->logger->debug("ID Token signature algorithm: $alg");

    my $h = $self->p->processHook( $req, 'oidcGenerateIDToken', $payload, $rp );
    return undef if ( $h != PE_OK );

    return $self->createJWT( $payload, $alg, $rp );
}

# Return flow type
# @param response_type Response type
# @return String flow
sub getFlowType {
    my ( $self, $response_type ) = @_;

    return {
        "code"                => "authorizationcode",
        "id_token"            => "implicit",
        "id_token token"      => "implicit",
        "code id_token"       => "hybrid",
        "code token"          => "hybrid",
        "code id_token token" => "hybrid",
    }->{$response_type};
}

# Return sub field of an ID Token
# @param id_token ID Token
# @return String sub
sub getIDTokenSub {
    my ( $self, $id_token ) = @_;
    my $payload = getJWTPayload($id_token);
    return $payload->{sub};
}

# Return JWKS representation of a key
# @param key Raw key
# @return HashRef JWKS key
sub key2jwks {
    my ( $self, $key ) = @_;

    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($key);
    my @params  = $rsa_pub->get_key_parameters();

    return {
        n => encode_base64url( $params[0]->to_bin(), "" ),
        e => encode_base64url( $params[1]->to_bin(), "" ),
    };
}

# Build Logout Request URI
# @param redirect_uri Redirect URI
# @param id_token_hint ID Token
# @param post_logout_redirect_uri Callback URI
# @param state State
# return String Logout URI
sub buildLogoutRequest {
    my ( $self, $redirect_uri, @args ) = @_;

    my @tab = (qw(id_token_hint post_logout_redirect_uri state));
    my @prms;
    for ( my $i = 0 ; $i < 3 ; $i++ ) {
        push @prms, $tab[$i], $args[$i]
          if defined( $args[$i] );
    }
    my $response_url = $redirect_uri;
    $response_url .=
      ( $response_url =~ /\?/ ? '&' : '?' ) . build_urlencoded(@prms)
      if (@prms);
    return $response_url;
}

# Build Logout Response URI
# @param redirect_uri Redirect URI
# @param state State
# return String Logout URI
sub buildLogoutResponse {
    my ( $self, $redirect_uri, $state ) = @_;

    my $response_url = $redirect_uri;

    if ($state) {
        $response_url .= ( $redirect_uri =~ /\?/ ? '&' : '?' );
        $response_url .= build_urlencoded( state => $state );
    }

    return $response_url;
}

# Create session_state parameter
# @param session_id Session ID
# @param client_id Client ID
# return String Session state
sub createSessionState {
    my ( $self, $session_id, $client_id ) = @_;

    my $salt =
      encode_base64url( $self->conf->{cipher}->encrypt($client_id) );
    my $data = $client_id . " " . $session_id . " " . $salt;

    my $hash = sha256_base64($data);
    while ( length($hash) % 4 ) {
        $hash .= '=';
    }

    my $session_state = $hash . "." . $salt;

    return $session_state;
}

# Get request JWT from request uri
# @param request_uri request uri
# return String request JWT
sub getRequestJWT {
    my ( $self, $request_uri ) = @_;

    my $response = $self->ua->get($request_uri);

    if ( $response->is_error ) {
        $self->logger->error("Unable to get request JWT on $request_uri");
        return;
    }

    return $response->decoded_content;
}

sub addRouteFromConf {
    my ( $self, $type, %subs ) = @_;
    my $adder = "add${type}Route";
    foreach ( keys %subs ) {
        my $sub  = $subs{$_};
        my $path = $self->conf->{$_};
        unless ($path) {
            $self->logger->error("$_ parameter not defined");
            next;
        }
        $self->$adder(
            $self->path => { $path => $sub },
            [ 'GET', 'POST' ]
        );
    }
}

# Validate PKCE code challenge with given code challenge method
# @param code_verifier
# @param code_challenge
# @param code_challenge_method
# @return boolean 1 if challenge succeed, 0 else
sub validatePKCEChallenge {
    my ( $self, $code_verifier, $code_challenge, $code_challenge_method ) = @_;

    unless ($code_verifier) {
        $self->logger->error("PKCE required but no code verifier provided");
        return 0;
    }

    $self->logger->debug("PKCE code verifier received: $code_verifier");

    if ( !$code_challenge_method or $code_challenge_method eq "plain" ) {
        if ( $code_verifier eq $code_challenge ) {
            $self->logger->debug("PKCE challenge validated (plain method)");
            return 1;
        }
        else {
            $self->logger->error("PKCE challenge failed (plain method)");
            return 0;
        }
    }

    elsif ( $code_challenge_method eq "S256" ) {
        my $code_verifier_hashed = encode_base64url( sha256($code_verifier) );
        if ( $code_verifier_hashed eq $code_challenge ) {
            $self->logger->debug("PKCE challenge validated (S256 method)");
            return 1;
        }
        else {
            $self->logger->error("PKCE challenge failed (S256 method)");
            return 0;
        }
    }

    else {
        $self->logger->error("PKCE challenge method not valid");
        return 0;
    }

    return 0;
}

sub force_id_claims {
    my ( $self, $rp ) = @_;
    return $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenForceClaims};
}

# https://openid.net/specs/openid-connect-core-1_0.html#IDToken
# Audience(s) that this ID Token is intended for. It MUST contain the OAuth 2.0
# client_id of the Relying Party as an audience value. It MAY also contain
# identifiers for other audiences. In the general case, the aud value is an
# array of case sensitive strings. In the common special case when there is one
# audience, the aud value MAY be a single case sensitive string.
sub getAudiences {
    my ( $self, $rp ) = @_;

    my $client_id = $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID};
    my @addAudiences = split /\s+/,
      ( $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsAdditionalAudiences}
          || '' );

    my $result = [$client_id];
    push @{$result}, @addAudiences;

    return $result;
}

# Returns the main attribute (sub) to use for this RP
# It can be a session attribute, or per-RP macro
sub getUserIDForRP {
    my ( $self, $req, $rp, $data ) = @_;

    my $user_id_attribute =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserIDAttr}
      || $self->conf->{whatToTrace};

    # If the main attribute is a SP macro, resolve it
    # else, get it directly from session data
    return $self->spMacros->{$rp}->{$user_id_attribute}
      ? $self->spMacros->{$rp}->{$user_id_attribute}->( $req, $data )
      : $data->{$user_id_attribute};
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Lib::OpenIDConnect - Common OpenIDConnect functions

=head1 SYNOPSIS

use Lemonldap::NG::Portal::Lib::OpenIDConnect;

=head1 DESCRIPTION

This module contains common methods for OpenIDConnect authentication
and user information loading

=head1 METHODS

=head2 loadOPs

Load OpenID Connect Providers and JWKS data

=head2 loadRPs

Load OpenID Connect Relying Parties

=head2 refreshJWKSdata

Refresh JWKS data if needed

=head2 getRP

Get Relying Party corresponding to a Client ID

=head2 getCallbackUri

Compute callback URI

=head2 buildAuthorizationCodeAuthnRequest

Build Authentication Request URI for Authorization Code Flow

=head2 buildAuthorizationCodeAuthnResponse

Build Authentication Response URI for Authorization Code Flow

=head2 buildImplicitAuthnResponse

Build Authentication Response URI for Implicit Flow

=head2 buildHybridAuthnResponse

Build Authentication Response URI for Hybrid Flow

=head2 getAuthorizationCodeAccessToken

Get Token response with authorization code

=head2 checkTokenResponseValidity

Check validity of Token Response

=head2 getUserInfo

Get UserInfo response

=head2 decodeJSON

Convert JSON to HashRef

=head2 newAuthorizationCode

Generate new Authorization Code session

=head2 newAccessToken

Generate new Access Token session

=head2 newRefreshToken

Generate new Refresh Token session

=head2 getAuthorizationCode

Get existing Authorization Code session

=head2 getAccessToken

Get existing Access Token session

=head2 getRefreshToken

Get existing Refresh Token session

=head2 getOpenIDConnectSession

Try to recover the OpenID Connect session corresponding to id and return session

=head2 storeState

Store information in state database and return

=head2 extractState

Extract state information into $self

=head2 verifyJWTSignature

Check signature of a JWT

=head2 verifyHash

Check value hash

=head2 createHash

Create Hash

=head2 returnBearerError

Return Bearer error

=head2 getEndPointAuthenticationCredentials

Get Client ID and Client Secret

=head2 getEndPointAccessToken

Get Access Token

=head2 getAttributesListFromClaim

Return list of attributes authorized for a claim

=head2 buildUserInfoResponseFromId

Return Hash of UserInfo data from session ID

=head2 buildUserInfoResponse

Return Hash of UserInfo data from session object

=head2 createJWT

Return JWT

=head2 createIDToken

Return ID Token

=head2 getFlowType

Return flow type

=head2 getIDTokenSub

Return sub field of an ID Token

=head2 getJWTJSONData

Return payload of a JWT as Hash ref

=head2 key2jwks

Return JWKS representation of a key

=head2 buildLogoutRequest

Build Logout Request URI

=head2 buildLogoutResponse

Build Logout Response URI 

=head2 addRouteFromConf

Build a Lemonldap::NG::Common::PSGI::Router route from OIDC configuration
attribute

=head2 validatePKCEChallenge

Validate PKCE code challenge with given code challenge method

=head1 SEE ALSO

L<Lemonldap::NG::Portal::AuthOpenIDConnect>, L<Lemonldap::NG::Portal::UserDBOpenIDConnect>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
