package Lemonldap::NG::Portal::Issuer::OpenIDConnect;

use strict;
use JSON                       qw(from_json to_json);
use Lemonldap::NG::Common::JWT qw(getJWTPayload);
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  portalConsts
  PE_OK
  PE_ERROR
  PE_CONFIRM
  PE_REDIRECT
  PE_LOGOUT_OK
  PE_PASSWORD_OK
  PE_BADCREDENTIALS
  PE_UNAUTHORIZEDURL
  PE_UNAUTHORIZEDPARTNER
  PE_UNKNOWNPARTNER
  PE_OIDC_SERVICE_NOT_ALLOWED
  PE_FIRSTACCESS
  PE_SENDRESPONSE
  PE_SLO_ERROR
);
use String::Random qw/random_string/;

our $VERSION = '2.21.0';

extends qw(
  Lemonldap::NG::Portal::Main::Issuer
  Lemonldap::NG::Common::Conf::AccessLib
  Lemonldap::NG::Portal::Lib::OpenIDConnect
);

with 'Lemonldap::NG::Portal::Lib::LazyLoadedConfiguration',
  'Lemonldap::NG::Common::OpenIDConnect::Metadata';

# INTERFACE

sub beforeAuth { 'exportRequestParameters' }
use constant hook => { updateSessionId => 'updateOidcSecondarySessions' };

# INITIALIZATION

use constant sessionKind => 'OIDCI';

# random_string mask for auto-registration client-id/secret
use constant RS_MSK => 's' x 30;

has rule => ( is => 'rw' );
has configStorage => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->{p}->HANDLER->localConfig->{configStorage};
    }
);
has ssoMatchUrl => ( is => 'rw' );

has iss => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{oidcServiceMetaDataIssuer}
          || $_[0]->p->HANDLER->tsv->{portal}->();
    }
);

has amrRules => ( is => 'rw', default => sub { {} } );

sub get_issuer {
    my ( $self, $req ) = @_;
    if ( $self->iss ) {
        return $self->iss;
    }
    else {
        return $req->portal;
    }
}

# OIDC has 7 endpoints managed here as PSGI endpoints or in run() [Main/Issuer.pm
# manage transparent authentication for run()]:
#  - authorize   : in run()
#  - logout      : in run()
#                  => endSessionDone() for unauth users
#  - checksession: => checkSession()   for all
#  - token       : => token()          for unauth users (RP)
#  - userinfo    : => userInfo()       for unauth users (RP)
#  - jwks        : => jwks()           for unauth users (RP)
#  - register    : => registration()   for unauth users (RP)
#  - introspect  : => introspection()  for unauth users (RP)
#
# Other paths will be handle by run() and return PE_ERROR
#
# .well-known/openid-configuration is handled by metadata()

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug(
        "OIDC rule -> " . $self->conf->{issuerDBOpenIDConnectRule} );
    my $rule =
      $hd->buildSub(
        $hd->substitute( $self->conf->{issuerDBOpenIDConnectRule} ) );
    unless ($rule) {
        my $error = $hd->tsv->{jail}->error || '???';
        $self->error("Bad OIDC activation rule -> $error");
        return 0;
    }
    $self->{rule} = $rule;

    return 0
      unless $self->Lemonldap::NG::Portal::Main::Issuer::init();

    # Preloading RPs should not be needed thanks to lazy loading, but is
    # required to make sp:confKey display rules work (#3058)
    $self->loadRPs;

    # Manage RP requests
    $self->addRouteFromConf(
        'Unauth',
        oidcServiceMetaDataEndSessionURI    => 'endSessionDone',
        oidcServiceMetaDataCheckSessionURI  => 'checkSession',
        oidcServiceMetaDataTokenURI         => 'token',
        oidcServiceMetaDataUserInfoURI      => 'unauthUserInfo',
        oidcServiceMetaDataJWKSURI          => 'jwks',
        oidcServiceMetaDataRegistrationURI  => 'registration',
        oidcServiceMetaDataIntrospectionURI => 'introspection',
    );

    # Manage user requests
    $self->addRouteFromConf(
        'Auth',
        oidcServiceMetaDataCheckSessionURI  => 'checkSession',
        oidcServiceMetaDataTokenURI         => 'token',
        oidcServiceMetaDataUserInfoURI      => 'userInfo',
        oidcServiceMetaDataJWKSURI          => 'jwks',
        oidcServiceMetaDataRegistrationURI  => 'registration',
        oidcServiceMetaDataIntrospectionURI => 'introspection',
    );

    # Metadata (.well-known/openid-configuration)
    $self->addUnauthRoute(
        '.well-known' => { 'openid-configuration' => 'metadata' },
        ['GET']
    ) unless $self->conf->{oidcServiceHideMetadata};
    $self->addAuthRoute(
        '.well-known' => { 'openid-configuration' => 'metadata' },
        ['GET']
    );
    my $m =
        '^/'
      . $self->path . '/+(?:'
      . join( '|',
        $self->conf->{oidcServiceMetaDataAuthorizeURI},
        $self->conf->{oidcServiceMetaDataEndSessionURI},
      ) . ')';
    $self->ssoMatchUrl(qr/$m/);

    while ( my ( $amr_value, $rule ) =
        each %{ $self->conf->{oidcServiceMetaDataAmrRules} || {} } )
    {
        $self->logger->debug("Compiling AMR rule for $amr_value");
        my $compiled_rule =
          $self->p->buildRule( $rule, "amr rule for $amr_value" );
        $self->amrRules->{$amr_value} = $compiled_rule if $compiled_rule;
    }

    return 1;
}

# CONFIGURATION LOADING

# Get Relying Party corresponding to a Client ID
# This will lazy-load the corresponding config from either LLNG configuration
# or from a plugin.
# @param client_id Client ID
# @return String result
sub getRP {
    my ( $self, $client_id ) = @_;
    my $rp;
    my $result = $self->lazy_load_config($client_id);
    return $result->{confKey};
}

# Handles configuration loading of RPs
# this method is called by the LazyLoadedConfiguration role
sub load_config {
    my ( $self, $client_id ) = @_;

    my @confKeys = grep {
        $self->conf->{oidcRPMetaDataOptions}->{$_}
          ->{oidcRPMetaDataOptionsClientID} eq $client_id
    } keys %{ $self->conf->{oidcRPMetaDataOptions} || {} };

    # Found this client_id in configuration,
    # load it permanently (until next conf reload)
    if (@confKeys) {
        my $confKey = $confKeys[0];
        $self->logger->debug("Loading $client_id from LLNG config $confKey");
        $self->load_rp_from_llng_conf($confKey);
        return { info => { confKey => $confKey } };
    }

    # Not found in config, try to load from hook
    my $config = {};
    $self->p->processHook( {}, 'getOidcRpConfig', $client_id, $config );

    my $info;
    if ( $config->{confKey} ) {

        $self->logger->debug(
            "Loading $config->{confKey} from getOidcRpConfig hook");
        $info = { confKey => $config->{confKey} };

        # Make sure Client ID is correctly set in options
        $config->{options}->{oidcRPMetaDataOptionsClientID} = $client_id;
        $self->load_rp(%$config);

    }

    # You can set a negative TTL in getOidcRpConfig hook even if you don't find
    # anything to avoid doing too many lookups
    my $ttl = $config->{ttl};
    return { ( $ttl ? ( ttl => $ttl ) : () ),
        ( $info ? ( info => $info ) : () ) };
}

# Load all OpenID Connect Relying Parties from configuration
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
        my $client_id = $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsClientID};
        if ($client_id) {
            $self->lazy_load_config($client_id);
        }
        else {
            $self->logger->warn("RP $rp has no Client ID");
        }
    }
    return 1;
}

# RUNNING METHODS

sub ssoMatch {
    my ( $self, $req ) = @_;
    my $lh = $req->param('login_hint');
    $req->data->{suggestedLogin} ||= $lh if $lh;
    return ( $req->uri =~ $self->ssoMatchUrl ? 1 : 0 );
}

# Main method (launched only for authenticated users, see Main/Issuer.pm)
# run() manages only "authorize" and "logout" endpoints.
sub run {
    my ( $self, $req, $path ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('OIDC service not authorized');
        return PE_OIDC_SERVICE_NOT_ALLOWED;
    }

    if ($path) {

        # Convert old format OIDC Consents
        my $ConvertedConsents = $self->_convertOldFormatConsents($req);
        $self->logger->debug("$ConvertedConsents consent(s) converted");

        # AUTHORIZE
        if ( $path eq $self->conf->{oidcServiceMetaDataAuthorizeURI} ) {
            $self->logger->debug(
                "URL detected as an OpenID Connect AUTHORIZE URL");
            return $self->_authorizeEndpoint($req);

        }
        elsif ( $path eq $self->conf->{oidcServiceMetaDataEndSessionURI} ) {
            $self->logger->debug(
                "URL detected as an OpenID Connect END SESSION URL");
            return $self->_rpInitiatedLogout($req);
        }
    }

    $self->logger->error(
        $path
        ? "Unknown OIDC endpoint: $path, skipping"
        : 'No OIDC endpoint found, aborting'
    );
    return PE_ERROR;
}

