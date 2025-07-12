## @file
# Common OpenID Connect functions

## @class
# Common OpenID Connect functions
package Lemonldap::NG::Portal::Lib::OpenIDConnect;

use strict;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Crypt::JWT  qw(encode_jwt decode_jwt);
use Digest::SHA qw/sha1 hmac_sha256_base64 sha256 sha384 sha512 sha256_base64/;
use JSON;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::OpenIDConnect::Constants;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::JWT
  qw(getAccessTokenSessionId getJWTPayload getJWTHeader getJWTSignature getJWTSignedData);
use MIME::Base64
  qw/encode_base64 decode_base64 encode_base64url decode_base64url/;
use Scalar::Util qw/looks_like_number/;
use URI;
use URI::QueryParam;
use Mouse;
use Crypt::URandom;
use URI;

use Lemonldap::NG::Portal::Main::Constants
  qw(PE_OK PE_REDIRECT PE_ERROR portalConsts);

our $VERSION = '2.21.1';

use constant oidcErrorLevel => {
    server_error     => 'error',
    invalid_request  => 'warn',
    consent_required => 'notice',
};

# PROPERTIES

has opAttributes => ( is => 'rw', default => sub { {} } );
has opMetadata   => ( is => 'rw', default => sub { {} }, );
has opOptions    => ( is => 'rw', default => sub { {} }, );
has opRules      => ( is => 'rw', default => sub { {} } );
has rpAttributes => ( is => 'rw', default => sub { {} }, );
has rpMacros     => ( is => 'rw', default => sub { {} } );
has rpOptions    => ( is => 'rw', default => sub { {} }, );
has rpRules      => ( is => 'rw', default => sub { {} } );
has rpLevelRules => ( is => 'rw', default => sub { {} } );
has rpScopes     => ( is => 'rw', default => sub { {} } );
has rpScopeRules => ( is => 'rw', default => sub { {} } );
has rpEncKey     => ( is => 'rw', default => sub { {} } );
has rpSigKey     => ( is => 'rw', default => sub { {} } );

# Deprecated names, remove in 3.0
*oidcOPList   = \&opMetadata;
*oidcRPList   = \&rpOptions;
*spMacros     = \&rpMacros;
*spRules      = \&rpRules;
*spScopeRules = \&rpScopeRules;

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