sub _checkErrorsInAuthorizeEndpoint {
    my ( $self, $req ) = @_;

    # Get and save parameters
    my $oidc_request = {};
    foreach my $param (
        qw/response_type scope client_id state redirect_uri nonce
        response_mode display prompt max_age ui_locales id_token_hint
        login_hint acr_values request request_uri code_challenge code_challenge_method/
      )
    {
        if ( $req->param($param) ) {
            $oidc_request->{$param} = $req->param($param);
            $self->logger->debug(
                "OIDC request parameter $param: " . $oidc_request->{$param} );
            $self->p->setHiddenFormValue( $req, $param, $oidc_request->{$param},
                '', 0 );
        }
    }

    my $h = $self->p->processHook( $req, 'oidcGotRequest', $oidc_request );
    return $self->_failAuthorize(
        $req,
        message => "oidcGotRequest hook failed",
        res     => $h
    ) if ( $h != PE_OK );

    # Detect requested flow
    my $response_type = $oidc_request->{'response_type'};

    unless ($response_type) {
        return $self->_failAuthorize( $req,
            msg => "No response type provided" );
    }

    my $flow = $self->getFlowType($response_type);

    unless ($flow) {
        return $self->_failAuthorize( $req,
            msg => "Unknown response type: $response_type" );
    }
    $self->logger->debug(
        "OIDC $flow flow requested (response type: $response_type)");

    # Check if response mode is allowed for flow
    my $response_mode = $oidc_request->{'response_mode'};
    if ( !$self->isResponseModeAllowed( $flow, $response_mode ) ) {
        return $self->_failAuthorize( $req,
            msg => "Reponse mode $response_mode is not allowed in $flow Flow" );
    }

    # Client ID must be provided and cannot come from
    # request or request_uri
    unless ( $oidc_request->{'client_id'} ) {
        return $self->_failAuthorize( $req, msg => "Client ID is required" );
    }

    # Check client_id
    my $client_id = $oidc_request->{'client_id'};
    $self->logger->debug("Request from client id $client_id");

    # Verify that client_id is registered in configuration
    my $rp = $self->getRP($client_id);

    unless ($rp) {
        return $self->_failAuthorize(
            $req,
            msg => (
                    "No registered Relying Party found with"
                  . " client_id $client_id"
            ),
            res => PE_UNKNOWNPARTNER
        );
    }
    else {
        $self->logger->debug("Client id $client_id matches RP $rp");
    }

    # Scope must be provided and cannot come from request or request_uri
    unless ( $oidc_request->{'scope'} ) {
        return $self->_failAuthorize( $req, msg => "Scope is required" );
    }

    # Extract request_uri/request parameter
    if ( my $request_uri = $oidc_request->{'request_uri'} ) {
        if (
            $self->isUriAllowedForRP(
                $request_uri, $rp, "oidcRPMetaDataOptionsRequestUris", 1
            )
          )
        {
            my $request = $self->getRequestJWT($request_uri);

            if ($request) {
                $oidc_request->{'request'} = $request;
            }
            else {
                return $self->_failAuthorize( $req,
                    msg => "Error with Request URI resolution" );
            }
        }
        else {
            return $self->_failAuthorize( $req,
                msg => "Request URI $request_uri is not allowed for $rp" );
        }
    }

    my $authMethod;
    if ( $oidc_request->{'request'} ) {
        if ( my ( $request, $alg ) =
            $self->decodeJWT( $oidc_request->{'request'}, undef, $rp ) )
        {
            $self->logger->debug("JWT signature request verified");

            $authMethod =
              $alg =~ /^HS/i
              ? 'client_secret_jwt'
              : 'private_key_jwt';

            # Override OIDC parameters by request content
            foreach ( keys %$request ) {
                $self->logger->debug( "Override $_ OIDC param"
                      . " by value present in request parameter" );

                if ( $_ eq "client_id" or $_ eq "response_type" ) {
                    if ( $oidc_request->{$_} ne $request->{$_} ) {
                        return $self->_failAuthorize(
                            $req,
                            msg => (
                                    "$_ from request JWT ("
                                  . $oidc_request->{$_}
                                  . ") does not match $_ from request URI ("
                                  . $request->{$_} . ")"
                            )
                        );
                    }
                }
                $oidc_request->{$_} = $request->{$_};
                $self->p->setHiddenFormValue( $req, $_, $request->{$_}, '', 0 );
            }
        }
        else {
            return $self->_failAuthorize( $req,
                msg => "JWT signature request can not be verified" );
        }
    }

    # Check all required parameters
    unless ( $oidc_request->{'redirect_uri'} ) {
        return $self->_failAuthorize( $req, msg => "Redirect URI is required" );
    }
    if ( $flow eq "implicit" and not defined $oidc_request->{'nonce'} ) {
        return $self->_failAuthorize( $req,
            msg => "Nonce is required for implicit flow" );
    }

    # Check if this RP is authorized
    if ( my $rule = $self->rpRules->{$rp} ) {
        my $ruleVariables =
          { %{ $req->sessionInfo || {} }, _oidc_grant_type => $flow };
        unless ( $rule->( $req, $ruleVariables ) ) {
            return $self->_failAuthorize(
                $req,
                msg => (
                        'User '
                      . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                      . " is not authorized to access to $rp"
                ),
                res        => PE_UNAUTHORIZEDPARTNER,
                userLogger => 1,
            );
        }
    }

    # Check redirect_uri
    my $redirect_uri = $oidc_request->{'redirect_uri'};
    if (
        !$self->isUriAllowedForRP(
            $redirect_uri, $rp, 'oidcRPMetaDataOptionsRedirectUris'
        )
      )
    {
        return $self->_failAuthorize(
            $req,
            msg        => "Redirect URI $redirect_uri not allowed",
            res        => PE_UNAUTHORIZEDURL,
            userLogger => 1,
        );
    }

    # Check if flow is allowed
    if ( $flow eq "authorizationcode"
        and not $self->conf->{oidcServiceAllowAuthorizationCodeFlow} )
    {
        return $self->returnRedirectError(
            $req,           $oidc_request->{'redirect_uri'},
            "server_error", "Authorization code flow not allowed",
            undef,          $oidc_request->{'state'}, 0
        );
    }
    if ( $flow eq "implicit"
        and not $self->conf->{oidcServiceAllowImplicitFlow} )
    {
        return $self->returnRedirectError(
            $req,           $oidc_request->{'redirect_uri'},
            "server_error", "Implicit flow not allowed",
            undef,          $oidc_request->{'state'}, 1
        );
    }
    if ( $flow eq "hybrid"
        and not $self->conf->{oidcServiceAllowHybridFlow} )
    {
        return $self->returnRedirectError(
            $req,           $oidc_request->{'redirect_uri'},
            "server_error", "Hybrid flow not allowed",
            undef,          $oidc_request->{'state'}, 1
        );
    }

    # Check if authentication was required
    if (
        $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthRequiredForAuthorize}
      )
    {
        $self->logger->debug('JWS authentication is required');
        unless ($authMethod) {
            return $self->returnRedirectError(
                $req,           $oidc_request->{'redirect_uri'},
                'server_error', 'JWS authentication required',
                undef,          $oidc_request->{'state'}, 1
            );
        }
        my $methodAllowed =
          $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthMethod};
        if ( $methodAllowed and $authMethod ne $methodAllowed ) {
            return $self->returnRedirectError(
                $req,           $oidc_request->{'redirect_uri'},
                'server_error', "Authentication must use $methodAllowed",
                undef,          $oidc_request->{'state'},
                1
            );
        }
    }

    # Check if state is required
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthnRequireState}
        and not( $oidc_request->{'state'} ) )
    {
        return $self->returnRedirectError(
            $req,           $oidc_request->{'redirect_uri'},
            "server_error", "State required",
            undef,          undef, 1
        );
    }

    # Check if nonce is required
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthnRequireNonce}
        and not( $oidc_request->{'nonce'} ) )
    {
        return $self->returnRedirectError(
            $req,           $oidc_request->{'redirect_uri'},
            "server_error", "Nonce required",
            undef,          undef, 1
        );
    }

    # Check scope validity
    # We use a slightly more relaxed version of
    # https://tools.ietf.org/html/rfc6749#appendix-A.4
    # To be tolerant of user error (trailing spaces, etc.)
    # Scope names are restricted to printable ASCII characters,
    # excluding double quote and backslash
    unless ( $oidc_request->{'scope'} =~ /^[\x20\x21\x23-\x5B\x5D-\x7E]*$/ ) {
        return $self->_failAuthorize( $req,
            msg => "Submitted scope is not valid" );
    }

    # Check openid scope
    unless ( $self->_hasScope( 'openid', $oidc_request->{'scope'} ) ) {
        return $self->_failAuthorize( $req, msg => "No openid scope found" );
    }
    $req->data->{_oidc_request} = $oidc_request;
    $req->data->{_oidc_rp}      = $rp;
    $req->data->{_oidc_flow}    = $flow;
    return ();
}

sub _authorizeEndpoint {
    my ( $self, $req ) = @_;

    my $res = $self->_checkErrorsInAuthorizeEndpoint($req);
    return $res if $res;
    my $oidc_request  = $req->data->{_oidc_request};
    my $rp            = $req->data->{_oidc_rp};
    my $flow          = $req->data->{_oidc_flow};
    my $client_id     = $oidc_request->{client_id};
    my $response_type = $oidc_request->{'response_type'};

    my $spAuthnLevel = $self->rpLevelRules->{$rp}->( $req, $req->sessionInfo );
    $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAuthnLevel} || 0;

    # RP may increase, but not lower, the requirement set in LLNG conf
    if ( $oidc_request->{'acr_values'} ) {
        my $requested_authn_level =
          $self->_get_authn_level_from_acr_values(
            $oidc_request->{'acr_values'} );
        if ( $requested_authn_level > $spAuthnLevel ) {
            $spAuthnLevel = $requested_authn_level;
        }
        else {
            $self->logger->info( "Ignoring requested authentication level "
                  . $requested_authn_level
                  . " because it is lower than minimum for this RP: $spAuthnLevel"
            );
        }
    }

    # Check if user needs to be reauthenticated
    my $prompt = $oidc_request->{'prompt'};
    if (
            $prompt
        and $prompt =~ /\blogin\b/
        and (
            time - $req->sessionInfo->{_utime} >
            $self->conf->{portalForceAuthnInterval} )
      )
    {
        $self->logger->debug(
            "Reauthentication required by Relying Party in prompt parameter");
        $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
        return $self->reAuth($req);
    }

    # Check id_token_hint
    my $id_token_hint = $oidc_request->{'id_token_hint'};
    if ($id_token_hint) {

        $self->logger->debug("Check sub of ID Token $id_token_hint");

        # Check that id_token_hint sub match current user
        my $sub     = $self->getIDTokenSub($id_token_hint);
        my $user_id = $self->getUserIDForRP( $req, $rp, $req->{sessionInfo} );
        unless ( $sub eq $user_id ) {
            $self->logger->error(
                "ID Token hint sub $sub does not match user $user_id");
            return $self->returnRedirectError(
                $req,
                $oidc_request->{'redirect_uri'},
                'invalid_request',
                "Current user does not match id_token_hint sub",
                undef,
                $oidc_request->{'state'},
                ( $flow ne "authorizationcode" )
            );
        }
        else {
            $self->logger->debug("ID Token hint sub $sub matches current user");
        }
    }

    my $max_age         = $oidc_request->{'max_age'};
    my $_lastAuthnUTime = $req->{sessionInfo}->{_lastAuthnUTime};
    if ( $max_age && time > $_lastAuthnUTime + $max_age ) {
        $self->logger->debug(
                "Reauthentication forced because authentication time"
              . " ($_lastAuthnUTime) is too old (>$max_age s)" );
        $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
        return $self->reAuth($req);
    }

    # Check if we have sufficient auth level
    my $authenticationLevel = $req->{sessionInfo}->{authenticationLevel} || 0;
    if ( $authenticationLevel < $spAuthnLevel ) {
        $self->logger->debug(
                "Insufficient authentication level for service $rp"
              . " (has: $authenticationLevel, want: $spAuthnLevel)" );

        # Reauth with sp auth level as target
        $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
        return $self->upgradeAuth($req);
    }

    # Compute scopes
    my $req_scope = $oidc_request->{'scope'};
    my $scope     = $self->getScope( $req, $rp, $req_scope );

    # Obtain consent
    my $bypassConsent =
      $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsBypassConsent};
    if ($bypassConsent) {
        $self->logger->debug( "Consent is disabled for Relying Party $rp,"
              . " user will not be prompted" );
    }
    else {
        my $ask_for_consent = 1;
        my $_oidcConsents;
        my @RPoidcConsent = ();

        # Loading existing oidcConsents
        $self->logger->debug("Looking for OIDC Consents ...");

        if ( $req->{sessionInfo}->{_oidcConsents} ) {
            $_oidcConsents = eval {
                from_json( $req->{sessionInfo}->{_oidcConsents},
                    { allow_nonref => 1 } );
            };
            if ($@) {
                return $self->_failAuthorize( $req,
                    msg => "Corrupted session (_oidcConsents): $@" );
            }
        }
        else {
            $self->logger->debug("No OIDC Consent found");
            $_oidcConsents = [];
        }

        # Read existing RP
        @RPoidcConsent = grep { $_->{rp} eq $rp } @$_oidcConsents;
        unless (@RPoidcConsent) {
            $self->logger->debug("No Relying Party $rp Consent found");

            # Set default value
            push @RPoidcConsent, { rp => $rp, epoch => '', scope => '' };
        }

        if (   $RPoidcConsent[0]{rp} eq $rp
            && $RPoidcConsent[0]{epoch}
            && $RPoidcConsent[0]{scope} )
        {
            $ask_for_consent = 0;
            my $consent_time  = $RPoidcConsent[0]{epoch};
            my $consent_scope = $RPoidcConsent[0]{scope};
            $self->logger->debug(
                    "Consent already given for Relying Party $rp"
                  . " (time: $consent_time, scope: $consent_scope)" );

            # Check accepted scope
            foreach my $requested_scope ( split( /\s+/, $scope ) ) {
                if ( $self->_hasScope( $requested_scope, $consent_scope ) ) {
                    $self->logger->debug(
                        "Scope $requested_scope already accepted");
                }
                else {
                    $self->logger->debug(
                        "Scope $requested_scope was not previously accepted");
                    $ask_for_consent = 1;
                    last;
                }
            }

            # Check prompt parameter
            $ask_for_consent = 1
              if ( $prompt and $prompt =~ /\bconsent\b/ );
        }
        if ($ask_for_consent) {
            if (    $req->param('confirm')
                and $req->param('confirm') == 1 )
            {
                $RPoidcConsent[0]{epoch} = time;
                $RPoidcConsent[0]{scope} = $scope;

                # Build new consent list by removing all references
                # to the current RP from the old list and appending the
                # new consent
                my @newoidcConsents =
                  grep { $_->{rp} ne $rp } @$_oidcConsents;
                push @newoidcConsents, $RPoidcConsent[0];
                $self->logger->debug("Append Relying Party $rp Consent");
                $self->p->updatePersistentSession( $req,
                    { _oidcConsents => to_json( \@newoidcConsents ) } );

                $self->logger->debug("Consent given for Relying Party $rp");
            }
            elsif ( $req->param('confirm')
                and $req->param('confirm') == -1 )
            {
                $self->logger->debug(
                    "User refused consent for Relying party $rp");
                return $self->returnRedirectError(
                    $req,
                    $oidc_request->{'redirect_uri'},
                    "consent_required",
                    "consent not given",
                    undef,
                    $oidc_request->{'state'},
                    ( $flow ne "authorizationcode" )
                );
            }
            else {
                $self->logger->debug(
                    "Request user consent for Relying Party $rp");

                # Return error if prompt is none
                if ( $prompt and $prompt =~ /\bnone\b/ ) {
                    $self->logger->debug(
                        "Consent is requiered but prompt is set to none");
                    return $self->returnRedirectError(
                        $req,
                        $oidc_request->{'redirect_uri'},
                        "consent_required",
                        "consent required",
                        undef,
                        $oidc_request->{'state'},
                        ( $flow ne "authorizationcode" )
                    );
                }

                my $display_name =
                  $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsDisplayName};
                my $icon = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIcon};
                my $imgSrc;

                if ($icon) {
                    $imgSrc =
                      ( $icon =~ m#^https?://# )
                      ? $icon
                      : $self->p->staticPrefix . "/common/" . $icon;
                }

                my $scope_messages = {
                    openid         => 'yourIdentity',
                    profile        => 'yourProfile',
                    email          => 'yourEmail',
                    address        => 'yourAddress',
                    phone          => 'yourPhone',
                    offline_access => 'yourOffline',
                };
                my @list;
                foreach my $requested_scope ( split( /\s+/, $scope ) ) {
                    if ( my $message = $scope_messages->{$requested_scope} ) {
                        push @list, { m => $message };
                    }
                    else {
                        push @list,
                          {
                            m => 'anotherInformation',
                            n => $requested_scope
                          };
                    }
                }
                $req->info(
                    $self->loadTemplate(
                        $req,
                        'oidcGiveConsent',
                        params => {
                            displayName => $display_name,
                            imgUrl      => $imgSrc,
                            list        => \@list,
                        }
                    )
                );
                $req->data->{activeTimer} = 0;
                return PE_CONFIRM;
            }
        }
    }

    # Create session_state
    my $session_state = $self->createSessionState( $req->id, $client_id );

    # Check if PKCE is required
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsRequirePKCE}
        and !$oidc_request->{'code_challenge'} )
    {
        return $self->returnRedirectError(
            $req,              $oidc_request->{'redirect_uri'},
            'invalid_request', "Code challenge is required",
            undef,             $oidc_request->{'state'},
            ( $flow ne "authorizationcode" )
        );
    }

    my $offline = 0;
    if ( $self->_hasScope( 'offline_access', $scope ) ) {
        $offline = 1;

        # MUST ensure that the prompt parameter contains consent unless
        # other conditions for processing the request permitting offline
        # access to the requested resources are in place; unless one or
        # both of these conditions are fulfilled, then it MUST ignore
        # the offline_access request,
        unless ( $bypassConsent
            or ( $prompt and $prompt =~ /\bconsent\b/ ) )
        {
            $self->logger->warn( "Offline access ignored, "
                  . "prompt parameter must contain \"consent\"" );
            $offline = 0;
        }

        # MUST ignore the offline_access request unless the Client is
        # using a response_type value that would result in an
        # Authorization Code being returned,
        if ( $response_type !~ /\bcode\b/ ) {
            $self->logger->warn( "Offline access incompatible "
                  . "with response type $response_type" );
            $offline = 0;
        }

        # Ignore offline_access request if not authorized by the RP
        unless ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowOffline} )
        {
            $self->logger->warn("Offline access not authorized for RP $rp");
            $offline = 0;
        }

        # Strip offline_access from scopes from now on
        $scope = join " ", grep !/^offline_access$/, split /\s+/, $scope;
    }

    # Authorization Code Flow
    if ( $flow eq "authorizationcode" ) {

        # Store data in session
        my $code_payload = {
            code_challenge        => $oidc_request->{'code_challenge'},
            code_challenge_method => $oidc_request->{'code_challenge_method'},
            nonce                 => $oidc_request->{'nonce'},
            offline               => $offline,
            redirect_uri          => $oidc_request->{'redirect_uri'},
            scope                 => $scope,
            req_scope             => $req_scope,
            client_id             => $client_id,
            user_session_id       => $req->id,
        };

        my $h = $self->p->processHook( $req, 'oidcGenerateCode',
            $oidc_request, $rp, $code_payload );
        return $self->_failAuthorize(
            $req,
            msg => "oidcGenerateCode hook failed",
            res => $h
        ) if ( $h != PE_OK );

        my $codeSession = $self->newAuthorizationCode( $rp, $code_payload );

        # Generate code
        my $code = $codeSession->id();

        $self->logger->debug("Generated code: $code");

        my $state = $oidc_request->{'state'};

        $self->p->registerProtectedAppAccess( $req,
            $req->sessionInfo->{ $self->conf->{whatToTrace} }, "oidc:$rp" );

        $self->auditLog(
            $req,
            code    => "ISSUER_OIDC_LOGIN_SUCCESS",
            rp      => $rp,
            message => (
                    'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is authorized to access to $rp"
            ),
            user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
        );

        return $self->sendOidcResponse(
            $req, $flow,
            $oidc_request->{'response_mode'},
            $oidc_request->{'redirect_uri'},
            {
                ( $code  ? ( code  => $code )  : () ),
                ( $state ? ( state => $state ) : () ),
                (
                    $session_state
                    ? ( session_state => $session_state )
                    : ()
                ),
            }
        );
    }

    # Implicit Flow
    if ( $flow eq "implicit" ) {

        my $access_token;
        my $at_hash;

        my $release_claims_in_id_token = 1;
        if ( $response_type =~ /\btoken\b/ ) {

            $release_claims_in_id_token = 0;

            # Store data in access token
            # Generate access_token
            $access_token = $self->newAccessToken(
                $req, $rp, $scope,
                $req->sessionInfo,
                {
                    scope           => $scope,
                    rp              => $rp,
                    user_session_id => $req->id,
                    grant_type      => $flow,
                }
            );

            unless ($access_token) {
                $self->returnRedirectError(
                    $req,           $oidc_request->{'redirect_uri'},
                    "server_error", "Unable to create Access Token",
                    undef,          $oidc_request->{'state'},
                    1
                );
            }

            $self->logger->debug("Generated access token: $access_token");

            # Compute hash to store in at_hash
            my $alg =
              $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
            my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
            $at_hash = $self->createHash( $access_token, $hash_level )
              if $hash_level;
        }

        my $id_token =
          $self->_generateIDToken( $req, $rp, $scope, $req->sessionInfo,
            $release_claims_in_id_token,
            { at_hash => $at_hash, nonce => $oidc_request->{nonce} } );

        unless ($id_token) {
            return $self->_failAuthorize( $req,
                msg => "Could not generate ID token" );
        }

        $self->logger->debug("Generated id token: $id_token");

        # Send token response
        my $expires_in =
          $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
          || $self->conf->{oidcServiceAccessTokenExpiration};

        my $state = $oidc_request->{'state'};

        $self->auditLog(
            $req,
            code    => "ISSUER_OIDC_LOGIN_SUCCESS",
            rp      => $rp,
            message => (
                    'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is authorized to access to $rp"
            ),
            user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
        );

        return $self->sendOidcResponse(
            $req, $flow,
            $oidc_request->{'response_mode'},
            $oidc_request->{'redirect_uri'},
            {
                id_token => $id_token,
                (
                    $access_token
                    ? (
                        token_type   => 'bearer',
                        access_token => $access_token
                      )
                    : ()
                ),
                ( $expires_in ? ( expires_in => $expires_in )    : () ),
                ( $state      ? ( state      => $state )         : () ),
                ( ( $req_scope ne $scope ) ? ( scope => $scope ) : () ),
                (
                    $session_state ? ( session_state => $session_state )
                    : ()
                )
            }
        );
    }

    # Hybrid Flow
    if ( $flow eq "hybrid" ) {

        my $access_token;
        my $id_token;
        my $at_hash;
        my $c_hash;

        # Hash level
        my $alg =
          $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
        my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );

        # Store data in session
        my $codeSession = $self->newAuthorizationCode(
            $rp,
            {
                nonce           => $oidc_request->{'nonce'},
                offline         => $offline,
                redirect_uri    => $oidc_request->{'redirect_uri'},
                client_id       => $client_id,
                scope           => $scope,
                user_session_id => $req->id,
            }
        );

        # Generate code
        my $code = $codeSession->id();

        $self->logger->debug("Generated code: $code");

        # Compute hash to store in c_hash
        $c_hash = $self->createHash( $code, $hash_level )
          if $hash_level;

        my $release_claims_in_id_token = 1;
        if ( $response_type =~ /\btoken\b/ ) {

            $release_claims_in_id_token = 0;

            # Generate access_token
            $access_token = $self->newAccessToken(
                $req, $rp, $scope,
                $req->sessionInfo,
                {
                    scope           => $scope,
                    rp              => $rp,
                    user_session_id => $req->id,
                    grant_type      => $flow,
                }
            );

            unless ($access_token) {
                return $self->returnRedirectError(
                    $req,           $oidc_request->{'redirect_uri'},
                    "server_error", "Unable to create Access Token",
                    undef,          $oidc_request->{'state'},
                    1
                );
            }

            $self->logger->debug("Generated access token: $access_token");

            # Compute hash to store in at_hash
            $at_hash = $self->createHash( $access_token, $hash_level )
              if $hash_level;
        }

        if ( $response_type =~ /\bid_token\b/ ) {

            $id_token = $self->_generateIDToken(
                $req, $rp, $scope,
                $req->sessionInfo,
                $release_claims_in_id_token,
                {
                    at_hash => $at_hash,
                    c_hash  => $c_hash,
                    nonce   => $oidc_request->{nonce},
                }
            );

            unless ($id_token) {
                return $self->_failAuthorize( $req,
                    msg => "Could not generate ID token" );
            }

            $self->logger->debug("Generated id token: $id_token");
        }

        my $expires_in =
          $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
          || $self->conf->{oidcServiceAccessTokenExpiration};

        my $state = $oidc_request->{state};

        $self->auditLog(
            $req,
            code    => "ISSUER_OIDC_LOGIN_SUCCESS",
            rp      => $rp,
            message => (
                    'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is authorized to access to $rp"
            ),
            user => $req->sessionInfo->{ $self->conf->{whatToTrace} },
        );

        return $self->sendOidcResponse(
            $req, $flow,
            $oidc_request->{'response_mode'},
            $oidc_request->{'redirect_uri'},
            {
                code => $code,
                (
                    $access_token
                    ? (
                        token_type   => 'bearer',
                        access_token => $access_token
                      )
                    : ()
                ),
                (
                    $id_token ? ( id_token => $id_token )
                    : ()
                ),
                ( $expires_in ? ( expires_in => $expires_in )    : () ),
                ( $state      ? ( state      => $state )         : () ),
                ( ( $req_scope ne $scope ) ? ( scope => $scope ) : () ),
                (
                    $session_state ? ( session_state => $session_state )
                    : ()
                )
            }
        );
    }

    $self->logger->debug("None flow has been selected");
    return PE_OK;
}