has state_ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott = $_[0]->{p}->loadModule('::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{oidcRPStateTimeout}
              || $_[0]->conf->{timeout} );
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
            $self->opMetadata->{$_}->{conf} = $op_conf;
            $self->opMetadata->{$_}->{jwks} =
              $self->decodeJSON( $self->conf->{oidcOPMetaDataJWKS}->{$_} );
        }
        else {
            $self->logger->warn("Could not parse OIDC metadata for $_");
        }
    }

    # Set rule
    foreach ( keys %{ $self->conf->{oidcOPMetaDataOptions} } ) {
        $self->opAttributes->{$_} =
          $self->conf->{oidcOPMetaDataExportedVars}->{$_};
        $self->opOptions->{$_} = $self->conf->{oidcOPMetaDataOptions}->{$_};
        my $cond =
          $self->opOptions->{$_}->{oidcOPMetaDataOptionsResolutionRule};
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

# Load a single RP from LLNG configuration
sub load_rp_from_llng_conf {
    my ( $self, $rp ) = @_;

    return $self->load_rp(
        confKey     => $rp,
        extraClaims => $self->conf->{oidcRPMetaDataOptionsExtraClaims}->{$rp},
        options     => $self->conf->{oidcRPMetaDataOptions}->{$rp},
        macros      => $self->conf->{oidcRPMetaDataMacros}->{$rp},
        scopeRules  => $self->conf->{oidcRPMetaDataScopeRules}->{$rp},
        attributes  => $self->conf->{oidcRPMetaDataExportedVars}->{$rp},
    );
}

sub load_rp {
    my ( $self, %config ) = @_;
    my $rp = $config{confKey};

    my $valid = 1;

    # Handle scopes
    # this HAS to be a deep copy of the DEFAULT_SCOPES hashref!
    my $scope_values = { %{ DEFAULT_SCOPES() } };

    # Additional claims
    my $extraClaims = $config{extraClaims};
    if ($extraClaims) {
        $self->logger->debug("Processing extra claims for RP $rp...");
        foreach my $scope ( keys %$extraClaims ) {
            $self->logger->debug("Processing scope value $scope for RP $rp...");
            my @extraAttributes = split( /\s/, $extraClaims->{$scope} );
            $scope_values->{$scope} = \@extraAttributes;
        }
    }

    # Access rule
    my $rule = $config{options}->{oidcRPMetaDataOptionsRule};
    if ( length $rule ) {
        $self->logger->debug("Processing access rule for RP $rp...");
        $rule = $self->p->buildRule( $rule, "access rule for RP $rp" );
        unless ($rule) {
            $valid = 0;
        }
    }

    # Required authentication level rule
    my $levelrule = $config{options}->{oidcRPMetaDataOptionsAuthnLevel} || 0;
    $levelrule = $self->p->buildRule( $levelrule,
        "required authentication level rule for RP $rp" );
    unless ($levelrule) {
        $valid = 0;
    }

    # Load per-RP macros
    my $macros         = $config{macros};
    my $compiledMacros = {};
    for my $macroAttr ( keys %{$macros} ) {
        my $macroRule = $macros->{$macroAttr};
        if ( length $macroRule ) {
            $self->logger->debug("Processing macros for RP $rp...");
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
    my $scope_rules          = $config{scopeRules};
    my $compiled_scope_rules = {};
    for my $scopeName ( keys %{$scope_rules} ) {
        my $scopeRule = $scope_rules->{$scopeName};
        if ( length $scopeRule ) {
            $self->logger->debug("Processing dynamic scopes for RP $rp...");
            $scopeRule = $self->p->HANDLER->substitute($scopeRule);
            if ( $scopeRule = $self->p->HANDLER->buildSub($scopeRule) ) {
                $compiled_scope_rules->{$scopeName} = $scopeRule;
            }
            else {
                $self->logger->error(
                    "Unable to build scope $scopeName for RP $rp:"
                      . $self->p->HANDLER->tsv->{jail}->error );
                $valid = 0;
            }
        }
    }
    if (
        $valid
        and (  $config{options}->{oidcRPMetaDataOptionsJwksUri}
            or $config{options}->{oidcRPMetaDataOptionsJwks} )
      )
    {
        $self->logger->debug("Processing JWKS options for RP $rp...");
        my $jwks = $config{options}->{oidcRPMetaDataOptionsJwks};
        $jwks = $self->decodeJSON($jwks) if $jwks and not ref $jwks;

        if ( !$jwks
            and my $url = $config{options}->{oidcRPMetaDataOptionsJwksUri} )
        {
            $self->logger->debug("Fetching JWKS URL: $url for RP $rp");
            my $resp = $self->ua->get($url);
            if ( $resp->is_success ) {
                my $content = $self->decodeJSON( $resp->decoded_content );
                if ( $content and ref($content) eq 'HASH' and $content->{keys} )
                {
                    $jwks = $content;
                }
                else {
                    $self->logger->error("Invalid response from $url");
                    $valid = 0;
                }
            }
            else {
                $self->logger->error( "Unable to fetch RP keys from $url: "
                      . $resp->status_line );
                $valid = 0;
            }
        }
        if ( $jwks and ref($jwks) eq 'HASH' and $jwks->{keys} ) {
            $self->logger->debug("Processing JWKS document for RP $rp");
            my %keys;
            my %validKeys;
            foreach my $key ( sort @{ $jwks->{keys} } ) {
                my $type = lc( $key->{use} );
                next unless $type =~ /^(?:enc|sig)$/;
                $key->{alg} = 'RSA-OAEP'
                  if !$key->{alg} and $key->{kty} eq 'RSA';
                $key->{alg} = 'ES256'
                  if !$key->{alg} and $key->{kty} eq 'EC';
                if ( $type eq 'sig' ) {
                    push @{ $validKeys{sig} }, $key;
                }
                if ( $key->{alg} ) {
                    $keys{ $key->{alg} } ||= $key;
                }
                else {
                    $self->logger->warn('Unable to find "alg" field in RP key');
                }
            }
            foreach my $alg ( @{&ENC_ALG_SUPPORTED} ) {
                if ( $keys{$alg} and $keys{$alg}->{use} eq 'enc' ) {
                    $self->logger->debug(
                        "Found encryption key with algorith $alg");
                    $validKeys{enc}{$alg} = $keys{$alg};
                    last;
                }
            }
            unless (%validKeys) {
                $self->logger->error(
                    "Unable to find a supported key for RP $rp");
                $valid = 0;
            }
            else {
                $self->rpEncKey->{$rp} = { keys => $validKeys{enc} }
                  if $validKeys{enc};
                $self->rpSigKey->{$rp} = { keys => $validKeys{sig} }
                  if $validKeys{sig};
            }
        }
        else {
            $self->logger->error('Malformed JWKS document');
            $valid = 0;
        }
    }
    if ($valid) {
        $self->logger->debug(" -> RP $rp is valid");

        # Register RP
        $self->rpOptions->{$rp}    = $config{options};
        $self->rpAttributes->{$rp} = $config{attributes};
        $self->rpScopes->{$rp}     = $scope_values;
        $self->rpMacros->{$rp}     = $compiledMacros;
        $self->rpScopeRules->{$rp} = $compiled_scope_rules;
        $self->rpRules->{$rp}      = $rule;
        $self->rpLevelRules->{$rp} = $levelrule;
    }
    else {
        $self->logger->debug(" -> RP $rp is NOT valid");
        $self->logger->error(
            "Relying Party $rp has errors and will be ignored");
    }
    return;
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
        $self->refreshJWKSdataForOp($_);
    }
    return 1;
}

sub refreshJWKSdataForOp {
    my ( $self, $op, $force ) = @_;

    $self->logger->debug("Attempting to refresh JWKS data for $op");

    # Refresh JWKS data if
    # 1/ oidcOPMetaDataOptionsJWKSTimeout > 0
    # 2/ jwks_uri defined in metadata

    my $jwksTimeout =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsJWKSTimeout};
    my $jwksUri = $self->opMetadata->{$op}->{conf}->{jwks_uri};

    unless ($jwksUri) {
        $self->logger->debug("No JWKS URI defined for $op, skipping...");
        return;
    }

    if ( !$force ) {
        unless ($jwksTimeout) {
            $self->logger->debug(
                "No JWKS refresh timeout defined for $op, skipping...");
            return;
        }

        if (
            $self->opMetadata->{$op}->{jwks}->{time}
            && (
                $self->opMetadata->{$op}->{jwks}->{time} + $jwksTimeout > time )
          )
        {
            $self->logger->debug("JWKS data still valid for $op, skipping...");
            return;
        }
    }

    $self->logger->debug("Refresh JWKS data for $op from $jwksUri");

    my $response = $self->ua->get($jwksUri);

    if ( $response->is_error ) {
        $self->logger->warn(
            "Unable to get JWKS data for $op from $jwksUri: "
              . $response->message );
        $self->logger->debug( $response->content );
        return;
    }

    my $content = $self->decodeJSON( $response->decoded_content );

    $self->opMetadata->{$op}->{jwks} = $content;
    $self->opMetadata->{$op}->{jwks}->{time} = time;

    return 1;
}

# Compute callback URI
# @return String Callback URI
sub getCallbackUri {
    my ( $self, $req ) = @_;

    my $callback_get_param = $self->conf->{oidcRPCallbackGetParam};

    my $callback_uri =
      $self->p->buildUrl( $req->portal, { $callback_get_param => 1 } );

    $self->logger->debug("OpenIDConnect Callback URI: $callback_uri");
    return $callback_uri;
}

# Build Authentication Request URI for Authorization Code Flow
# @param op OpenIP Provider configuration key
# @param state State
# return String Authentication Request URI
sub buildAuthorizationCodeAuthnRequest {
    my ( $self, $req, $op, $state, $nonce ) = @_;
    my $authMode =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsAuthnEndpointAuthMethod};

    my $authorize_uri =
      $self->opMetadata->{$op}->{conf}->{authorization_endpoint};

    unless ($authorize_uri) {
        $self->logger->error(
            "Could not build Authorize request: no
            'authorization_endpoint'" . " in JSON metadata for OP $op"
        );
        return undef;
    }
    my $client_id = $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientID};
    my $scope     = $self->opOptions->{$op}->{oidcOPMetaDataOptionsScope};
    my $response_type = "code";
    my $redirect_uri  = $self->getCallbackUri($req);
    my $display       = $self->opOptions->{$op}->{oidcOPMetaDataOptionsDisplay};
    my $prompt        = $self->opOptions->{$op}->{oidcOPMetaDataOptionsPrompt};
    my $max_age       = $self->opOptions->{$op}->{oidcOPMetaDataOptionsMaxAge};
    my $ui_locales = $self->opOptions->{$op}->{oidcOPMetaDataOptionsUiLocales};
    my $acr_values = $self->opOptions->{$op}->{oidcOPMetaDataOptionsAcrValues};
    my $login_hint = $req->data->{suggestedLogin};

    my $authorize_request_oauth2_params = {
        response_type => $response_type,
        client_id     => $client_id,
        scope         => $scope,
        redirect_uri  => $redirect_uri,
        ( defined $state      ? ( state      => $state )      : () ),
        ( defined $nonce      ? ( nonce      => $nonce )      : () ),
        ( defined $login_hint ? ( login_hint => $login_hint ) : () ),
    };
    my $authorize_request_params = {
        %$authorize_request_oauth2_params,
        ( $display ? ( display => $display ) : () ),
        ( $prompt  ? ( prompt  => $prompt )  : () ),
        # MaxAge is defined as an int type in LLNG config,
        # so 0 means undefined
        ( $max_age    ? ( max_age    => $max_age )    : () ),
        (
            defined($ui_locales)
              && length($ui_locales) ? ( ui_locales => $ui_locales ) : ()
        ),
        (
            defined($acr_values)
              && length($acr_values) ? ( acr_values => $acr_values ) : ()
        )
    };

    # Call oidcGenerateAuthenticationRequest
    my $h = $self->p->processHook(
        $req, 'oidcGenerateAuthenticationRequest',
        $op,  $authorize_request_params,
    );
    return if ( $h != PE_OK );

    if ( $authMode and $authMode =~ /^jw(?:s|e)$/ ) {

        # Save hook changes if any
        $authorize_request_oauth2_params->{$_} = $authorize_request_params->{$_}
          foreach ( keys %$authorize_request_oauth2_params );
        my $aud = $authorize_uri;
        $aud =~ s#^(https://[^/]*).*?$#$1#;
        my $jwt = $self->createJWTForOP( {
                iss => $client_id,
                aud => $aud,
                jti => $self->generateNonce,
                exp => time + 30,
                iat => time,
                %$authorize_request_params,
            },
            $self->opOptions->{op}
              ->{oidcOPMetaDataOptionsAuthnEndpointAuthSigAlg} || 'RS256',
            $op
        );
        if ($jwt) {
            $authorize_request_params =
              { %$authorize_request_oauth2_params, request => $jwt };
            if ( $authMode eq 'jwe' ) {
                $self->logger->error('jwe mode not yet implemented');
            }
        }
        else {
            $self->logger->error(
                'Unable to generate JWT, continue with unauthenticated query');
        }
    }
    my $authn_uri =
        $authorize_uri
      . ( $authorize_uri =~ /\?/ ? '&' : '?' )
      . build_urlencoded(%$authorize_request_params);

    $self->logger->debug(
        "OpenIDConnect Authorization Code Flow Authn Request: $authn_uri");

    return $authn_uri;
}