sub _failAuthorize {
    my ( $self, $req, %params ) = @_;

    my $reason = $params{'msg'} ? ": $params{'msg'}" : "";
    my $res    = $params{res} || PE_ERROR;

    $self->auditLog(
        $req,
        code    => "ISSUER_OIDC_LOGIN_FAILED",
        message => ( "OIDC login failed" . $reason ),
        ( $reason ? ( reason => $reason ) : () ),
        portal_error => portalConsts->{$res},
        user         => $req->sessionInfo->{ $self->conf->{whatToTrace} },
    );

    return $res;
}

sub _rpInitiatedLogout {
    my ( $self, $req ) = @_;

    # Set hidden fields
    my $oidc_request = {};
    foreach my $param (qw/id_token_hint post_logout_redirect_uri state/) {
        if ( $oidc_request->{$param} = $req->param($param) ) {
            $self->logger->debug(
                "OIDC request parameter $param: " . $oidc_request->{$param} );
        }
    }

    my $post_logout_redirect_uri = $oidc_request->{'post_logout_redirect_uri'};
    my $id_token_hint            = $oidc_request->{'id_token_hint'};
    my $state                    = $oidc_request->{'state'};
    my $bypassConfirm            = 0;

    # Check if we can bypass confirm using token_hint
    if ($id_token_hint) {

        # TODO: we should check JWT signature here to avoid DoS by
        # logging the user out, however, as long as there is no logout
        # confirmation when accessing ?logout=1, such a protection is
        # trivial to bypass
        my $payload = getJWTPayload($id_token_hint);
        my $rp;
        $rp = $self->getRP( $payload->{azp} ) if $payload->{azp};

        $bypassConfirm = $self->_check_bypass_confirm( $req, $rp, $payload );
    }

    # Ask consent for logout
    if ( $req->param('confirm') or $bypassConfirm ) {
        my $err;
        if ( (
                defined( $req->param('confirm') )
                and $req->param('confirm') eq '1'
            )
            or $bypassConfirm
          )
        {
            $req->steps(
                [ @{ $self->p->beforeLogout }, 'authLogout', 'deleteSession' ]
            );
            $req->data->{nofail} = 1;
            $err = $req->error( $self->p->process($req) );
            if ( $err and $err != PE_LOGOUT_OK ) {
                if ( $err > 0 ) {
                    $self->logger->error(
                        "Logout process returns error code $err");
                }
                return $err;
            }
        }

        if ($post_logout_redirect_uri) {

            unless (
                $self->findRPFromUri(
                    $post_logout_redirect_uri,
                    'oidcRPMetaDataOptionsPostLogoutRedirectUris'
                )
              )
            {
                $self->logger->error(
                    "$post_logout_redirect_uri is not allowed");
                return PE_UNAUTHORIZEDURL;
            }

            # Build Response
            my $response_url =
              $self->buildLogoutResponse( $post_logout_redirect_uri, $state );

            return $self->_redirectToUrl( $req, $response_url );
        }
        return $req->param('confirm') == 1
          ? ( $err ? $err : PE_LOGOUT_OK )
          : PE_OK;
    }

    $req->info( $self->loadTemplate( $req, 'oidcLogout' ) );
    $req->data->{activeTimer} = 0;

    while ( my ( $k, $v ) = each %$oidc_request ) {
        $self->p->setHiddenFormValue( $req, $k, $v, '', 0 );
    }

    return PE_CONFIRM;
}

sub _check_bypass_confirm {
    my ( $self, $req, $rp, $payload ) = @_;

    unless ($rp) {
        $self->userLogger->info(
                "ID Token hint azp doesn't match any known RP,"
              . " forcing confirmation" );
        return 0;
    }

    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsLogoutBypassConfirm} ) {

        my $sub     = $payload->{sub};
        my $user_id = $self->getUserIDForRP( $req, $rp, $req->{sessionInfo} );
        if ( $sub ne $user_id ) {
            $self->userLogger->info(
                    "ID Token hint sub $sub does not match user $user_id,"
                  . " forcing confirmation" );
            return 0;
        }

        my $sid = $payload->{sid};
        if ( $self->getSidFromSession( $rp, $req->{sessionInfo} ) ne $sid ) {
            $self->userLogger->info(
                    "ID Token hint `sid` does not match user session,"
                  . " forcing confirmation" );
            return 0;
        }
        $self->logger->debug("Bypass logout confirm for RP $rp");
        return 1;

    }
    return 0;

}

sub findRPFromUri {
    my ( $self, $uri, $option ) = @_;

    my $found_rp;
    foreach my $rp ( keys %{ $self->rpOptions } ) {
        $found_rp = $rp if $self->isUriAllowedForRP( $uri, $rp, $option );
    }
    return $found_rp;
}

sub isUriAllowedForRP {
    my ( $self, $uri, $rp, $option, $wildcard_allowed ) = @_;
    my $allowed_uris = $self->rpOptions->{$rp}->{$option} // "";
    $self->logger->debug("Allowed URIs for $rp: $allowed_uris");

    my $is_uri_allowed;
    if ($wildcard_allowed) {
        $is_uri_allowed =
          grep { _wildcard_match( $_, $uri ) } split( /\s+/, $allowed_uris );
    }
    else {
        $is_uri_allowed = grep { $_ eq $uri } split( /\s+/, $allowed_uris );
    }
    return $is_uri_allowed;
}

# Picks the first ACR value from the list that matches a known Authn Context
sub _get_authn_level_from_acr_values {
    my ( $self, $acr_values ) = @_;
    my @acr_values = split( /\s+/, $acr_values );
    for my $acr_value (@acr_values) {
        if ( my $level =
            $self->conf->{oidcServiceMetaDataAuthnContext}->{$acr_value} )
        {
            $self->logger->debug(
                "Authentication level $level selected from ACR value $acr_value"
            );

            return $level;
        }
    }
    return 0;
}

sub _wildcard_match {
    my ( $config_url, $candidate ) = @_;

    # Quote everything
    my $config_re = $config_url =~ s/(.)/\Q$1/gr;

    # Replace \* by .*
    $config_re =~ s/\\\*/.*/g;

    return ( $candidate =~ qr/^$config_re$/ ? 1 : 0 );
}

# Handle token endpoint
sub token {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect TOKEN URL");

    my ($rp) = $self->checkEndPointAuthenticationCredentials($req);
    return $self->invalidClientResponse($req) unless ($rp);

    my $grant_type = $req->param('grant_type') || '';

    # Autorization Code grant
    if ( $grant_type eq 'authorization_code' ) {
        return $self->_handleAuthorizationCodeGrant( $req, $rp );
    }

    # Refresh token
    elsif ( $grant_type eq 'refresh_token' ) {
        return $self->_handleRefreshTokenGrant( $req, $rp );
    }

    # Resource Owner Password Credenials
    elsif ( $grant_type eq 'password' ) {
        unless (
            $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowPasswordGrant} )
        {
            $self->logger->warn(
                "Access to grant_type=password, is not allowed for RP $rp");
            return $self->sendOIDCError( $req, 'unauthorized_client', 400 );
        }
        return $self->_handlePasswordGrant( $req, $rp );
    }

    # Resource Owner Password Credenials
    elsif ( $grant_type eq 'client_credentials' ) {
        unless ( $self->rpOptions->{$rp}
            ->{oidcRPMetaDataOptionsAllowClientCredentialsGrant} )
        {
            $self->logger->warn(
                "Access to Client Credentials grant is not allowed for RP $rp");
            return $self->sendOIDCError( $req, 'unauthorized_client', 400 );
        }
        return $self->_handleClientCredentialsGrant( $req, $rp );
    }

    # OAuth2.0 Token Exchange
    elsif ( $grant_type eq 'urn:ietf:params:oauth:grant-type:token-exchange' ) {
        return $self->_handleTokenExchange( $req, $rp );
    }

    # Unknown or unspecified grant type
    else {
        $self->userLogger->error(
            $grant_type
            ? "Unknown grant type: $grant_type"
            : "Missing grant_type parameter"
        );
        return $self->sendOIDCError( $req, 'unsupported_grant_type', 400 );
    }

}

# RFC6749 section 4.4
sub _handleClientCredentialsGrant {
    my ( $self, $req, $rp ) = @_;

    # The client credentials grant type MUST only be used by confidential
    # clients.
    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsPublic} ) {
        $self->logger->error(
            "Client Credentials grant cannot be used on public clients");
        return $self->sendOIDCError( $req, 'unauthorized_client', 400 );
    }
    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    # Populate minimal session info
    my $req_scope = $req->param('scope') || '';
    my $scope     = $self->getScope( $req, $rp, $req_scope );

    unless ($scope) {
        $self->userLogger->warn( 'Client '
              . $client_id
              . " was not granted any requested scopes ($req_scope) for $rp" );
        return $self->sendOIDCError( $req, 'invalid_scope', 400 );
    }

    my $infos = {
        $self->conf->{whatToTrace} => $client_id,
        _clientId                  => $client_id,
        _clientConfKey             => $rp,
        _scope                     => $scope,
        _utime                     => time,
    };

    my $h = $self->p->processHook( $req, 'oidcGotClientCredentialsGrant',
        $infos, $rp );
    return $self->sendOIDCError( $req, 'server_error', 500 ) if ( $h != PE_OK );

    # Update scope in case hook changed it
    $scope = $infos->{_scope};

    # Run rule against session info
    if ( my $rule = $self->rpRules->{$rp} ) {
        my $ruleVariables =
          { %{ $infos || {} }, _oidc_grant_type => "clientcredentials", };
        unless ( $rule->( $req, $ruleVariables ) ) {
            $self->userLogger->warn(
                    "Relying party $rp did not validate the provided "
                  . "Access Rule during Client Credentials Grant" );
            return $self->sendOIDCError( $req, 'invalid_grant', 400 );
        }
    }

    # Create access token
    my $session = $self->p->getApacheSession( undef, info => $infos );
    unless ($session) {
        $self->logger->error("Unable to create session");
        return $self->sendOIDCError( $req, 'server_error', 500 );
    }

    my $access_token = $self->newAccessToken(
        $req, $rp, $scope,
        $session->data,
        {
            scope           => $scope,
            rp              => $rp,
            user_session_id => $session->id,
            grant_type      => "clientcredentials",
        }
    );
    unless ($access_token) {
        $self->userLogger->error("Unable to create Access Token");
        return $self->sendOIDCError( $req,
            'Unable to create Access Token', 500 );
    }

    my $expires_in =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        ( ( $req_scope ne $scope ) ? ( scope => "$scope" ) : () ),
    };

    $self->logger->debug("Send token response");
    return $self->p->sendJSONresponse( $req, $token_response );
}