sub isResponseModeAllowed {
    my ( $self, $flow, $response_mode ) = @_;

    # Query encoding can only be used for authorization code flow
    # cf oauth-v2-multiple-response-types-1_0.html
    if ( $response_mode and $response_mode eq "query" ) {
        return ( $flow eq "authorizationcode" );
    }

    # Fragment or Form Post are OK for all types
    # cf oauth-v2-form-post-response-mode-1_0.html
    return 1;
}

# Build OpenID Connect response
# This method does not check if the response mode is allowed for the current
# grant type. Use isResponseModeAllowed for that
sub sendOidcResponse {
    my ( $self, $req, $flow, $response_mode, $redirect_uri, $response_params )
      = @_;

    $response_mode //= $self->getDefaultResponseModeForFlow($flow);

    if ( $response_mode eq "query" ) {
        return $self->sendQueryResponse( $req, $redirect_uri,
            $response_params );
    }
    elsif ( $response_mode eq "fragment" ) {
        return $self->sendFragmentResponse( $req, $redirect_uri,
            $response_params );
    }
    elsif ( $response_mode eq "form_post" ) {
        return $self->sendFormPostResponse( $req, $redirect_uri,
            $response_params );
    }
    else {
        $self->logger->error("Unknown response_mode $response_mode");
        return PE_ERROR;
    }
}

sub getDefaultResponseModeForFlow {
    my ( $self, $flow ) = @_;
    my %def_flows = (
        authorizationcode => "query",
        implicit          => "fragment",
        hybrid            => "fragment",
    );
    return $def_flows{$flow};
}

sub sendQueryResponse {
    my ( $self, $req, $redirect_uri, $response_params ) = @_;
    my $response_uri =
      $self->getQueryResponse( $redirect_uri, $response_params );
    return $self->_redirectToUrl( $req, $response_uri );
}

sub sendFragmentResponse {
    my ( $self, $req, $redirect_uri, $response_params ) = @_;
    my $response_uri =
      $self->getFragmentResponse( $redirect_uri, $response_params );
    return $self->_redirectToUrl( $req, $response_uri );
}

sub getQueryResponse {
    my ( $self, $redirect_uri, $response_params ) = @_;
    my $uri = URI->new($redirect_uri);
    for ( keys %$response_params ) {
        $uri->query_param( $_, $response_params->{$_} );
    }
    return $uri;
}

sub getFragmentResponse {
    my ( $self, $redirect_uri, $response_params ) = @_;
    my $uri = URI->new($redirect_uri);

   # Use a temporary URL so we can use QueryParam features to build the fragment
    my $tmp = URI->new;
    $tmp->query( $uri->fragment );
    for ( keys %$response_params ) {
        $tmp->query_param( $_, $response_params->{$_} );
    }

    $uri->fragment( $tmp->query );

    return $uri;
}

sub sendFormPostResponse {
    my ( $self, $req, $redirect_uri, $response_params ) = @_;

    $self->p->clearHiddenFormValue($req);
    $req->postUrl($redirect_uri);
    $req->postFields($response_params);
    $req->steps( ['autoPost'] );
    return PE_OK;
}

sub _redirectToUrl {
    my ( $self, $req, $response_url ) = @_;

    # We must clear hidden form fields saved from the request (#2085)
    $self->p->clearHiddenFormValue($req);
    $self->logger->debug("Redirect user to $response_url");
    $req->urldc($response_url);

    return PE_REDIRECT;
}

# Build Authentication Response URI for Authorization Code Flow
# DEPRECATED, remove in 3.0, use sendOidcResponse instead
# @param redirect_uri Redirect URI
# @param code Code
# @param state State
# @param session_state Session state
# return String Authentication Response URI
sub buildAuthorizationCodeAuthnResponse {
    my ( $self, $redirect_uri, $code, $state, $session_state ) = @_;

    return $self->getQueryResponse(
        $redirect_uri,
        {
            code => $code,
            ( $state         ? ( state         => $state )         : () ),
            ( $session_state ? ( session_state => $session_state ) : () )
        }
    );
}

# Build Authentication Response URI for Implicit Flow
# DEPRECATED, remove in 3.0, use sendOidcResponse instead
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

    return $self->getFragmentResponse(
        $redirect_uri,
        {
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
        }
    );
}

# Build Authentication Response URI for Hybrid Flow
# DEPRECATED, remove in 3.0, use sendOidcResponse instead
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

    return $self->getFragmentResponse(
        $redirect_uri,
        {
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
        }
    );
}

sub getAccessTokenFromTokenEndpoint {
    my ( $self, $req, $op, $grant_type, $grant_options ) = @_;

    $grant_options ||= {};

    my $client_id = $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientID};
    my $client_secret =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientSecret};
    my $access_token_uri =
      $self->opMetadata->{$op}->{conf}->{token_endpoint};

    unless ($access_token_uri) {
        $self->logger->error(
            "Could not build Token request: no
            'token_endpoint'" . " in JSON metadata for OP $op"
        );
        return 0;
    }

    my $auth_method =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsTokenEndpointAuthMethod}
      || 'client_secret_post';

    unless ( $auth_method =~
        /^(?:client_secret_(?:(?:pos|jw)t|basic)|private_key_jwt)$/ )
    {
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
    else {
        if ( $auth_method eq "client_secret_post" ) {
            $token_request_params->{client_id}     = $client_id;
            $token_request_params->{client_secret} = $client_secret;
        }
        elsif ( $auth_method =~ /^(?:client_secret|private_key)_jwt$/ ) {

            # TODO: add parameter to choose alg
            my $alg =
                $auth_method eq 'client_secret_jwt'          ? 'HS256'
              : $self->conf->{oidcServiceKeyTypeSig} eq 'EC' ? 'ES256'
              :                                                'RS256';
            my $time = time;
            my $jws  = $self->createJWTForOP( {
                    iss => $client_id,
                    sub => $client_id,
                    aud => $access_token_uri,
                    jti => $self->generateNonce,
                    exp => $time + 30,
                    iat => $time,
                },
                $alg, $op
            );
            $token_request_params->{client_id} = $client_id;
            $token_request_params->{client_assertion_type} =
              'urn:ietf:params:oauth:client-assertion-type:jwt-bearer';
            $token_request_params->{client_assertion} = $jws;
        }
        else {
            $self->logger->error("Unknown auth method $auth_method");
        }
        $response = $self->ua->post( $access_token_uri, $token_request_params,
            "Content-Type" => 'application/x-www-form-urlencoded' );
    }

    if ( $response->is_error ) {
        $self->logger->error(
            "Bad token response from $op, grant_type: $grant_type, error: "
              . $response->message );
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
    my ( $self, $op, $id_token, $state_nonce ) = @_;

    my $client_id  = $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientID};
    my $acr_values = $self->opOptions->{$op}->{oidcOPMetaDataOptionsAcrValues};
    my $max_age    = $self->opOptions->{$op}->{oidcOPMetaDataOptionsMaxAge};
    my $id_token_max_age =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsIDTokenMaxAge};
    my $use_nonce = $self->opOptions->{$op}->{oidcOPMetaDataOptionsUseNonce};

    # Check issuer
    unless ( $id_token->{iss} eq $self->opMetadata->{$op}->{conf}->{issuer} ) {
        $self->logger->error("Issuer mismatch");
        return 0;
    }

    # Check audience
    if ( ref $id_token->{aud} ) {
        my @audience = @{ $id_token->{aud} };
        unless ( grep { $_ eq $client_id } @audience ) {
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
        my $id_token_nonce = $id_token->{nonce};
        unless ($id_token_nonce) {
            $self->logger->error("Nonce was not returned by OP $op");
            return 0;
        }
        else {
            # Get nonce session
            unless ( $id_token_nonce eq $state_nonce ) {
                $self->logger->error(
"Nonce $id_token_nonce verification failed, expected $state_nonce"
                );
                return 0;
            }
        }
    }

    # Check acr
    my $acr = $id_token->{acr};
    if ($acr_values) {
        unless ($acr) {
            $self->logger->error("ACR was not returned by OP $op");
            return 0;
        }
        unless ( grep { $_ eq $acr } split( /[\s,]+/, $acr_values ) ) {
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
      $self->opMetadata->{$op}->{conf}->{userinfo_endpoint};

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
        my $jwt = $self->decryptJwt($userinfo_content);
        return $self->decodeJWT( $jwt, $op );
    }
}

# Convert JSON to HashRef
# @return HashRef JSON decoded content
sub decodeJSON {
    my ( $self, $json ) = @_;
    my $json_hash;

    eval { $json_hash = from_json( $json, { allow_nonref => 1 } ); };
    return undef if ($@);
    unless ( ref $json_hash ) {
        $self->logger->error("Wanted a JSON object, got: $json_hash");
        return undef;
    }

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
        ttl => $self->rpOptions->{$rp}
          ->{oidcRPMetaDataOptionsAuthorizationCodeExpiration}
          || $self->conf->{oidcServiceAuthorizationCodeExpiration},
        info => $info
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

    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    my $at_info = {

        scope     => $scope,
        rp        => $rp,
        client_id => $client_id,
        %{$info},
    };

    my $ttl =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};
    my $session = $self->getOpenIDConnectSession(
        undef, "access_token",
        ttl  => $ttl,
        info => $at_info,
    );

    if ($session) {

        my $user = $sessionInfo->{ $self->conf->{whatToTrace} };
        $self->auditLog(
            $req,
            code    => "ISSUER_OIDC_ACCESS_TOKEN",
            rp      => $rp,
            message =>
              ("Access Token for $user generated for $rp with TTL $ttl"),
            user => $user,
            ttl  => $ttl,
        );

        if ( $self->_wantJWT($rp) ) {
            my $at_jwt =
              $self->makeJWT( $req, $rp, $scope, $session->id, $sessionInfo );
            $at_jwt = $self->encryptToken(
                $rp,
                $at_jwt,
                $self->rpOptions->{$rp}
                  ->{oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg},
                $self->rpOptions->{$rp}
                  ->{oidcRPMetaDataOptionsIdTokenEncContentEncAlg},
            );
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
    return $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenJWT};
}

sub makeJWT {
    my ( $self, $req, $rp, $scope, $id, $sessionInfo ) = @_;

    my $exp =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};
    $exp += time;
    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    my $access_token_payload = {
        iss       => $self->get_issuer($req),     # Issuer Identifier
        exp       => $exp,                        # expiration
        aud       => $self->getAudiences($rp),    # Audience
        client_id => $client_id,                  # Client ID
        iat       => time,                        # Issued time
        jti       => $id,                         # Access Token session ID
        scope     => $scope,                      # Scope
        sid       => $self->getSidFromSession( $rp, $sessionInfo ), # Session id
    };

    my $claims =
      $self->buildUserInfoResponseFromData( $req, $scope, $rp, $sessionInfo );

    # Release claims, or only sub
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenClaims} ) {
        foreach ( keys %$claims ) {
            $access_token_payload->{$_} = $claims->{$_}
              unless $access_token_payload->{$_};
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
    my $alg = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenSignAlg}
      || ( $self->conf->{oidcServiceKeyTypeSig} eq 'EC' ? 'ES256' : 'RS256' );
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
      ? (
        $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsOfflineSessionExpiration}
          || $self->conf->{oidcServiceOfflineSessionExpiration} )
      : $self->conf->{timeout};

    return $self->getOpenIDConnectSession(
        undef, "refresh_token",
        ttl  => $ttl,
        info => $info
    );
}