# OAuth 2.0 Token Exchange - RFC8693
sub _handleTokenExchange {
    my ( $self, $req, $rp ) = @_;

    my $h = $self->p->processHook( $req, 'oidcGotTokenExchange', $rp );
    if ( $h == PE_SENDRESPONSE ) {
        return $req->response;
    }

    $self->logger->error("Unsupported OAuth 2.0 Token Exchange request");
    return $self->sendOIDCError( $req, 'invalid_request', 400 );
}

sub _handlePasswordGrant {
    my ( $self, $req, $rp ) = @_;
    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $req_scope = $req->param('scope') || '';
    my $username  = $req->param('username');
    my $password  = $req->param('password');

    unless ( $username and $password ) {
        $self->logger->error("Missing username or password");
        return $self->sendOIDCError( $req, 'invalid_request', 400 );
    }

    ####
    # Authenticate user by running through the regular login process
    # minus the buildCookie step
    $req->parameters->{user}     = ($username);
    $req->parameters->{password} = $password;
    $req->data->{skipToken}      = 1;

    # This makes Auth::Choice use authChoiceAuthBasic if defined
    $req->data->{_pwdCheck} = 1;

    $req->steps( [
            @{ $self->p->beforeAuth },
            $self->p->authProcess,
            @{ $self->p->betweenAuthAndData },
            $self->p->sessionData,
            @{ $self->p->afterData },
            'storeHistory',
            @{ $self->p->endAuth },
        ]
    );
    my $result = $self->p->process($req);

    if (    ( $result == PE_FIRSTACCESS )
        and ( $self->conf->{authentication} eq "Choice" ) )
    {
        $self->logger->warn(
                "Choice module did not know which module to choose. "
              . "You should define authChoiceAuthBasic or specify desired module in the URL"
        );
    }

    $self->logger->debug( "Credentials check returned "
          . $self->p->_formatProcessResult($result) )
      if $result;

    ## Make sure we returned successfuly from the process AND we were able to create a session
    return $self->sendOIDCError( $req, 'invalid_grant', 400 )
      unless ( $result == PE_OK and $req->id and $req->user );

    ## Make sure the current user is allowed to use this RP
    if ( my $rule = $self->rpRules->{$rp} ) {
        my $ruleVariables =
          { %{ $req->sessionInfo || {} }, _oidc_grant_type => "password", };
        unless ( $rule->( $req, $ruleVariables ) ) {
            $self->userLogger->warn( 'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is not authorized to access to $rp" );
            $self->p->deleteSession($req);
            return $self->sendOIDCError( $req, 'invalid_grant', 400 );
        }
    }

    # Resolve scopes
    my $scope = $self->getScope( $req, $rp, $req_scope );
    unless ($scope) {
        $self->userLogger->warn( 'User '
              . $req->sessionInfo->{ $self->conf->{whatToTrace} }
              . " was not granted any requested scopes ($req_scope) for $rp" );
        return $self->sendOIDCError( $req, 'invalid_scope', 400 );
    }

    my $user_id = $self->getUserIDForRP( $req, $rp, $req->sessionInfo );

    $self->logger->debug(
        $user_id
        ? "Found corresponding user: $user_id"
        : 'Corresponding user not found'
    );

    # Generate access_token
    my $access_token = $self->newAccessToken(
        $req, $rp, $scope,
        $req->sessionInfo,
        {
            grant_type      => "password",
            user_session_id => $req->id,
        }
    );

    unless ($access_token) {
        $self->userLogger->error("Unable to create Access Token");
        return $self->sendOIDCError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated access token: $access_token");

    # Generate refresh_token
    my $refresh_token = undef;

    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsRefreshToken} ) {
        my $refreshTokenSession = $self->_generateRefreshToken(
            $req, $rp,
            {
                scope           => $scope,
                client_id       => $client_id,
                user_session_id => $req->id,
                grant_type      => "password",
            },
            0,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->sendOIDCError( $req,
                'Could not create refresh token session', 500 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated refresh token: $refresh_token");
    }

    # Generate ID token
    my $id_token = undef;
    if ( $self->_hasScope( "openid", $scope ) ) {

        # Compute hash to store in at_hash
        my $alg =
          $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
        my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
        my $at_hash = $self->createHash( $access_token, $hash_level )
          if $hash_level;

        $id_token =
          $self->_generateIDToken( $req, $rp, $scope, $req->sessionInfo, 0,
            { ( $at_hash ? ( at_hash => $at_hash ) : () ), } );

        unless ($id_token) {
            $self->logger->error(
                "Failed to generate ID Token for service: $client_id");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }
    }

    # Send token response
    my $expires_in =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        ( ( $scope ne $req_scope ) ? ( scope => "$scope" )       : () ),
        ( $refresh_token ? ( refresh_token => "$refresh_token" ) : () ),
        ( $id_token      ? ( id_token      => "$id_token" )      : () ),
    };

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

sub _handleAuthorizationCodeGrant {
    my ( $self, $req, $rp ) = @_;
    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $code      = $req->param('code');

    unless ($code) {
        $self->logger->error("No code found on token endpoint");
        return $self->sendOIDCError( $req, 'invalid_request', 400 );
    }

    my $codeSession = $self->getAuthorizationCode($code);
    unless ($codeSession) {
        $self->logger->warn("Unable to find OIDC session $code");
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    $codeSession->remove();

    # Check PKCE
    unless (
        $self->validatePKCEChallenge(
            $req->param('code_verifier'),
            $codeSession->data->{'code_challenge'},
            $codeSession->data->{'code_challenge_method'}
        )
      )
    {
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    # Check we have the same client_id value
    unless ( $client_id eq $codeSession->data->{client_id} ) {
        $self->userLogger->error( "Provided client_id does not match "
              . $codeSession->data->{client_id} );
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    # Check we have the same redirect_uri value
    unless ( $req->param("redirect_uri") eq $codeSession->data->{redirect_uri} )
    {
        $self->userLogger->error( "Provided redirect_uri does not match: "
              . $codeSession->data->{redirect_uri} . ' != '
              . $req->param("redirect_uri") );
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    # Get user identifier
    my $apacheSession =
      $self->p->getApacheSession( $codeSession->data->{user_session_id} );

    unless ($apacheSession) {
        $self->userLogger->warn("Unable to find user session");
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    my $user_id = $self->getUserIDForRP( $req, $rp, $apacheSession->data );

    $self->logger->debug("Found corresponding user: $user_id");

    my $req_scope = $codeSession->{data}->{req_scope};
    my $scope     = $codeSession->{data}->{scope};

    # Generate access_token
    my $access_token = $self->newAccessToken(
        $req, $rp, $scope,
        $apacheSession->data,
        {
            grant_type      => "authorizationcode",
            user_session_id => $apacheSession->id,
        }
    );

    unless ($access_token) {
        $self->userLogger->error("Unable to create Access Token");
        return $self->sendOIDCError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated access token: $access_token");

    # Generate refresh_token
    my $refresh_token = undef;

    my $sid = $self->getSidFromSession( $rp, $apacheSession->data );

    # For offline access, the refresh token isn't tied to the session ID
    if ( $codeSession->{data}->{offline} ) {

        # We need to remove _sessionType, _sessionid , _utime and _lastSeen
        # from the session data before storing session data in the refresh
        # token
        my %userInfo;
        for my $userKey (
            grep !/^(_session|_utime$|_lastSeen$)/,
            keys %{ $apacheSession->data }
          )
        {
            $userInfo{$userKey} = $apacheSession->data->{$userKey};
        }
        my $refreshTokenSession = $self->_generateRefreshToken(
            $req, $rp,
            {
                %userInfo,
                redirect_uri => $codeSession->data->{redirect_uri},
                scope        => $scope,
                client_id    => $client_id,
                _session_uid =>
                  $apacheSession->data->{ $self->conf->{whatToTrace} },
                auth_time  => $apacheSession->data->{_lastAuthnUTime},
                grant_type => "authorizationcode",
                _oidc_sid  => $sid,
            },
            1,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated offline refresh token: $refresh_token");
    }

    # For online access, if configured
    elsif ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsRefreshToken} ) {
        my $refreshTokenSession = $self->_generateRefreshToken(
            $req,

            $rp,
            {
                redirect_uri => $codeSession->data->{redirect_uri},
                scope        => $scope,
                client_id    => $client_id,
                _session_uid =>
                  $apacheSession->data->{ $self->conf->{whatToTrace} },
                user_session_id => $codeSession->data->{user_session_id},
                grant_type      => "authorizationcode",
                _oidc_sid       => $sid,
            },
            0,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated online refresh token: $refresh_token");
    }

    # Compute hash to store in at_hash
    my $alg = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
    my $at_hash      = $self->createHash( $access_token, $hash_level )
      if $hash_level;

    # Create ID Token
    my $nonce    = $codeSession->data->{nonce};
    my $id_token = $self->_generateIDToken(
        $req, $rp, $scope,
        $apacheSession->data,
        0,
        {
            ( $nonce   ? ( nonce   => $nonce )   : () ),
            ( $at_hash ? ( at_hash => $at_hash ) : () ),
        },
    );

    unless ($id_token) {
        $self->logger->error(
            "Failed to generate ID Token for service: $client_id");
        return $self->sendOIDCError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated id token: $id_token");

    # Send token response
    my $expires_in =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        id_token     => "$id_token",
        ( $refresh_token ? ( refresh_token => "$refresh_token" ) : () ),
        ( ( $req_scope ne $scope ) ? ( scope => "$scope" )       : () ),
    };

    $self->p->processHook( $req, 'oidcGenerateTokenResponse', $rp,
        $token_response, $codeSession->data, $apacheSession->data );

    my %update;

    # This is kept for compatibility in case some plugins use it
    my $cRP = $apacheSession->data->{_oidcConnectedRP} || '';
    unless ( grep { $_ eq $rp } split( ",", $cRP ) ) {
        %update = ( %update, _oidcConnectedRP => "$rp,$cRP" );
    }

    my $cRPID = $apacheSession->data->{_oidcConnectedRPIDs} || '';
    unless ( grep { $_ eq $client_id } split( ",", $cRPID ) ) {
        %update = ( %update, _oidcConnectedRPIDs => "$client_id,$cRPID" );
    }

    if (%update) {
        $self->p->updateSession( $req, \%update, $apacheSession->id );
    }

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

sub _handleRefreshTokenGrant {
    my ( $self, $req, $rp, $refresh_token, $client_id ) = @_;
    $client_id     ||= $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};
    $refresh_token ||= $req->param('refresh_token');

    unless ($refresh_token) {
        $self->logger->error("Missing refresh_token parameter");
        return $self->sendOIDCError( $req, 'invalid_request', 400 );
    }

    $self->logger->debug("OpenID Refresh Token: $refresh_token");

    my $refreshSession = $self->getRefreshToken($refresh_token);

    unless ($refreshSession) {
        $self->logger->warn("Unable to find OIDC session $refresh_token");
        return $self->sendOIDCError( $req, 'invalid_request', 400 );
    }

    $refreshSession =
      $self->_rotateRefreshSession( $req, $rp, $refreshSession );

    # Check we have the same client_id value
    unless ( $client_id eq $refreshSession->data->{client_id} ) {
        $self->userLogger->error( "Provided client_id does not match "
              . $refreshSession->data->{client_id} );
        return $self->sendOIDCError( $req, 'invalid_grant', 400 );
    }

    my $access_token;
    my $userData;

    # If this refresh token is tied to a SSO session
    if ( $refreshSession->data->{user_session_id} ) {
        my $user_session_id = $refreshSession->data->{user_session_id};
        $userData =
          $self->p->HANDLER->retrieveSession( $req, $user_session_id );

        unless ($userData) {
            $self->logger->error(
                "Unable to find user session tied to Refresh Token");
            return $self->sendOIDCError( $req, 'invalid_grant', 400 );
        }

        my $h = $self->p->processHook( $req, 'oidcGotOnlineRefresh', $rp,
            $refreshSession->data, $userData );
        if ( $h != PE_OK ) {
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        # Generate access_token
        $access_token = $self->newAccessToken(
            $req, $rp,
            $refreshSession->data->{scope},
            $userData,
            {
                user_session_id => $user_session_id,
                grant_type      => $refreshSession->data->{grant_type},
            }
        );

        unless ($access_token) {
            $self->userLogger->error("Unable to create Access Token");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        $self->logger->debug("Generated access token: $access_token");
    }

    # Else, we are in an offline session
    else {

        unless ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowOffline} )
        {
            $self->logger->error(
                'Got a offline refresh_token for an application no more allowed'
            );
            return $self->sendOIDCError( $req, 'invalid_grant', 400 );
        }

        # Lookup attributes and macros for user
        $self->getAttributesForUser( $req, $refreshSession )
          or return $self->sendOIDCError( $req, 'invalid_grant', 400 );

        # Cleanup sessionInfo
        delete $req->sessionInfo->{_utime};
        delete $req->sessionInfo->{_startTime};
        delete $req->sessionInfo->{_lastSeen};

        # Update refresh session
        $self->updateRefreshToken( $refreshSession->id, $req->sessionInfo );
        $userData = $refreshSession->data;
        for ( keys %{ $req->sessionInfo } ) {
            $refreshSession->data->{$_} = $req->sessionInfo->{$_};
        }

        my $h = $self->p->processHook( $req, 'oidcGotOfflineRefresh', $rp,
            $refreshSession->data );
        if ( $h != PE_OK ) {
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        # Generate access_token
        $access_token = $self->newAccessToken(
            $req, $rp,
            $refreshSession->data->{scope},
            $refreshSession->data,
            {
                offline_session_id => $refreshSession->id,
                grant_type         => $refreshSession->data->{grant_type},
            }
        );

        unless ($access_token) {
            $self->userLogger->error("Unable to create Access Token");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        $self->logger->debug("Generated access token: $access_token");
    }

    # Compute hash to store in at_hash
    my $alg = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg};
    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
    my $at_hash      = $self->createHash( $access_token, $hash_level )
      if $hash_level;

    # Create ID Token
    my $id_token = undef;
    if ( $self->_hasScope( 'openid', $refreshSession->data->{scope} ) ) {
        my $nonce = $refreshSession->data->{nonce};
        $id_token = $self->_generateIDToken(
            $req, $rp,
            $refreshSession->data->{scope},
            $userData,
            0,
            {
                ( $nonce   ? ( nonce   => $nonce )   : () ),
                ( $at_hash ? ( at_hash => $at_hash ) : () ),
            }
        );

        unless ($id_token) {
            $self->logger->error(
                "Failed to generate ID Token for service: $rp");
            return $self->sendOIDCError( $req, 'server_error', 500 );
        }

        $self->logger->debug("Generated id token: $id_token");
    }

    # Send token response
    my $expires_in =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $need_to_update_refresh_token =
      ( $refresh_token ne $refreshSession->id );

    my $token_response = {
        access_token => "$access_token",
        token_type   => 'Bearer',
        expires_in   => $expires_in + 0,
        (
            $need_to_update_refresh_token
            ? ( refresh_token => $refreshSession->id )
            : ()
        ),
        ( $id_token ? ( id_token => "$id_token" ) : () ),
    };

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

sub _rotateRefreshSession {
    my ( $self, $req, $rp, $refreshSession ) = @_;

    if ( $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsRefreshTokenRotation} )
    {
        $self->logger->debug("Creating new refresh token for $rp");

        my $newRefreshSession =
          $self->_generateRefreshToken( $req, $rp, $refreshSession->data );

        if ($newRefreshSession) {
            $self->logger->debug(
                "Generated new refresh token: " . $newRefreshSession->id );

            my $old_refresh_token = $refreshSession->id;
            if ( $refreshSession->remove ) {
                $self->logger->debug(
                    "Removed old refresh token: $old_refresh_token");
            }
            else {
                $self->logger->error(
                    "Failed to remove old refresh token $old_refresh_token: "
                      . $refreshSession->error );
            }

            return $newRefreshSession;

        }
        else {
            $self->logger->error(
                "Unable to create OIDC session for refresh_token");
            return $refreshSession;
        }
    }
    return $refreshSession;
}

sub unauthUserInfo {
    my ( $self, $req ) = @_;
    return $self->userInfo( $req, 1 );
}

# Handle userinfo endpoint
sub userInfo {
    my ( $self, $req, $setUser ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect USERINFO URL");

    my ( $access_token, $authMethod ) = $self->getEndPointAccessToken($req);

    unless ($access_token) {
        $self->logger->error("Unable to get access_token");
        return $self->returnBearerError( 'invalid_request',
            "Access token not found in request", 401 );
    }

    $self->logger->debug("Received Access Token $access_token");

    my $accessTokenSession = $self->getAccessToken($access_token);

    unless ($accessTokenSession) {
        $self->userLogger->error(
            "Unable to validate access token $access_token");
        return $self->returnBearerError( 'invalid_request',
            'Invalid request', 401 );
    }

    # Get access token session data
    my $scope           = $accessTokenSession->data->{scope};
    my $rp              = $accessTokenSession->data->{rp};
    my $user_session_id = $accessTokenSession->data->{user_session_id};

    $self->p->HANDLER->set_user( $req,
        $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID} )
      if $setUser;

    if ( $self->rpOptions->{$rp}
        ->{oidcRPMetaDataOptionsUserinfoRequireHeaderToken}
        and $authMethod ne 'header' )
    {
        $self->userLogger->error(
            'Endpoint authentication without using header');
        return $self->returnBearerError( 'invalid_request',
            'Invalid request', 400 );
    }

    # Make sure $rp has been lazy loaded
    if ( $accessTokenSession->data->{client_id} ) {
        $self->getRP( $accessTokenSession->data->{client_id} );
    }

    my $session =
      $self->_getSessionFromAccessTokenData( $accessTokenSession->data );
    unless ($session) {
        return $self->returnBearerError( 'invalid_request',
            'Invalid request', 401 );
    }

    my $userinfo_response =
      $self->buildUserInfoResponse( $req, $scope, $rp, $session );
    return $self->returnBearerError( 'invalid_request', 'Invalid request', 401 )
      unless ($userinfo_response);

    my $attr_str = join( ',', sort( keys(%$userinfo_response) ) );
    my $sub      = $userinfo_response->{sub};
    my $user     = $session->data->{ $self->conf->{whatToTrace} };
    $self->auditLog(
        $req,
        code    => "ISSUER_OIDC_USERINFO",
        rp      => $rp,
        message => (
"User information for $user transmitted to $rp as $sub with attributes $attr_str"
        ),
        user       => $user,
        oidc_sub   => $sub,
        attributes => $userinfo_response,
    );

    my $userinfo_sign_alg =
      $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsUserInfoSignAlg};

    unless ($userinfo_sign_alg) {
        my $debug_response = to_json($userinfo_response);
        utf8::downgrade($debug_response);
        $self->logger->debug( "Return UserInfo as JSON: " . $debug_response );
        return $self->p->sendJSONresponse( $req, $userinfo_response );

    }
    else {
        my $userinfo_jwt = $self->encryptToken(
            $rp,
            $self->createJWT( $userinfo_response, $userinfo_sign_alg, $rp ),
            $self->rpOptions->{$rp}
              ->{oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg},
            $self->rpOptions->{$rp}
              ->{oidcRPMetaDataOptionsUserInfoEncContentEncAlg},
        );
        $self->logger->debug("Return UserInfo as JWT: $userinfo_jwt");
        return [
            200,
            [
                'Content-Type'   => 'application/jwt',
                'Content-Length' => length($userinfo_jwt)
            ],
            [$userinfo_jwt]
        ];
    }
}

sub _getSessionFromAccessTokenData {
    my ( $self, $tokenData ) = @_;
    my $session;

    # If using a refreshed access token
    if ( $tokenData->{user_session_id} ) {

        # Get user identifier
        $session = $self->p->getApacheSession( $tokenData->{user_session_id} );
        $self->logger->warn("Unable to find user session") unless ($session);
    }
    else {
        my $offline_session_id = $tokenData->{offline_session_id};
        if ($offline_session_id) {
            $session = $self->getRefreshToken($offline_session_id);
            $self->logger->warn("Unable to find refresh session")
              unless ($session);
        }
    }
    return $session;
}

sub introspection {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect INTROSPECTION URL");

    my ( $rp, $authMethod ) =
      $self->checkEndPointAuthenticationCredentials($req);
    return $self->invalidClientResponse($req) unless ($rp);

    if ( !$authMethod or $authMethod eq 'none' ) {
        $self->logger->error(
"Unauthenticated clients are not allowed to access the introspection endpoint"
        );
        return $self->sendOIDCError( $req, 'unauthorized_client', 401 );
    }

    my $token = $req->param('token');
    return $self->sendOIDCError( $req, 'invalid_request', 400 ) unless ($token);

    my $response    = { active => JSON::false };
    my $oidcSession = $self->getAccessToken($token);
    if ($oidcSession) {
        my $apacheSession =
          $self->_getSessionFromAccessTokenData( $oidcSession->{data} );
        if ($apacheSession) {

            $response->{active} = JSON::true;

        # The ID attribute we choose is the one of the calling webservice,
        # which might be different from the OIDC client the token was issued to.
            $response->{sub} =
              $self->getUserIDForRP( $req, $rp, $apacheSession->data );
            $response->{scope} = $oidcSession->{data}->{scope}
              if $oidcSession->{data}->{scope};
            $response->{client_id} = $oidcSession->{data}->{client_id}
              if $oidcSession->{data}->{client_id};
            $response->{iss} = $self->get_issuer($req);
            $response->{exp} =
              $oidcSession->{data}->{_utime} + $self->conf->{timeout};
        }
        else {
            $self->logger->warn("Count not find session tied to Access Token");
        }
    }
    return $self->p->sendJSONresponse( $req, $response );
}

# Endpoint JWKS is implemented in Lib/OpenIDConnect

# Handle register endpoint
sub registration {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect REGISTRATION URL");

    # TODO: check Initial Access Token

    # Specific message to allow DOS detection
    my $source_ip = $req->address;
    $self->logger->notice(
        "OpenID Connect Registration request from $source_ip");

    # Check dynamic registration is allowed
    unless ( $self->conf->{oidcServiceAllowDynamicRegistration} ) {
        $self->logger->error("Dynamic registration is not allowed");
        return $self->p->sendError( $req, 'server_error' );
    }

    # Get client metadata
    my $client_metadata_json = $req->content;
    return $self->p->sendError( $req, 'Missing POST data', 400 )
      unless ($client_metadata_json);

    $self->logger->debug("Client metadata received: $client_metadata_json");

    my $client_metadata = $self->decodeClientMetadata($client_metadata_json)
      or return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    my $registration_response = {};

    # Check redirect_uris
    my $redirect_uris = $client_metadata->{redirect_uris};
    unless ( $redirect_uris and ref($redirect_uris) eq 'ARRAY' ) {
        $self->logger->error("Field redirect_uris (array) is mandatory");
        return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    }
    else {
        foreach (@$redirect_uris) {
            if ( /^\s*((?:java|vb)script|data):/i
                or $self->p->checkXSSAttack( 'redirect_uri', $_ ) )
            {
                $self->userLogger->error(
                    "Registration tried with a forbidden redirect_uri: $_");
                return $self->p->sendError( $req, 'invalid_client_metadata',
                    400 );
            }
        }
    }

    # RP identifier
    my $registration_time = time;
    my $rp                = "register-$registration_time";

    # Generate Client ID and Client Password
    my $client_id     = random_string(RS_MSK);
    my $client_secret = random_string(RS_MSK);

    # Register known parameters
    my $client_name =
      $client_metadata->{client_name} || "Self registered client";
    my $logo_uri = $client_metadata->{logo_uri};
    my $id_token_signed_response_alg =
      $client_metadata->{id_token_signed_response_alg}
      || ( $self->conf->{oidcServiceKeyTypeSig} eq 'EC' ? 'ES256' : 'RS256' );
    my $userinfo_signed_response_alg =
      $client_metadata->{userinfo_signed_response_alg};
    my $request_uris           = $client_metadata->{request_uris};
    my $backchannel_logout_uri = $client_metadata->{backchannel_logout_uri};
    my $backchannel_logout_session_required =
      $client_metadata->{backchannel_logout_session_required};
    my $frontchannel_logout_uri = $client_metadata->{backchannel_logout_uri};
    my $frontchannel_logout_session_required =
      $client_metadata->{frontchannel_logout_session_required};
    my $jwksUri = $client_metadata->{jwks_uri};
    my $encryptedResponseAlg =
      $client_metadata->{id_token_encrypted_response_alg};
    my $encryptedResponseEnc =
      $client_metadata->{id_token_encrypted_response_enc};
    my $userInfoEncAlg = $client_metadata->{userinfo_encrypted_response_alg};
    my $userInfoEncEnc = $client_metadata->{userinfo_encrypted_response_enc};

    # Register RP in global configuration
    my $conf = $self->confAcc->getConf( { raw => 1, noCache => 1 } );

    $conf->{cfgAuthor}   = "OpenID Connect Registration ($client_name)";
    $conf->{cfgAuthorIP} = $source_ip;
    $conf->{cfgVersion}  = $VERSION;

    $conf->{oidcRPMetaDataExportedVars}->{$rp} = {};
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsClientID} =
      $client_id;
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsClientSecret}
      = $client_secret;
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsDisplayName} =
      $client_name;
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsIcon} =
      $logo_uri;
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsIDTokenSignAlg}
      = $id_token_signed_response_alg;
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsRedirectUris}
      = join( ' ', @$redirect_uris );
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsRequestUris} =
      join( ' ', @$request_uris )
      if $request_uris and @$request_uris;
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserInfoSignAlg} = $userinfo_signed_response_alg
      if defined $userinfo_signed_response_alg;

    if ($frontchannel_logout_uri) {
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsLogoutType}
          = 'front';
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsLogoutUrl}
          = $frontchannel_logout_uri;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsLogoutSessionRequired} =
          $frontchannel_logout_session_required;
    }
    elsif ($backchannel_logout_uri) {
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsLogoutType}
          = 'back';
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsLogoutUrl}
          = $backchannel_logout_uri;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsLogoutSessionRequired} =
          $backchannel_logout_session_required;
    }
    $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsJwksUri} =
      $jwksUri
      if $jwksUri;
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg} = $encryptedResponseAlg
      if $encryptedResponseAlg;
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIdTokenEncContentEncAlg} = $encryptedResponseEnc
      if $encryptedResponseEnc;
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg} = $userInfoEncAlg
      if $userInfoEncAlg;
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserInfoEncContentEncAlg} = $userInfoEncEnc
      if $userInfoEncEnc;

    # TODO "jwks" support (when jwks_uri isn't available

    # Exported Vars
    if (
        ref( $self->conf->{oidcServiceDynamicRegistrationExportedVars} ) eq
        'HASH' )
    {
        $conf->{oidcRPMetaDataExportedVars}->{$rp} =
          $self->conf->{oidcServiceDynamicRegistrationExportedVars};
    }

    # Extra claims
    if (
        ref( $self->conf->{oidcServiceDynamicRegistrationExtraClaims} ) eq
        'HASH' )
    {
        $conf->{oidcRPMetaDataOptionsExtraClaims}->{$rp} =
          $self->conf->{oidcServiceDynamicRegistrationExtraClaims};
    }

    if ( $self->confAcc->saveConf($conf) > 0 ) {

        # Send registration response
        $registration_response->{'client_id'}            = $client_id;
        $registration_response->{'client_secret'}        = $client_secret;
        $registration_response->{'client_id_issued_at'}  = $registration_time;
        $registration_response->{'client_id_expires_at'} = 0;
        $registration_response->{'client_name'}          = $client_name;
        $registration_response->{'logo_uri'}             = $logo_uri;
        $registration_response->{'id_token_signed_response_alg'} =
          $id_token_signed_response_alg;
        $registration_response->{'redirect_uris'} = $redirect_uris;
        $registration_response->{'request_uris'}  = $request_uris
          if $request_uris and @$request_uris;
        $registration_response->{'userinfo_signed_response_alg'} =
          $userinfo_signed_response_alg
          if defined $userinfo_signed_response_alg;
    }
    else {
        $self->logger->error(
            "Configuration not saved: $Lemonldap::NG::Common::Conf::msg");
        return $self->p->sendError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Registration response sent");
    return $self->p->sendJSONresponse( $req, $registration_response,
        code => 201 );
}