# Get existing Refresh Token
# @param id
# @return new Lemonldap::NG::Common::Session object

sub getRefreshToken {
    my ( $self, $id ) = @_;

    return $self->getOpenIDConnectSession( $id, "refresh_token", noCache => 1 );
}

sub updateRefreshToken {
    my $self = shift;
    return $self->updateToken(@_);
}

sub updateToken {
    my ( $self, $id, $infos ) = @_;

    my $oidcSession = Lemonldap::NG::Common::Session->new( {
            $self->_storeOpts(),
            cacheModule        => $self->conf->{localSessionStorage},
            cacheModuleOptions => $self->conf->{localSessionStorageOptions},
            hashStore          => $self->conf->{hashedSessionStore},
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
    my $self = shift;
    my $id   = shift;
    my $type = shift;

    # Check old method signature ($id, $type, $ttl, $info)
    my %opts =
        ( ( $_[0] and $_[0] =~ /^\d+$/ ) or ( $_[1] and ref $_[1] ) )
      ? ( ttl => $_[0], info => $_[1] )
      : (@_);

    $opts{ttl} ||= $self->conf->{timeout};

    my $oidcSession = Lemonldap::NG::Common::Session->new( {
            $self->_storeOpts(),
            (
                $opts{noCache} ? ()
                : (
                    cacheModule        => $self->conf->{localSessionStorage},
                    cacheModuleOptions =>
                      $self->conf->{localSessionStorageOptions}
                )
            ),
            hashStore => $opts{hashStore} // $self->conf->{hashedSessionStore},
            id        => $id,
            kind      => $self->sessionKind,
            (
                $opts{info}
                ? (
                    info => {
                        _type  => $type,
                        _utime => time + $opts{ttl} - $self->conf->{timeout},
                        %{ $opts{info} }
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
            $self->logger->notice("Session $id has expired");
            return undef;
        }
    }

    # Make sure the token is still valid, we already compensated for
    # different TTLs when storing _utime
    if ( time > ( $oidcSession->{data}->{_utime} + $self->conf->{timeout} ) ) {
        $self->logger->notice("Session $id has expired");
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
        $infos->{state}->{$_}        = $req->{$_}       if $req->{$_};
        $infos->{state}->{"data_$_"} = $req->data->{$_} if $req->data->{$_};
    }
    return unless ($infos);

    # Session type
    $infos->{_type} = "state";

    # Create state session and store infos
    return $self->state_ott->createToken($infos);
}

# Extract state information into $req
sub extractState {
    my ( $self, $req, $state ) = @_;

    return 0 unless $state;

    # Open state session
    my $stateSession = $self->state_ott->getToken($state);

    return 0 unless $stateSession;
    return 0 unless $stateSession->{_type} eq "state";
    return 0 unless $stateSession->{state};

    # Push values in $self
    foreach ( keys %{ $stateSession->{state} } ) {
        my $tmp = $stateSession->{state}->{$_};
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
sub decodeJWT {
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
            return;
        }
        $self->logger->debug(
            "JWT algorithm is 'none', signature cannot be verified");
        return;
    }

    my $jwks;
    if ($op) {

        # Always refresh JWKS if timeout has elapsed
        $self->refreshJWKSdataForOp($op);

        my $kid = $jwt_header->{kid};

        # If the JWT is signed by an unknown kid, force a refresh
        if (
            $kid
            and !$self->_kid_found_in_jwks(
                $kid, $self->opMetadata->{$op}->{jwks}
            )
          )
        {
            $self->logger->debug(
                "Key ID $kid not found in current JWKS, forcing JWKS refresh");
            $self->refreshJWKSdataForOp( $op, 1 );
        }

        $jwks = $self->opMetadata->{$op}->{jwks};
    }
    else {
        $jwks = $self->rpSigKey->{$rp};
    }

    unless ( $alg =~ /^HS/ ) {
        unless ($jwks) {
            $self->logger->error(
                "Cannot verify $alg signature: no JWKS data found");
            return;
        }
        unless ( $jwks->{keys}
            and ref( $jwks->{keys} ) eq 'ARRAY'
            and @{ $jwks->{keys} } )
        {
            $self->logger->error('Malformed JWKS, I need {"keys":[..keys..]}');
            return;
        }
    }

    # Choosing keys
    #  - if algorithm is HS{digits}, the key is the ClientSecret
    #  - if JWS has a "kid" field in its header, use it (then replace the
    #    "key" arg of Crypt::JWT by "kid_keys" and give the whole JWKS)
    #  - else we try the first available key of jwks document
    my @keyArgs;
    if ( $alg =~ /^HS/ ) {
        $self->logger->debug("Alg is $alg, using secret as key");
        @keyArgs = ( [
                key => $op
                ? $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientSecret}
                : $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientSecret}
            ]
        );
    }
    elsif ( $jwt_header->{kid} ) {
        $self->logger->debug(
            "'kid' found in JWT header, using the whole JWKS doc as 'kid_keys'"
        );
        @keyArgs = ( [ kid_keys => $jwks ] );
    }
    else {
        $self->logger->debug(
"No 'kid' found in JWT header, will try all keys found in JWKS doc ("
              . @{ $jwks->{keys} }
              . ' key(s))' );
        @keyArgs = map { [ key => $_ ] } @{ $jwks->{keys} };
    }

    my $error = [];
    my $content;
    foreach my $keyArg (@keyArgs) {

        # JSON decoding is done here because #2748
        $content = eval {
            JSON::from_json(
                decode_jwt( token => $jwt, @$keyArg, decode_payload => 0 ) );
        };
        if ($@) {
            $error = [ "Unable to verify JWT: $@", "Jwt was: $jwt" ];
        }
        else {
            $error = [];
            last;
        }
    }
    if (@$error) {
        $self->logger->error($_) foreach @$error;
        return;
    }
    return wantarray ? ( $content, $alg ) : $content;
}

sub _kid_found_in_jwks {
    my ( $self, $kid, $jwks ) = @_;

    return 0 if !$kid;

    my @keys = $jwks ? @{ $jwks->{keys} // [] } : ();

    my @found = grep { $_->{kid} and $_->{kid} eq $kid } @keys;

    return @found > 0;
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

    my $reason = $error_description ? ": $error_description" : "";
    $self->auditLog(
        $req,
        code    => "ISSUER_OIDC_LOGIN_FAILED",
        message => ( "OIDC login failed" . $reason ),
        ( $error_description ? ( reason => $error_description ) : () ),
        oauth_error  => $error,
        portal_error => portalConsts->{PE_REDIRECT},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

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

sub invalidClientResponse {
    my ( $self, $req ) = @_;
    if ( $req->authorization ) {
        my ($method) = $req->authorization =~ qw/^(\w+) /;
        if ($method) {
            $req->respHeaders( [ 'WWW-Authenticate' => $method ] );
            return $self->sendOIDCError( $req, 'invalid_client', 401 );
        }
    }
    else {
        return $self->sendOIDCError( $req, 'invalid_client', 400 );
    }
}

sub checkEndPointAuthenticationCredentials {
    my ( $self, $req ) = @_;

    # Check authentication
    my ( $client_id, $client_secret, $method ) =
      $self->getEndPointAuthenticationCredentials($req);

    $self->logger->debug("Authentication method: $method");

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
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsPublic} ) {
        $self->logger->debug(
            "Relying Party $rp is public, do not check client secret");
    }
    else {
        if ( $method eq "none" ) {
            $self->logger->error(
                "Relying Party $rp is confidential but no known method was used"
                  . " to authenticate on token endpoint" );
            return undef;
        }
        if ( $method =~ /^client_secret_(?:basic|post)$/ ) {
            unless ($client_secret) {
                $self->logger->error(
"Relying Party $rp is confidential but no client secret was provided to authenticate on token endpoint"
                );
                return undef;
            }
            unless ( $client_secret eq
                $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientSecret} )
            {
                $self->logger->error("Wrong credentials for $rp");
                return undef;
            }
        }

        if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthMethod} ) {
            unless ( $method eq
                $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthMethod} )
            {
                $self->logger->error("Wrong authetication method for $rp");
                return undef;
            }
        }
    }
    $self->p->HANDLER->set_user( $req,
        $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID} );
    return ( $rp, $method );
}