# Handle logout endpoint for unauthenticated users
sub endSessionDone {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL  detected as an OpenID Connect END SESSION URL");
    $self->logger->debug("User is already logged out");

    my $post_logout_redirect_uri = $req->param('post_logout_redirect_uri');
    my $state                    = $req->param('state');

    if ($post_logout_redirect_uri) {

        unless (
            $self->findRPFromUri(
                $post_logout_redirect_uri,
                'oidcRPMetaDataOptionsPostLogoutRedirectUris'
            )
          )
        {
            $self->logger->error("$post_logout_redirect_uri is not allowed");
            return $self->p->login($req);
        }

        # Build Response
        my $response_url =
          $self->buildLogoutResponse( $post_logout_redirect_uri, $state );

        $self->logger->debug("Redirect user to $response_url");
        return [ 302, [ Location => $response_url ], [] ];
    }

    # Else, normal login process
    return $self->p->login($req);
}

# Handle checksession endpoint
sub checkSession {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    $self->logger->debug("URL detected as an OpenID Connect CHECK SESSION URL");

    # TODO: access_control_allow_origin => '*'
    $req->frame(1);
    return $self->p->sendHtml(
        $req,
        '../common/oidc_checksession',
        params => {
            COOKIENAME => $self->conf->{cookieName},
        }
    );
}

sub logout {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    my $code = PE_OK;
    if ( my $s = $req->userData->{_oidcConnectedRPIDs} ) {
        my @rps = grep /\w/, split( ',', $s );
        foreach my $client_id (@rps) {
            my $rp = $self->getRP($client_id);
            if ( !$rp ) {
                $self->logger->warn(
                    "Cannot find RP configuration for $client_id");
                $code = PE_SLO_ERROR;
                next;
            }
            my $rpConf = $self->rpOptions->{$rp};
            if ( !$rpConf ) {
                $self->logger->warn("Cannot find RP options for $client_id");
                $code = PE_SLO_ERROR;
                next;
            }
            if ( my $url = $rpConf->{oidcRPMetaDataOptionsLogoutUrl} ) {

                # FRONT CHANNEL
                if ( $rpConf->{oidcRPMetaDataOptionsLogoutType} eq 'front' ) {
                    if ( $rpConf->{oidcRPMetaDataOptionsLogoutSessionRequired} )
                    {
                        $url .= ( $url =~ /\?/ ? '&' : '?' )
                          . build_urlencoded(
                            iss => $self->get_issuer($req),
                            sid => $self->getSidFromSession(
                                $rp, $req->{sessionInfo}
                            )
                          );
                    }
                    $req->info( qq'<iframe src="$url" class="noborder">'
                          . '</iframe>' );
                }

                # BACK CHANNEL
                elsif ( $rpConf->{oidcRPMetaDataOptionsLogoutType} eq 'back' ) {

                    # Logout token must contain:
                    #  - iss: issuer identifier
                    #  - sub: subject id (user id)
                    #  OR/AND
                    #  - sid: OP session id given to the RP
                    #  - aud: audience
                    #  - iat: issue at time
                    #  - jti: JWT token id
                    #  - events: should be :
                    #   { 'http://schemas.openid.net/event/backchannel-logout"
                    #     => {} } # or a JSON object
                    #
                    # Logout token should be send using a POST request:
                    #
                    #   POST /backChannelUri HTTP/1.1
                    #   Host: rp
                    #   Content-Type: application/x-www-form-urlencoded
                    #
                    #   logout_token=<JWT value>
                    #
                    # RP response should be 200 (204 accepted) or 400 for errors
                    my $alg =
                      $self->rpOptions->{$rp}
                      ->{oidcRPMetaDataOptionsAccessTokenSignAlg}
                      || (
                        $self->conf->{oidcServiceKeyTypeSig} eq 'EC'
                        ? 'ES256'
                        : 'RS256'
                      );
                    $self->logger->debug(
                        "Access Token signature algorithm: $alg");
                    my $userId =
                      $self->getUserIDForRP( $req, $rp, $req->userData );
                    my $logoutToken = {
                        iss => $self->get_issuer($req),
                        sub => $userId,
                        aud => $self->getAudiences($rp),
                        iat => time,

                        # Random string: no response expected from RP
                        jti => join( "",
                            map { [ "0" .. "9", 'A' .. 'Z' ]->[ rand 36 ] }
                              1 .. 8 ),
                        events => { $self->BACKCHANNEL_EVENTSKEY => {} },
                    };
                    if ( $self->rpOptions->{$rp}
                        ->{oidcRPMetaDataOptionsLogoutSessionRequired} )
                    {
                        $logoutToken->{sid} =
                          $self->getSidFromSession( $rp, $req->{sessionInfo} );
                    }
                    $self->logger->debug( "Logout token content: "
                          . JSON::to_json($logoutToken) );
                    my $jwt = $self->encryptToken(
                        $rp,
                        $self->createJWT( $logoutToken, $alg, $rp ),
                        $self->rpOptions->{$rp}
                          ->{oidcRPMetaDataOptionsLogoutEncKeyMgtAlg},
                        $self->rpOptions->{$rp}
                          ->{oidcRPMetaDataOptionsLogoutEncContentEncAlg},
                    );
                    my $resp = $self->ua->post(
                        $url,
                        { logout_token => $jwt },
                        'Content-Type' => 'application/x-www-form-urlencoded',
                    );
                    if ( $resp->is_error ) {
                        $self->logger->warn(
                                "OIDC back channel: unable to unlog"
                              . " $userId from $rp: "
                              . $resp->message );
                        $self->logger->debug("Logout token: $jwt");
                        $self->logger->debug(
                            'Upstream status: ' . $resp->status_line );
                        $self->logger->debug(
                            'Upstream response: ' . ( $resp->content // '' ) );
                        $code = PE_SLO_ERROR;
                    }
                    else {
                        $self->logger->info(
                            "OIDC back channel: user $userId unlogged from $rp"
                        );
                    }
                }
            }
        }
    }
    return $code;
}

# Internal methods

sub metadata {
    my ( $self, $req ) = @_;
    $req->data->{dropCsp} = 1 if $self->conf->{oidcDropCspHeaders};
    my %args;
    $args{ttl} = $self->conf->{oidcServiceMetadataTtl}
      if $self->conf->{oidcServiceMetadataTtl};
    return $self->p->sendJSONresponse( $req,
        $self->metadataDoc( $self->get_issuer($req) ), %args );
}

# Store request parameters in %ENV
sub exportRequestParameters {
    my ( $self, $req ) = @_;

    if ( my $p = $req->param('prompt') ) {
        if ( $p eq 'none' ) {
            return $self->_unauthPromptNone($req);
        }
    }

    foreach my $param (
        qw/response_type scope client_id state redirect_uri nonce
        response_mode display prompt max_age ui_locales id_token_hint
        login_hint acr_values request request_uri/
      )
    {
        if ( $req->param($param) ) {
            $req->env->{ "llng_oidc_" . $param } = $req->param($param);
        }
    }

    my $rp;
    if ( $req->param('client_id') ) {
        $rp = $self->getRP( $req->param('client_id') );
        if ($rp) {
            $req->env->{"llng_oidc_rp"} = $rp;
        }
    }

    # Extract request_uri/request parameter
    my $request = $req->param('request');
    if ( my $request_uri = $req->param('request_uri') ) {
        if (
            $rp
            and $self->isUriAllowedForRP(
                $request_uri, $rp, 'oidcRPMetaDataOptionsRequestUris', 1
            )
          )
        {
            $request = $self->getRequestJWT($request_uri);
        }
    }

    if ($request) {
        my $request_data = getJWTPayload($request);
        foreach ( keys %$request_data ) {
            $req->env->{ "llng_oidc_" . $_ } = $request_data->{$_};
        }
    }

    # Store target authentication level in pdata
    if ($rp) {
        my $targetAuthnLevel = $self->rpLevelRules->{$rp}->( $req, {} );

        if ( my $acr_values = $req->env->{'llng_oidc_acr_values'} ) {
            $targetAuthnLevel =
              $self->_get_authn_level_from_acr_values($acr_values);
        }

        $req->pdata->{targetAuthnLevel} = $targetAuthnLevel
          if $targetAuthnLevel;
    }

    return PE_OK;
}

sub _unauthPromptNone {
    my ( $self, $req ) = @_;
    my $res = $self->_checkErrorsInAuthorizeEndpoint($req);
    return $res if $res;

    my $oidc_request = $req->data->{_oidc_request};
    my $uri          = $oidc_request->{redirect_uri};
    $uri =
        $uri
      . ( $uri =~ /\?/ ? '&' : '?' )
      . build_urlencoded(
        error => 'login_required',
        ( $oidc_request->{state} ? ( state => $oidc_request->{state} ) : () ),
      );
    return $self->_redirectToUrl( $req, $uri );
}

sub _hasScope {
    my ( $self, $scope, $scopelist ) = @_;
    return scalar grep { $_ eq $scope } ( split /\s+/, $scopelist );
}

sub _convertOldFormatConsents {
    my ( $self, $req ) = @_;
    my @oidcConsents = ();
    my @rps          = ();
    my $scope        = '';
    my $epoch        = '';
    my $rp           = '';
    unless ( $req->{sessionInfo} ) {
        $self->logger->error("Corrupted session");
        return PE_ERROR;
    }

    # Search Relying Parties
    $self->logger->debug(
        "Searching for previously registered Relying Parties...");
    foreach ( keys %{ $req->{sessionInfo} } ) {
        if ( $_ =~ /^_oidc_consent_scope_([\w-]+)$/ ) {
            push @rps, $1;
            $self->logger->debug("Found RP $1");
        }
    }

    # Convert OIDC Consents format
    $self->logger->debug("Convert Relying Party Consent(s)...");
    my $count = 0;
    foreach (@rps) {
        $scope = $req->{sessionInfo}->{ "_oidc_consent_scope_" . $_ };
        $epoch = $req->{sessionInfo}->{ "_oidc_consent_time_" . $_ };
        $rp    = $_;

        if ( $scope and $epoch and $rp ) {
            $self->logger->debug("Append RP $rp Consent");
            push @oidcConsents, { rp => $rp, scope => $scope, epoch => $epoch };
            $count++;
            $self->logger->debug("Delete Key -> _oidc_consent_scope_$_");
            $self->p->updatePersistentSession( $req,
                { "_oidc_consent_scope_" . $_ => undef } );
            $self->logger->debug("Delete Key -> _oidc_consent_time_$_");
            $self->p->updatePersistentSession( $req,
                { "_oidc_consent_time_" . $_ => undef } );
        }
        else {
            $self->logger->debug( "Corrupted Consent / Session -> "
                  . "RP=$rp, Scope=$scope, Epoch=$epoch" );
            return PE_ERROR;
        }
    }

    # Update persistent session
    $self->p->updatePersistentSession( $req,
        { _oidcConsents => to_json( \@oidcConsents ) } )
      if $count;
    return $count;
}

sub _generateRefreshToken {
    my ( $self, $req, $rp, $info, $offline ) = @_;

    my $user  = $info->{_session_uid};
    my $token = $self->newRefreshToken( $rp, $info, $offline );
    if ($token) {
        my $offline_str = ( $offline ? 'Offline ' : '' );
        $self->auditLog(
            $req,
            code    => "ISSUER_OIDC_REFRESH_TOKEN",
            rp      => $rp,
            message =>
              ( "${offline_str}Refresh Token for $user generated for $rp", ),
            user    => $user,
            offline => ( $offline ? 1 : 0 ),
        );
    }
    return $token;
}

sub _generateIDToken {
    my ( $self, $req, $rp, $scope, $sessionInfo, $release_user_claims,
        $extra_claims, $sid )
      = @_;

    $sid ||= $self->getSidFromSession( $rp, $sessionInfo );
    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    my $id_token_exp =
         $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsIDTokenExpiration}
      || $self->conf->{oidcServiceIDTokenExpiration};
    $id_token_exp += time;

    my $authenticationLevel = $sessionInfo->{authenticationLevel} || 0;

    my $id_token_acr = "loa-$authenticationLevel";
    foreach ( keys %{ $self->conf->{oidcServiceMetaDataAuthnContext} } ) {
        if ( $self->conf->{oidcServiceMetaDataAuthnContext}->{$_} eq
            $authenticationLevel )
        {
            $id_token_acr = $_;
            last;
        }
    }

    my $sub = $self->getUserIDForRP( $req, $rp, $sessionInfo );

    my $amr = $self->getAmr( $req, $rp, $sessionInfo );

    my $id_token_payload_hash = {
        iss       => $self->get_issuer($req),            # Issuer Identifier
        sub       => $sub,                               # Subject Identifier
        aud       => $self->getAudiences($rp),           # Audience
        exp       => $id_token_exp,                      # expiration
        iat       => time,                               # Issued time
        auth_time => $sessionInfo->{_lastAuthnUTime},    # Authentication time
        acr       => $id_token_acr,  # Authentication Context Class Reference
        azp       => $client_id,     # Authorized party, this is used for logout
        ( @$amr ? ( amr => $amr ) : () ),
        sid => $sid,
    };

    for ( keys %{$extra_claims} ) {
        $id_token_payload_hash->{$_} = $extra_claims->{$_}
          if $extra_claims->{$_} and not $id_token_payload_hash->{$_};
    }

    # Decided by response_type or forced in RP config
    my $attribute_claims = {};
    if ( $release_user_claims || $self->force_id_claims($rp) ) {

        $attribute_claims =
          $self->buildUserInfoResponseFromData( $req, $scope, $rp,
            $sessionInfo );

        foreach ( keys %$attribute_claims ) {
            $id_token_payload_hash->{$_} = $attribute_claims->{$_}
              unless ( $_ eq "sub" or $_ eq "sid" );
        }
    }

    my $attr_str = (
        keys %$attribute_claims
        ? ( " with attributes "
              . join( ',', sort( keys(%$attribute_claims) ) ) )
        : ''
    );
    my $user = $sessionInfo->{ $self->conf->{whatToTrace} };
    $self->auditLog(
        $req,
        code       => "ISSUER_OIDC_ID_TOKEN",
        rp         => $rp,
        message    => ("ID Token for $user generated for $rp as $sub$attr_str"),
        user       => $user,
        oidc_sub   => $sub,
        attributes => $attribute_claims,
    );

    # Create ID Token
    return $self->createIDToken( $req, $id_token_payload_hash, $rp );
}

sub getAmr {
    my ( $self, $req, $rp, $sessionInfo ) = @_;
    my $result = [];

    my $client_id = $self->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID};

    for my $amr_value ( sort keys %{ $self->amrRules } ) {
        my $richSessionInfo = {
            %{ $sessionInfo || {} },
            _clientId      => $client_id,
            _clientConfKey => $rp,
        };

        if (    $self->amrRules->{$amr_value}
            and $self->amrRules->{$amr_value}->( $req, $richSessionInfo ) )
        {
            push @$result, $amr_value;
        }
    }

    return $result;
}