# Get Client ID and Client Secret
# @return array (client_id, client_secret)
sub getEndPointAuthenticationCredentials {
    my ( $self, $req ) = @_;
    my ( $client_id, $client_secret, $scheme );

    my $authorization = $req->authorization;
    if ( $authorization and $authorization =~ m#^Basic ([[:alnum:]+/=]+)#i ) {
        $scheme = 'client_secret_basic';
        $self->logger->debug("Method client_secret_basic used");
        eval {
            ( $client_id, $client_secret ) =
              split( ':', decode_base64($1), 2 );
        };
        $self->logger->error("Bad authentication header: $@") if ($@);

        # Using multiple methods is an error
        if (
            ( $req->param('client_id') and $req->param('client_secret') )
            or (    $req->param('client_assertion')
                and $req->param('client_assertion_type') )
          )
        {
            $self->logger->error("Multiple client authentication methods used");
            ( $client_id, $client_secret ) = ( undef, undef );
        }
    }

    # JWS authentication
    elsif ( my $atype = $req->param('client_assertion_type')
        and my $jws = $req->param('client_assertion')
        and my $_clientId = $req->param('client_id') )
    {
        # Type must be 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        if (
            $atype eq 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer' )
        {
            # JWS token must contain iss, sub and iss must be equal to usb
            my $payload = getJWTPayload($jws);
            if (    $payload
                and ( ref($payload) eq 'HASH' )
                and $payload->{iss}
                and $payload->{sub}
                and $payload->{iss} eq $payload->{sub}
                and $payload->{iss} eq $_clientId )
            {
                # client_id must match to a known relying party
                my $rp = $self->getRP($_clientId);
                if ($rp) {

                    # RP must have a signature key registered
                    # (key may be the secret for HS* alg)
                    if (   $self->rpSigKey->{$rp}
                        or $self->rpOptions->{$rp}
                        ->{oidcRPMetaDataOptionsClientSecret} )
                    {

                        # Signature must be valid
                        my ( $jwt, $alg ) =
                          $self->decodeJWT( $jws, undef, $rp );
                        if ($jwt) {

                            $scheme =
                              $alg =~ /^HS/i
                              ? 'client_secret_jwt'
                              : 'private_key_jwt';

                            # Token must be time-valid
                            if ( $jwt->{aud} and $jwt->{exp} ) {
                                if ( time < $jwt->{exp} ) {
                                    $self->logger->debug("JWS is valid");

                                    # Then export the client_id !
                                    $client_id = $_clientId;
                                }
                                else {
                                    $self->logger->error('JWS expired');
                                }
                            }
                            else {
                                $self->logger->error(
                                    'Bad JWS content (missing aud or exp)');
                            }
                        }
                        else {
                            $self->logger->error('Bad JWS signature');
                        }
                    }
                    else {
                        $self->logger->error("No signature key found for $rp");
                    }
                }
                else {
                    $self->logger->error(
                        "Unable to find any RP with client_id=$_clientId");
                }
            }
            else {
                $self->logger->error("Bad JWS payload: $jws");
            }
        }
        else {
            $self->logger->error("Unsuported client_assertion_type $atype");
        }
    }
    elsif ( $req->param('client_id')
        and $req->body_parameters->{client_secret} )
    {
        $scheme = 'client_secret_post';
        $self->logger->debug("Method client_secret_post used");
        $client_id     = $req->param('client_id');
        $client_secret = $req->param('client_secret');
    }
    elsif ( $req->param('client_id') ) {
        $scheme = 'none';
        $self->logger->debug("Method none used");
        $client_id = $req->param('client_id');
    }

    return ( $client_id, $client_secret, $scheme );
}

# Get Access Token
# @return access_token
sub getEndPointAccessToken {
    my ( $self, $req ) = @_;
    my ( $access_token, $method );

    my $authorization = $req->authorization;
    if ( $authorization and $authorization =~ /^Bearer ([\w\-\.]+)/i ) {
        $self->logger->debug("Bearer access token");
        $access_token = $1;
        $method       = 'header';
    }
    elsif ( $access_token = $req->param('access_token') ) {
        $self->logger->debug("GET/POST access token");
        $method = 'param';
    }

    return wantarray ? ( $access_token, $method ) : $access_token;
}

# DEPRECATED, remove in 3.0, use getAttributeListFromScopeValue instead
sub getAttributesListFromClaim {
    my ( $self, $rp, $scope_value ) = @_;
    return $self->getAttributesListFromScopeValue( $rp, $scope_value );
}

# Return list of attributes authorized for a claim
# @param rp RP name
# @param claim Claim
# @return arrayref attributes list
sub getAttributesListFromScopeValue {
    my ( $self, $rp, $scope_value ) = @_;
    return $self->rpScopes->{$rp}->{$scope_value};
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
            keys( %{ $self->rpScopeRules->{$rp} || {} } ),
            keys( %{ $self->rpScopes->{$rp}     || {} } ),
            'openid', 'offline_access',
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
    if ( $self->rpScopeRules->{$rp} ) {

        # Add dynamic scopes
        for my $dynamicScope ( keys %{ $self->rpScopeRules->{$rp} } ) {

            # Set a magic "$requested" variable that contains true if the
            # scope was requested by the application
            my $requested  = grep { $_ eq $dynamicScope } @scope_values;
            my $attributes = { %{ $req->userData }, requested => $requested };

            # If scope is granted by the rule
            if ( $self->rpScopeRules->{$rp}->{$dynamicScope}
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

sub _addAttributeToResponse {
    my ( $self, $req, $data, $userinfo_response, $rp, $attribute ) = @_;
    my @attrConf = split /;/,
      ( $self->rpAttributes->{$rp}->{$attribute} || "" );
    my $session_key = $attrConf[0];
    if ($session_key) {
        my $type  = $attrConf[1] || 'string';
        my $array = $attrConf[2] || 'auto';

        my $session_value;

        # Lookup attribute in macros first
        if ( $self->rpMacros->{$rp}->{$session_key} ) {
            $session_value =
              $self->rpMacros->{$rp}->{$session_key}->( $req, $data );

            # If not found, search in session
        }
        else {
            $session_value = $data->{$session_key};
        }

        # Handle empty values, arrays, type, etc.
        $session_value =
          $self->_formatValue( $session_value, $type, $array,
            $attribute, $req->user );

        # From this point on, do NOT touch $session_value
        # or you will break the variable's type.

        # Only release claim if it has a value
        if ( defined $session_value ) {

            # If this attribute is a standardized subkey (address)
            if ( COMPLEX_CLAIM->{$attribute} ) {
                my $superkey = COMPLEX_CLAIM->{$attribute};
                $userinfo_response->{$superkey}->{$attribute} = $session_value;
            }
            else {
                $userinfo_response->{$attribute} = $session_value;
            }
        }
    }
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
        _clientId => $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID},
        _clientConfKey => $rp,
        _scope         => $scope,
    };
    my $user_id = $self->getUserIDForRP( $req, $rp, $data );

    $self->logger->debug("Found corresponding user: $user_id");

    $userinfo_response->{sub} = $user_id;

    # By default, release all exported attributes
    if ( $self->conf->{oidcServiceIgnoreScopeForClaims} ) {
        for my $attribute ( keys %{ $self->rpAttributes->{$rp} || {} } ) {
            $self->_addAttributeToResponse( $req, $data, $userinfo_response,
                $rp, $attribute );
        }

        # Else, iterate through scopes to find allowed attributes
    }
    else {
        foreach my $scope_value ( split( /\s/, $scope ) ) {
            next if ( $scope_value eq "openid" );
            $self->logger->debug(
                "Get attributes linked to scope value $scope_value");
            my $list =
              $self->getAttributesListFromScopeValue( $rp, $scope_value );
            $self->logger->debug(
                "-> found attributes: " . join( " ", @{ $list || [] } ) );
            next unless $list;
            foreach my $attribute (@$list) {
                $self->_addAttributeToResponse( $req, $data,
                    $userinfo_response, $rp, $attribute );
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
    return $self->_createJWT( $payload, $alg, $rp, $type );
}

sub createJWTForOP {
    my ( $self, $payload, $alg, $rp, $type ) = @_;
    return $self->_createJWT( $payload, $alg, $rp, $type, 1 );
}

sub _createJWT {
    my ( $self, $payload, $alg, $partner, $type, $isRp ) = @_;

    my @keyArg;
    my %extra_headers;

    # Set Cript::JWT arguments depending on "alg"
    #  a) "none"
    if ( $alg eq 'none' ) {
        @keyArg = ( allow_none => 1 );
    }

    #  b) HMAC algorithms, key is the client secret
    elsif ( $alg =~ /^HS/ ) {

        # Sign with client secret
        my $client_secret =
            $isRp
          ? $self->opOptions->{$partner}->{oidcOPMetaDataOptionsClientSecret}
          : $self->rpOptions->{$partner}->{oidcRPMetaDataOptionsClientSecret};
        unless ($client_secret) {
            $self->logger->error(
                "Algorithm $alg needs a Client Secret to sign JWT");
            return;
        }
        @keyArg = ( key => $client_secret );
    }

    #  c) asymetric algorithms
    else {
        my $priv_key = $self->conf->{oidcServicePrivateKeySig};
        unless ($priv_key) {
            $self->logger->error(
                "Algorithm $alg needs a Private Key to sign JWT");
            return;
        }
        @keyArg = ( key => \$priv_key, );

        if ( $self->conf->{oidcServiceKeyIdSig} ) {
            $extra_headers{kid} = $self->conf->{oidcServiceKeyIdSig};
        }
        my $key_info =
          $self->getCertInfo( $self->conf->{oidcServicePublicKeySig} );
        if ( $key_info->{x5t} ) {
            $extra_headers{x5t} = $key_info->{x5t};
        }

    }
    my $noTyp =
        $isRp
      ? $self->opOptions->{$partner}->{oidcOPMetaDataOptionsNoJwtHeader}
      : $self->rpOptions->{$partner}->{oidcRPMetaDataOptionsNoJwtHeader};
    unless ($noTyp) {
        $extra_headers{typ} = $type || 'JWT';
    }
    push @keyArg, extra_headers => \%extra_headers if %extra_headers;

    # Encode payload here due to #2748
    my $jwt = eval {
        encode_jwt(
            payload => to_json($payload),
            alg     => $alg,
            @keyArg,
        );
    };
    if ($@) {
        $self->logger->error("Unable to build JWT: $@");
        return;
    }
    return $jwt;
}

# Return ID Token
# @param payload ID Token content
# @param rp Internal Relying Party identifier
# @return String id_token ID Token as JWT
sub createIDToken {
    my ( $self, $req, $payload, $rp ) = @_;

    # Get signature algorithm
    my $alg = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
    $self->logger->debug("ID Token signature algorithm: $alg");

    my $h = $self->p->processHook( $req, 'oidcGenerateIDToken', $payload, $rp );
    return undef if ( $h != PE_OK );

    my $id_token = $self->createJWT( $payload, $alg, $rp );
    return $self->encryptToken(
        $rp,
        $id_token,
        $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg},
        $self->rpOptions->{$rp}
          ->{oidcRPMetaDataOptionsAccessTokenEncContentEncAlg},
    );
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
    my ( $self, $key, $type ) = @_;

    if ( $type and $type eq 'EC' ) {
        require Crypt::PK::ECC;
        my $eck = Crypt::PK::ECC->new();
        $eck->import_key( \$key );
        return $eck->export_key_jwk( 'public', 1 );
    }
    else {
        my $rsa_pub = Crypt::OpenSSL::RSA->new_private_key($key);
        my @params  = $rsa_pub->get_key_parameters();

        return {
            n   => encode_base64url( $params[0]->to_bin(), "" ),
            e   => encode_base64url( $params[1]->to_bin(), "" ),
            kty => 'RSA',
        };
    }
}

# Return X.509 data if public key is a certificate
# @param key public key or certificate
# @return HashRef of JWK attributes
sub getCertInfo {
    my ( $self, $key ) = @_;

    if ( $key =~ /CERTIFICATE/ ) {
        my $x509 = Crypt::OpenSSL::X509->new_from_string( $key,
            Crypt::OpenSSL::X509::FORMAT_PEM );
        my $der  = $x509->as_string(Crypt::OpenSSL::X509::FORMAT_ASN1);
        my $hash = sha1($der);
        return {
            # Caution, x5c is B64, x5t is B64URL, this is not a mistake
            x5c => [ encode_base64( $der, '' ) ],
            x5t => encode_base64url($hash),
        };

    }
    else {
        return {};
    }
}

### JWKS ENDPOINT

# Keys to display in jwks endpoint:
#  Signature:
#   - current, new and old key to permit to clients to verify all JWT emitted
#     during 3 weeks
#  Encryption:
#   - only the current key. Old encryption key is kept to permit to
#     Auth::OPenIDCOnnect to decrypt all JWE emitted by Issuer but no
#     need to display any other key
use constant KEYS_TO_DISPLAY => (
    [ ''    => 'Sig' ],
    [ 'Old' => 'Sig' ],
    [ 'New' => 'Sig' ],
    [ ''    => 'Enc' ],
);

sub _buildJwk {
    my ( $self, $prefix, $type ) = @_;
    my $publicKeyOrCert = $self->conf->{"oidcService${prefix}PublicKey$type"};
    my $privateKey      = $self->conf->{"oidcService${prefix}PrivateKey$type"};
    my $keyId           = $self->conf->{"oidcService${prefix}KeyId$type"};
    my $keytype         = $self->conf->{"oidcService${prefix}KeyType$type"};
    return $privateKey
      ? {
        kty => $keytype,
        use => lc($type),
        (
            $type eq 'Enc'
            ? ( alg => $self->conf->{oidcServiceEncAlgorithmAlg} )
            : ()
        ),
        ( $keyId ? ( kid => $keyId ) : () ),
        %{ $self->key2jwks( $privateKey, $keytype ) },
        %{ $self->getCertInfo($publicKeyOrCert) },
      }
      : ();
}

# Handle jwks endpoint
sub jwks {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect JWKS URL");

    my $jwks = { keys => [] };

    push @{ $jwks->{keys} }, $self->_buildJwk( $_->[0], $_->[1] )
      foreach (KEYS_TO_DISPLAY);

    $self->logger->debug("Send JWKS response sent");
    return $self->p->sendJSONresponse( $req, $jwks );
}

# Build Logout Request URI
# @param redirect_uri Redirect URI
# @param id_token_hint ID Token
# @param post_logout_redirect_uri Callback URI
# @param state State
# return String Logout URI
sub buildLogoutRequest {
    my ( $self, $redirect_uri, @args ) = @_;

    my @tab = (qw(id_token_hint post_logout_redirect_uri state client_id));
    my @prms;
    for ( my $i = 0 ; $i < @tab ; $i++ ) {
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

    return URI->new($response_url)->as_string;
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
        $self->logger->error( "Unable to get request JWT on $request_uri: "
              . $response->message );
        $self->logger->debug( $response->content );
        return;
    }

    return $response->decoded_content;
}

sub addRouteFromConf {
    my ( $self, $type, %subs ) = @_;

    # avoid a warning in logs when route is already defined
    my $getter = { "Auth" => "authRoutes", "Unauth" => "unAuthRoutes" }->{$type}
      || "${type}Routes";

    my $adder = "add${type}Route";
    foreach ( keys %subs ) {
        my $sub  = $subs{$_};
        my $path = $self->conf->{$_};
        unless ($path) {
            $self->logger->error("$_ parameter not defined");
            next;
        }

        # Avoid warning if loading modules twice
        next if $self->p->$getter->{GET}->{ $self->path }->{$path};

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

    unless ($code_challenge) {
        $self->logger->debug("PKCE was not requested by the RP");
        return 1;
    }

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
    return $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenForceClaims};
}

# https://openid.net/specs/openid-connect-core-1_0.html#IDToken
# Audience(s) that this ID Token is intended for. It MUST contain the OAuth 2.0
# client_id of the Relying Party as an audience value. It MAY also contain
# identifiers for other audiences. In the general case, the aud value is an
# array of case sensitive strings. In the common special case when there is one
# audience, the aud value MAY be a single case sensitive string.
sub getAudiences {
    my ( $self, $rp ) = @_;

    my $client_id    = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};
    my @addAudiences = split /\s+/,
      ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAdditionalAudiences}
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
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsUserIDAttr}
      || $self->conf->{whatToTrace};

    # If the main attribute is a SP macro, resolve it
    # else, get it directly from session data
    return $self->rpMacros->{$rp}->{$user_id_attribute}
      ? $self->rpMacros->{$rp}->{$user_id_attribute}->( $req, $data )
      : $data->{$user_id_attribute};
}

# Return storage options
sub _storeOpts {
    my ($self) = @_;
    my $storage =
      $self->conf->{oidcStorage}
      ? {
        storageModule        => $self->conf->{oidcStorage},
        storageModuleOptions => $self->conf->{oidcStorageOptions},
      }
      : {
        storageModule        => $self->conf->{globalStorage},
        storageModuleOptions => $self->conf->{globalStorageOptions},
      };
    return %$storage;
}

sub generateNonce {
    my ($self) = @_;
    return encode_base64url( Crypt::URandom::urandom(16) );
}

sub getSidFromSession {
    my ( $self, $rp, $sessionInfo ) = @_;
    return $sessionInfo->{_oidc_sid}
      || Digest::SHA::hmac_sha256_base64(
        $sessionInfo->{_session_id} . ':' . $rp );
}

sub decryptJwt {
    my ( $self, $jwt ) = @_;
    my @count = split /\./, $jwt;
    if ( $#count == 4 ) {
        my $key = $self->conf->{oidcServicePrivateKeyEnc};
        $self->logger->debug("Receive an encrypted JWT: $jwt");
        unless ($key) {
            $self->logger->error('Receive an encrypted JWT but no key defined');
            return $jwt;
        }

        my $tmp;
        eval { $tmp = decode_jwt( token => $jwt, key => \$key, ); };
        if ($@) {
            if ( $key = $self->conf->{oidcServiceOldPrivateKeyEnc} ) {
                eval { $tmp = decode_jwt( token => $jwt, key => \$key, ); };
            }
            if ($@) {
                $self->logger->error( 'Unable to decrypt JWE: ' . $@ );
                return undef;
            }
        }
        $jwt = $tmp;
        $self->logger->debug("Decrypted JWT: $jwt");
    }
    return $jwt;
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