sub encryptToken {
    my ( $self, $rp, $token, $alg, $enc ) = @_;
    return $token unless $alg;
    my $keys = $self->rpEncKey->{$rp};
    unless ($keys) {
        $self->logger->error(
            "No key defined for $rp, unable to encrypt tokens");
        return $token;
    }
    my $key = $keys->{$alg};
    unless ($key) {
        $self->logger->error(
            "No compatible key found for $rp with algorithm $alg");
        return $token;
    }
    $self->logger->debug('Encrypt JWT token');
    my $tmp = eval {
        Crypt::JWT::encode_jwt(
            payload => $token,
            alg     => $alg,
            key     => $key,
            enc     => $enc || 'A128CBC-HS256',
        );
    };
    if ($@) {
        $self->logger->error("Unable to encrypt token: $@");
        return undef;
    }
    return $token;
}

# Used to build refresh_token
sub getAttributesForUser {
    my ( $self, $req, $session ) = @_;
    $req->userData( $session->data );
    $req->{error} = $self->p->processRefreshSession($req);

    return 1 unless $req->error > 0;

    # PE_BADCREDENTIAL is returned by UserDB modules when the user was
    # explicitly not found. And not in case of temporary failures
    if ( $req->error == PE_BADCREDENTIALS ) {
        $self->logger->error( "User: "
              . $req->user
              . " no longer exists, removing offline session" );
        $session->remove;
    }
    else {
        $self->logger->error( "Could not resolve user: " . $req->user );
    }
    return 0;
}

# Change the ID of secondary sessions (during upgrade)
sub updateOidcSecondarySessions {
    my ( $self, $req, $old_session_id, $new_session_id ) = @_;

    my $module = "Lemonldap::NG::Common::Apache::Session";

    my %opts    = $self->_storeOpts;
    my $options = $opts{storageModuleOptions};
    $options->{backend} = $opts{storageModule};

    my $oidc_sessions =
      $module->searchOn( $options, "user_session_id", $old_session_id );

    if (
        my @oidc_sessions_keys =
        grep { $oidc_sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$oidc_sessions
      )
    {

        foreach my $oidc_session (@oidc_sessions_keys) {

            # Get session
            $self->logger->debug("Retrieve OIDC session $oidc_session");

            my $oidcSession = $self->getOpenIDConnectSession( $oidc_session, '',
                hashStore => 0 );

            if ($oidcSession) {

                # Delete session
                $oidcSession->update( { user_session_id => $new_session_id } );
            }
        }
    }

    return;
}

1;
