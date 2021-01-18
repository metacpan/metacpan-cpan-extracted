package Lemonldap::NG::Portal::Issuer::OpenIDConnect;

use strict;
use JSON qw(from_json to_json);
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADURL
  PE_CONFIRM
  PE_REDIRECT
  PE_LOGOUT_OK
  PE_PASSWORD_OK
  PE_BADCREDENTIALS
  PE_UNAUTHORIZEDPARTNER
  PE_OIDC_SERVICE_NOT_ALLOWED
);
use String::Random qw/random_string/;

our $VERSION = '2.0.10';

extends 'Lemonldap::NG::Portal::Main::Issuer',
  'Lemonldap::NG::Portal::Lib::OpenIDConnect',
  'Lemonldap::NG::Common::Conf::AccessLib';

# INTERFACE

sub beforeAuth { 'exportRequestParameters' }

# INITIALIZATION

use constant sessionKind => 'OIDCI';

has rule          => ( is => 'rw' );
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
        $_[0]->conf->{oidcServiceMetaDataIssuer} || $_[0]->conf->{portal};
    }
);

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

    # Initialize RP list
    return 0
      unless ( $self->Lemonldap::NG::Portal::Main::Issuer::init()
        and $self->loadRPs );

    # Manage RP requests
    $self->addRouteFromConf(
        'Unauth',
        oidcServiceMetaDataEndSessionURI    => 'endSessionDone',
        oidcServiceMetaDataCheckSessionURI  => 'checkSession',
        oidcServiceMetaDataTokenURI         => 'token',
        oidcServiceMetaDataUserInfoURI      => 'userInfo',
        oidcServiceMetaDataJWKSURI          => 'jwks',
        oidcServiceMetaDataRegistrationURI  => 'registration',
        oidcServiceMetaDataIntrospectionURI => 'introspection',
    );

    # Manage user requests
    $self->addRouteFromConf(
        'Auth',
        oidcServiceMetaDataCheckSessionURI  => 'checkSession',
        oidcServiceMetaDataTokenURI         => 'badAuthRequest',
        oidcServiceMetaDataUserInfoURI      => 'badAuthRequest',
        oidcServiceMetaDataJWKSURI          => 'badAuthRequest',
        oidcServiceMetaDataRegistrationURI  => 'badAuthRequest',
        oidcServiceMetaDataIntrospectionURI => 'badAuthRequest',
    );

    # Metadata (.well-known/openid-configuration)
    $self->addUnauthRoute(
        '.well-known' => { 'openid-configuration' => 'metadata' },
        ['GET']
    );
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
    return 1;
}

# RUNNING METHODS

sub ssoMatch {
    my ( $self, $req ) = @_;
    return ( $req->uri =~ $self->ssoMatchUrl ? 1 : 0 );
}

# Main method (launched only for authenticated users, see Main/Issuer.pm)
# run() manages only "authorize" and "logout" endpoints.
sub run {
    my ( $self, $req, $path ) = @_;

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
                    $self->logger->debug( "OIDC request parameter $param: "
                          . $oidc_request->{$param} );
                    $self->p->setHiddenFormValue( $req, $param,
                        $oidc_request->{$param},
                        '', 0 );
                }
            }

            my $h =
              $self->p->processHook( $req, 'oidcGotRequest', $oidc_request );
            return PE_ERROR if ( $h != PE_OK );

            # Detect requested flow
            my $response_type = $oidc_request->{'response_type'};
            my $flow          = $self->getFlowType($response_type);

            unless ($flow) {
                $self->logger->error("Unknown response type: $response_type");
                return PE_ERROR;
            }
            $self->logger->debug(
                "OIDC $flow flow requested (response type: $response_type)");

            # Extract request_uri/request parameter
            if ( $oidc_request->{'request_uri'} ) {
                my $request =
                  $self->getRequestJWT( $oidc_request->{'request_uri'} );

                if ($request) {
                    $oidc_request->{'request'} = $request;
                }
                else {
                    $self->logger->error("Error with Request URI resolution");
                    return PE_ERROR;
                }
            }

            if ( $oidc_request->{'request'} ) {
                my $request =
                  $self->getJWTJSONData( $oidc_request->{'request'} );

                # Override OIDC parameters by request content
                foreach ( keys %$request ) {
                    $self->logger->debug(
"Override $_ OIDC param by value present in request parameter"
                    );
                    $oidc_request->{$_} = $request->{$_};
                    $self->p->setHiddenFormValue( $req, $_, $request->{$_}, '',
                        0 );
                }
            }

            # Check all required parameters
            unless ( $oidc_request->{'redirect_uri'} ) {
                $self->logger->error("Redirect URI is required");
                return PE_ERROR;
            }
            unless ( $oidc_request->{'scope'} ) {
                $self->logger->error("Scope is required");
                return PE_ERROR;
            }
            unless ( $oidc_request->{'client_id'} ) {
                $self->logger->error("Client ID is required");
                return PE_ERROR;
            }
            if ( $flow eq "implicit" and not defined $oidc_request->{'nonce'} )
            {
                $self->logger->error("Nonce is required for implicit flow");
                return PE_ERROR;
            }

            # Check client_id
            my $client_id = $oidc_request->{'client_id'};
            $self->logger->debug("Request from client id $client_id");

            # Verify that client_id is registered in configuration
            my $rp = $self->getRP($client_id);

            unless ($rp) {
                $self->logger->error(
"No registered Relying Party found with client_id $client_id"
                );
                return PE_UNAUTHORIZEDPARTNER;
            }
            else {
                $self->logger->debug("Client id $client_id matches RP $rp");
            }

            # Check if this RP is authorized
            if ( my $rule = $self->spRules->{$rp} ) {
                unless ( $rule->( $req, $req->sessionInfo ) ) {
                    $self->userLogger->warn( 'User '
                          . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                          . " is not authorized to access to $rp" );
                    return PE_UNAUTHORIZEDPARTNER;
                }
            }

            $self->userLogger->notice( 'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is authorized to access to $rp" );

            # Check redirect_uri
            my $redirect_uri  = $oidc_request->{'redirect_uri'};
            my $redirect_uris = $self->conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsRedirectUris};

            if ($redirect_uris) {
                my $redirect_uri_allowed = 0;
                foreach ( split( /\s+/, $redirect_uris ) ) {
                    $redirect_uri_allowed = 1 if $redirect_uri eq $_;
                }
                unless ($redirect_uri_allowed) {
                    $self->userLogger->error(
                        "Redirect URI $redirect_uri not allowed");
                    return PE_BADURL;
                }
            }

            # Check if flow is allowed
            if ( $flow eq "authorizationcode"
                and not $self->conf->{oidcServiceAllowAuthorizationCodeFlow} )
            {
                $self->userLogger->error(
                    "Authorization code flow is not allowed");
                return $self->returnRedirectError(
                    $req,           $oidc_request->{'redirect_uri'},
                    "server_error", "Authorization code flow not allowed",
                    undef,          $oidc_request->{'state'},
                    0
                );
            }
            if ( $flow eq "implicit"
                and not $self->conf->{oidcServiceAllowImplicitFlow} )
            {
                $self->logger->error("Implicit flow is not allowed");
                return $self->returnRedirectError(
                    $req,           $oidc_request->{'redirect_uri'},
                    "server_error", "Implicit flow not allowed",
                    undef,          $oidc_request->{'state'},
                    1
                );
            }
            if ( $flow eq "hybrid"
                and not $self->conf->{oidcServiceAllowHybridFlow} )
            {
                $self->logger->error("Hybrid flow is not allowed");
                return $self->returnRedirectError(
                    $req,           $oidc_request->{'redirect_uri'},
                    "server_error", "Hybrid flow not allowed",
                    undef,          $oidc_request->{'state'},
                    1
                );
            }

            my $spAuthnLevel = $self->conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsAuthnLevel} || 0;

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
"Reauthentication required by Relying Party in prompt parameter"
                );
                $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
                return $self->reAuth($req);
            }

            my $max_age         = $oidc_request->{'max_age'};
            my $_lastAuthnUTime = $req->{sessionInfo}->{_lastAuthnUTime};
            if ( $max_age && time > $_lastAuthnUTime + $max_age ) {
                $self->logger->debug(
"Reauthentication forced because authentication time ($_lastAuthnUTime) is too old (>$max_age s)"
                );
                $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
                return $self->reAuth($req);
            }

            # Check if we have sufficient auth level
            my $authenticationLevel =
              $req->{sessionInfo}->{authenticationLevel} || 0;
            if ( $authenticationLevel < $spAuthnLevel ) {
                $self->logger->debug(
                        "Insufficient authentication level for service $rp"
                      . " (has: $authenticationLevel, want: $spAuthnLevel)" );

                # Reauth with sp auth level as target
                $req->pdata->{targetAuthnLevel} = $spAuthnLevel;
                return $self->upgradeAuth($req);
            }

            # Check scope validity
            # We use a slightly more relaxed version of
            # https://tools.ietf.org/html/rfc6749#appendix-A.4
            # To be tolerant of user error (trailing spaces, etc.)
            # Scope names are restricted to printable ASCII characters,
            # excluding double quote and backslash
            unless (
                $oidc_request->{'scope'} =~ /^[\x20\x21\x23-\x5B\x5D-\x7E]*$/ )
            {
                $self->logger->error("Submitted scope is not valid");
                return PE_ERROR;
            }

            # Check openid scope
            unless ( $self->_hasScope( 'openid', $oidc_request->{'scope'} ) ) {
                $self->logger->debug("No openid scope found");

                #TODO manage standard OAuth request
                return PE_OK;
            }

            # Check Request JWT signature
            if ( $oidc_request->{'request'} ) {
                unless (
                    $self->verifyJWTSignature(
                        $oidc_request->{'request'},
                        undef, $rp
                    )
                  )
                {
                    $self->logger->error(
                        "JWT signature request can not be verified");
                    return PE_ERROR;
                }
                else {
                    $self->logger->debug("JWT signature request verified");
                }
            }

            # Check id_token_hint
            my $id_token_hint = $oidc_request->{'id_token_hint'};
            if ($id_token_hint) {

                $self->logger->debug("Check sub of ID Token $id_token_hint");

                # Check that id_token_hint sub match current user
                my $sub = $self->getIDTokenSub($id_token_hint);
                my $user_id =
                  $self->getUserIDForRP( $req, $rp, $req->{sessionInfo} );
                unless ( $sub eq $user_id ) {
                    $self->userLogger->error(
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
                    $self->logger->debug(
                        "ID Token hint sub $sub matches current user");
                }
            }

            # Obtain consent
            my $bypassConsent = $self->conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsBypassConsent};
            if ($bypassConsent) {
                $self->logger->debug(
"Consent is disabled for Relying Party $rp, user will not be prompted"
                );
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
                        $self->logger->error(
                            "Corrupted session (_oidcConsents): $@");
                        return PE_ERROR;
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
                    push @RPoidcConsent,
                      { rp => $rp, epoch => '', scope => '' };
                }

                if (   $RPoidcConsent[0]{rp} eq $rp
                    && $RPoidcConsent[0]{epoch}
                    && $RPoidcConsent[0]{scope} )
                {
                    $ask_for_consent = 0;
                    my $consent_time  = $RPoidcConsent[0]{epoch};
                    my $consent_scope = $RPoidcConsent[0]{scope};
                    $self->logger->debug(
"Consent already given for Relying Party $rp (time: $consent_time, scope: $consent_scope)"
                    );

                    # Check accepted scope
                    foreach my $requested_scope (
                        split( /\s+/, $oidc_request->{'scope'} ) )
                    {
                        if (
                            $self->_hasScope(
                                $requested_scope, $consent_scope
                            )
                          )
                        {
                            $self->logger->debug(
                                "Scope $requested_scope already accepted");
                        }
                        else {
                            $self->logger->debug(
"Scope $requested_scope was not previously accepted"
                            );
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
                        $RPoidcConsent[0]{scope} = $oidc_request->{'scope'};

                        # Build new consent list by removing all references
                        # to the current RP from the old list and appending the
                        # new consent
                        my @newoidcConsents =
                          grep { $_->{rp} ne $rp } @$_oidcConsents;
                        push @newoidcConsents, $RPoidcConsent[0];
                        $self->logger->debug(
                            "Append Relying Party $rp Consent");
                        $self->p->updatePersistentSession( $req,
                            { _oidcConsents => to_json( \@newoidcConsents ) } );

                        $self->logger->debug(
                            "Consent given for Relying Party $rp");
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
                                "Consent is requiered but prompt is set to none"
                            );
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
                          $self->conf->{oidcRPMetaDataOptions}->{$rp}
                          ->{oidcRPMetaDataOptionsDisplayName};
                        my $icon =
                          $self->conf->{oidcRPMetaDataOptions}->{$rp}
                          ->{oidcRPMetaDataOptionsIcon};
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
                        foreach my $requested_scope (
                            split( /\s+/, $oidc_request->{'scope'} ) )
                        {
                            if ( my $message =
                                $scope_messages->{$requested_scope} )
                            {
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
            my $session_state =
              $self->createSessionState( $req->id, $client_id );

            # Check if PKCE is required
            if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
                ->{oidcRPMetaDataOptionsRequirePKCE}
                and !$oidc_request->{'code_challenge'} )
            {
                $self->userLogger->error(
                    "Relying Party must use PKCE protection");
                return $self->returnRedirectError(
                    $req,
                    $oidc_request->{'redirect_uri'},
                    'invalid_request',
                    "Code challenge is required",
                    undef,
                    $oidc_request->{'state'},
                    ( $flow ne "authorizationcode" )
                );
            }

            # WIP: Offline access
            my $offline = 0;
            if (
                $self->_hasScope( 'offline_access', $oidc_request->{'scope'} ) )
            {
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
                unless ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
                    ->{oidcRPMetaDataOptionsAllowOffline} )
                {
                    $self->logger->warn(
                        "Offline access not authorized for RP $rp");
                    $offline = 0;
                }

                # Strip offline_access from scopes from now on
                $oidc_request->{'scope'} = join " ",
                  grep !/^offline_access$/,
                  split /\s+/,
                  $oidc_request->{'scope'};
            }

            # Authorization Code Flow
            if ( $flow eq "authorizationcode" ) {

                # Store data in session
                my $codeSession = $self->newAuthorizationCode(
                    $rp,
                    {
                        code_challenge => $oidc_request->{'code_challenge'},
                        code_challenge_method =>
                          $oidc_request->{'code_challenge_method'},
                        nonce           => $oidc_request->{'nonce'},
                        offline         => $offline,
                        redirect_uri    => $oidc_request->{'redirect_uri'},
                        scope           => $oidc_request->{'scope'},
                        client_id       => $client_id,
                        user_session_id => $req->id,
                    }
                );

                # Generate code
                my $code = $codeSession->id();

                $self->logger->debug("Generated code: $code");

                # Build Response
                my $response_url = $self->buildAuthorizationCodeAuthnResponse(
                    $oidc_request->{'redirect_uri'},
                    $code, $oidc_request->{'state'},
                    $session_state
                );

                return $self->_redirectToUrl( $req, $response_url );
            }

            # Implicit Flow
            if ( $flow eq "implicit" ) {

                my $access_token;
                my $at_hash;

                if ( $response_type =~ /\btoken\b/ ) {

                    # Store data in access token
                    # Generate access_token
                    my $accessTokenSession = $self->newAccessToken(
                        $rp,
                        {
                            scope           => $oidc_request->{'scope'},
                            rp              => $rp,
                            user_session_id => $req->id,
                        }
                    );

                    unless ($accessTokenSession) {
                        $self->logger->error(
                            "Unable to create OIDC session for access_token");
                        $self->returnRedirectError( $req,
                            $oidc_request->{'redirect_uri'},
                            "server_error", undef, undef,
                            $oidc_request->{'state'}, 1 );
                    }

                    $access_token = $accessTokenSession->id;

                    $self->logger->debug(
                        "Generated access token: $access_token");

                    # Compute hash to store in at_hash
                    my $alg =
                      $self->conf->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
                    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
                    $at_hash = $self->createHash( $access_token, $hash_level )
                      if $hash_level;
                }

                my $id_token =
                  $self->_generateIDToken( $req, $oidc_request,
                    $rp, { at_hash => $at_hash } );

                unless ($id_token) {
                    $self->logger->error("Could not generate ID token");
                    return PE_ERROR;
                }

                $self->logger->debug("Generated id token: $id_token");

                # Send token response
                my $expires_in =
                  $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsAccessTokenExpiration}
                  || $self->conf->{oidcServiceAccessTokenExpiration};

                # Build Response
                my $response_url = $self->buildImplicitAuthnResponse(
                    $oidc_request->{'redirect_uri'},
                    $access_token, $id_token, $expires_in,
                    $oidc_request->{'state'},
                    $session_state
                );

                return $self->_redirectToUrl( $req, $response_url );
            }

            # Hybrid Flow
            if ( $flow eq "hybrid" ) {

                my $access_token;
                my $id_token;
                my $at_hash;
                my $c_hash;

                # Hash level
                my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsIDTokenSignAlg};
                my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );

                # Store data in session
                my $codeSession = $self->newAuthorizationCode(
                    $rp,
                    {
                        nonce           => $oidc_request->{'nonce'},
                        offline         => $offline,
                        redirect_uri    => $oidc_request->{'redirect_uri'},
                        client_id       => $client_id,
                        scope           => $oidc_request->{'scope'},
                        user_session_id => $req->id,
                    }
                );

                # Generate code
                my $code = $codeSession->id();

                $self->logger->debug("Generated code: $code");

                # Compute hash to store in c_hash
                $c_hash = $self->createHash( $code, $hash_level )
                  if $hash_level;

                if ( $response_type =~ /\btoken\b/ ) {

                    # Generate access_token
                    my $accessTokenSession = $self->newAccessToken(
                        $rp,
                        {
                            scope           => $oidc_request->{'scope'},
                            rp              => $rp,
                            user_session_id => $req->id,
                        }
                    );

                    unless ($accessTokenSession) {
                        $self->logger->error(
                            "Unable to create OIDC session for access_token");
                        return $self->returnRedirectError( $req,
                            $oidc_request->{'redirect_uri'},
                            "server_error", undef, undef,
                            $oidc_request->{'state'}, 1 );
                    }

                    $access_token = $accessTokenSession->id;

                    $self->logger->debug(
                        "Generated access token: $access_token");

                    # Compute hash to store in at_hash
                    $at_hash = $self->createHash( $access_token, $hash_level )
                      if $hash_level;
                }

                if ( $response_type =~ /\bid_token\b/ ) {

                    $id_token = $self->_generateIDToken(
                        $req,
                        $oidc_request,
                        $rp,
                        {
                            at_hash => $at_hash,
                            c_hash  => $c_hash,
                        }
                    );

                    unless ($id_token) {
                        $self->logger->error("Could not generate ID token");
                        return PE_ERROR;
                    }

                    $self->logger->debug("Generated id token: $id_token");
                }

                my $expires_in =
                  $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsAccessTokenExpiration}
                  || $self->conf->{oidcServiceAccessTokenExpiration};

                # Build Response
                my $response_url = $self->buildHybridAuthnResponse(
                    $oidc_request->{'redirect_uri'}, $code,
                    $access_token,                   $id_token,
                    $expires_in,                     $oidc_request->{'state'},
                    $session_state
                );

                return $self->_redirectToUrl( $req, $response_url );
            }

            $self->logger->debug("None flow has been selected");
            return PE_OK;
        }

        # LOGOUT
        elsif ( $path eq $self->conf->{oidcServiceMetaDataEndSessionURI} ) {
            $self->logger->debug(
                "URL detected as an OpenID Connect END SESSION URL");

            # Set hidden fields
            my $oidc_request = {};
            foreach my $param (qw/id_token_hint post_logout_redirect_uri state/)
            {
                if ( $oidc_request->{$param} = $req->param($param) ) {
                    $self->logger->debug( "OIDC request parameter $param: "
                          . $oidc_request->{$param} );
                    $self->p->setHiddenFormValue( $req, $param,
                        $oidc_request->{$param},
                        '', 0 );
                }
            }

            my $post_logout_redirect_uri =
              $oidc_request->{'post_logout_redirect_uri'};
            my $state = $oidc_request->{'state'};

            # Ask consent for logout
            if ( $req->param('confirm') ) {
                my $err;
                if ( $req->param('confirm') == 1 ) {
                    $req->steps( [
                            @{ $self->p->beforeLogout }, 'authLogout',
                            'deleteSession'
                        ]
                    );
                    $err = $req->error( $self->p->process($req) );
                    if ( $err and $err != PE_LOGOUT_OK ) {
                        if ( $err > 0 ) {
                            $self->logger->error(
                                "Logout process returns error code $err");
                            return PE_ERROR;
                        }
                        return $err;
                    }
                }

                if ($post_logout_redirect_uri) {

                    # Check redirect URI is allowed
                    my $redirect_uri_allowed = 0;
                    foreach ( keys %{ $self->conf->{oidcRPMetaDataOptions} } ) {
                        my $logout_rp = $_;
                        if ( my $redirect_uris =
                            $self->conf->{oidcRPMetaDataOptions}->{$logout_rp}
                            ->{oidcRPMetaDataOptionsPostLogoutRedirectUris} )
                        {

                            foreach ( split( /\s+/, $redirect_uris ) ) {
                                if ( $post_logout_redirect_uri eq $_ ) {
                                    $self->logger->debug(
"$post_logout_redirect_uri is an allowed logout redirect URI for RP $logout_rp"
                                    );
                                    $redirect_uri_allowed = 1;
                                }
                            }
                        }
                    }

                    unless ($redirect_uri_allowed) {
                        $self->logger->error(
                            "$post_logout_redirect_uri is not allowed");
                        return PE_BADURL;
                    }

                    # Build Response
                    my $response_url =
                      $self->buildLogoutResponse( $post_logout_redirect_uri,
                        $state );

                    return $self->_redirectToUrl( $req, $response_url );
                }
                return $req->param('confirm') == 1
                  ? ( $err ? $err : PE_LOGOUT_OK )
                  : PE_OK;
            }

            $req->info( $self->loadTemplate( $req, 'oidcLogout' ) );
            $req->data->{activeTimer} = 0;
            return PE_CONFIRM;
        }
    }

    $self->logger->error(
        $path
        ? "Unknown OIDC endpoint: $path, skipping"
        : 'No OIDC endpoint found, aborting'
    );
    return PE_ERROR;
}

# Handle token endpoint
sub token {
    my ( $self, $req ) = @_;
    $self->logger->debug("URL detected as an OpenID Connect TOKEN URL");

    my $rp = $self->checkEndPointAuthenticationCredentials($req);
    return $self->p->sendError( $req, 'invalid_request', 400 ) unless ($rp);

    my $grant_type = $req->param('grant_type');

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
            $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsAllowPasswordGrant}
          )
        {
            $self->logger->warn(
                "Access to grant_type=password, is not allowed for RP $rp");
            return $self->p->sendError( $req, 'unauthorized_client', 400 );
        }
        return $self->_handlePasswordGrant( $req, $rp );
    }

    # Unknown or unspecified grant type
    else {
        $self->userLogger->error(
            $grant_type
            ? "Unknown grant type: $grant_type"
            : "Missing grant_type parameter"
        );
        return $self->p->sendError( $req, 'unsupported_grant_type', 400 );
    }

}

sub _handlePasswordGrant {
    my ( $self, $req, $rp ) = @_;
    my $client_id = $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $scope     = $req->param('scope') || 'openid';
    my $username  = $req->param('username');
    my $password  = $req->param('password');

    unless ( $username and $password ) {
        $self->logger->error("Missing username or password");

        # FIXME
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    ####
    # Authenticate user by running through the regular login process
    # minus the buildCookie step
    $req->parameters->{user}     = ($username);
    $req->parameters->{password} = $password;
    $req->data->{skipToken}      = 1;

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

    $self->logger->debug( "Credentials check returned "
          . $self->p->_formatProcessResult($result) )
      if $result;

    ## Make sure we returned successfuly from the process AND we were able to create a session
    return $self->p->sendError( $req, 'invalid_grant', 400 )
      unless ( $result == PE_OK and $req->id and $req->user );

    ## Make sure the current user is allowed to use this RP
    if ( my $rule = $self->spRules->{$rp} ) {
        unless ( $rule->( $req, $req->sessionInfo ) ) {
            $self->userLogger->warn( 'User '
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . " is not authorized to access to $rp" );
            $self->p->deleteSession($req);
            return $self->p->sendError( $req, 'invalid_grant', 400 );
        }
    }

    my $user_id = $self->getUserIDForRP( $req, $rp, $req->sessionInfo );

    $self->logger->debug( $user_id
        ? "Found corresponding user: $user_id"
        : 'Corresponding user not found' );

    # Generate access_token
    my $accessTokenSession = $self->newAccessToken(
        $rp,
        {
            scope           => $scope,
            rp              => $rp,
            user_session_id => $req->id,
        }
    );

    unless ($accessTokenSession) {
        $self->userLogger->error(
            "Unable to create OIDC session for access_token");

        #FIXME: should be an error 500
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    my $access_token = $accessTokenSession->id;

    $self->logger->debug("Generated access token: $access_token");

    # Generate refresh_token
    my $refresh_token = undef;

    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsRefreshToken} )
    {
        my $refreshTokenSession = $self->newRefreshToken(
            $rp,
            {
                scope           => $req->param('scope'),
                client_id       => $client_id,
                user_session_id => $req->id,
            },
            0,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->p->sendError( $req,
                'Could not create refresh token session', 500 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated refresh token: $refresh_token");
    }

    # Send token response
    my $expires_in =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => $access_token,
        token_type   => 'Bearer',
        expires_in   => $expires_in,
        ( $refresh_token ? ( refresh_token => $refresh_token ) : () ),
    };

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

sub _handleAuthorizationCodeGrant {
    my ( $self, $req, $rp ) = @_;
    my $client_id = $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $code      = $req->param('code');

    unless ($code) {
        $self->logger->error("No code found on token endpoint");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    my $codeSession = $self->getAuthorizationCode($code);
    unless ($codeSession) {
        $self->logger->error("Unable to find OIDC session $code");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    $codeSession->remove();

    # Check PKCE
    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsRequirePKCE} )
    {
        unless (
            $self->validatePKCEChallenge(
                $req->param('code_verifier'),
                $codeSession->data->{'code_challenge'},
                $codeSession->data->{'code_challenge_method'}
            )
          )
        {
            return $self->p->sendError( $req, 'invalid_grant', 400 );
        }
    }

    # Check we have the same client_id value
    unless ( $client_id eq $codeSession->data->{client_id} ) {
        $self->userLogger->error( "Provided client_id does not match "
              . $codeSession->data->{client_id} );
        return $self->p->sendError( $req, 'invalid_grant', 400 );
    }

    # Check we have the same redirect_uri value
    unless ( $req->param("redirect_uri") eq $codeSession->data->{redirect_uri} )
    {
        $self->userLogger->error( "Provided redirect_uri does not match "
              . $codeSession->data->{redirect_uri} );
        return $self->p->sendError( $req, 'invalid_grant', 400 );
    }

    # Get user identifier
    my $apacheSession =
      $self->p->getApacheSession( $codeSession->data->{user_session_id},
        noInfo => 1 );

    unless ($apacheSession) {
        $self->userLogger->error("Unable to find user session");
        return $self->p->sendError( $req, 'invalid_grant', 400 );
    }

    my $user_id = $self->getUserIDForRP( $req, $rp, $apacheSession->data );

    $self->logger->debug("Found corresponding user: $user_id");

    # Generate access_token
    my $accessTokenSession = $self->newAccessToken(
        $rp,
        {
            scope           => $codeSession->data->{scope},
            rp              => $rp,
            user_session_id => $apacheSession->id,
        }
    );

    unless ($accessTokenSession) {
        $self->userLogger->error(
            "Unable to create OIDC session for access_token");

        #FIXME: should be an error 500
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    my $access_token = $accessTokenSession->id;

    $self->logger->debug("Generated access token: $access_token");

    # Generate refresh_token
    my $refresh_token = undef;

    # For offline access, the refresh token isn't tied to the session ID
    if ( $codeSession->{data}->{offline} ) {

        # We need to remove _sessionType, _sessionid and _utime from the
        # session data before storing session data in the refresh token
        my %userInfo;
        for my $userKey ( grep !/^(_session|_utime$)/,
            keys %{ $apacheSession->data } )
        {
            $userInfo{$userKey} = $apacheSession->data->{$userKey};
        }
        my $refreshTokenSession = $self->newRefreshToken(
            $rp,
            {
                %userInfo,
                redirect_uri => $codeSession->data->{redirect_uri},
                scope        => $codeSession->data->{scope},
                client_id    => $client_id,
                _session_uid => $apacheSession->data->{_user},
                auth_time    => $apacheSession->data->{_lastAuthnUTime},
            },
            1,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->p->sendError( $req, 'invalid_request', 400 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated refresh token: $refresh_token");
    }

    # For online access, if configured
    elsif ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsRefreshToken} )
    {
        my $refreshTokenSession = $self->newRefreshToken(
            $rp,
            {
                redirect_uri    => $codeSession->data->{redirect_uri},
                scope           => $codeSession->data->{scope},
                client_id       => $client_id,
                user_session_id => $codeSession->data->{user_session_id},
            },
            0,
        );

        unless ($refreshTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for refresh_token");
            return $self->p->sendError( $req, 'invalid_request', 400 );
        }

        $refresh_token = $refreshTokenSession->id;

        $self->logger->debug("Generated refresh token: $refresh_token");
    }

    # Compute hash to store in at_hash
    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
    my $at_hash = $self->createHash( $access_token, $hash_level )
      if $hash_level;

    # ID token payload
    # TODO: refactor to use _generateIDToken
    my $id_token_exp =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenExpiration}
      || $self->conf->{oidcServiceIDTokenExpiration};
    $id_token_exp += time;

    my $id_token_acr = "loa-" . $apacheSession->data->{authenticationLevel};

    my $id_token_payload_hash = {
        iss       => $self->iss,                            # Issuer Identifier
        sub       => $user_id,                              # Subject Identifier
        aud       => $self->getAudiences($rp),              # Audience
        exp       => $id_token_exp,                         # expiration
        iat       => time,                                  # Issued time
        auth_time => $apacheSession->data->{_lastAuthnUTime}
        ,    # Authentication time
        acr => $id_token_acr,    # Authentication Context Class Reference
        azp => $client_id,       # Authorized party
                                 # TODO amr
    };

    my $nonce = $codeSession->data->{nonce};
    $id_token_payload_hash->{nonce}     = $nonce   if defined $nonce;
    $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;

    if ( $self->force_id_claims($rp) ) {
        my $claims = $self->buildUserInfoResponseFromId(
            $req, $codeSession->data->{'scope'},
            $rp,  $codeSession->data->{user_session_id}
        );

        foreach ( keys %$claims ) {
            $id_token_payload_hash->{$_} = $claims->{$_}
              unless ( $_ eq "sub" );
        }
    }

    # Create ID Token
    my $id_token = $self->createIDToken( $req, $id_token_payload_hash, $rp );

    unless ($id_token) {
        $self->logger->error(
            "Failed to generate ID Token for service: $client_id");
        return $self->p->sendError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated id token: $id_token");

    # Send token response
    my $expires_in =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => $access_token,
        token_type   => 'Bearer',
        expires_in   => $expires_in,
        id_token     => $id_token,
        ( $refresh_token ? ( refresh_token => $refresh_token ) : () ),
    };

    my $cRP = $apacheSession->data->{_oidcConnectedRP} || '';
    unless ( $cRP =~ /\b$rp\b/ ) {
        $self->p->updateSession( $req, { _oidcConnectedRP => "$rp,$cRP" },
            $apacheSession->id );
    }

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );
}

sub _handleRefreshTokenGrant {
    my ( $self, $req, $rp ) = @_;
    my $client_id = $self->oidcRPList->{$rp}->{oidcRPMetaDataOptionsClientID};
    my $refresh_token = $req->param('refresh_token');

    unless ($refresh_token) {
        $self->logger->error("Missing refresh_token parameter");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    $self->logger->debug("OpenID Refresh Token: $refresh_token");

    my $refreshSession = $self->getRefreshToken($refresh_token);

    unless ($refreshSession) {
        $self->logger->error("Unable to find OIDC session $refresh_token");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    # Check we have the same client_id value
    unless ( $client_id eq $refreshSession->data->{client_id} ) {
        $self->userLogger->error( "Provided client_id does not match "
              . $refreshSession->data->{client_id} );
        return $self->p->sendError( $req, 'invalid_grant', 400 );
    }

    my $access_token;
    my $user_id;
    my $auth_time;
    my $session;

    # If this refresh token is tied to a SSO session
    if ( $refreshSession->data->{user_session_id} ) {
        my $user_session_id = $refreshSession->data->{user_session_id};
        $session = $self->p->getApacheSession($user_session_id);

        unless ($session) {
            $self->logger->error("Unable to find user session");
            return $self->returnBearerError( 'invalid_request',
                'Invalid request', 401 );
        }

        $user_id = $self->getUserIDForRP( $req, $rp, $session->data );

        $auth_time = $session->data->{_lastAuthnUTime};

        # Generate access_token
        my $accessTokenSession = $self->newAccessToken(
            $rp,
            {
                scope           => $refreshSession->data->{scope},
                rp              => $rp,
                user_session_id => $user_session_id,
            }
        );

        unless ($accessTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for access_token");
            return $self->p->sendError( $req,
                'Unable to create Access Token', 500 );
        }

        $access_token = $accessTokenSession->id;

        $self->logger->debug("Generated access token: $access_token");
    }

    # Else, we are in an offline session
    else {

        # Lookup attributes and macros for user
        $req->user( $refreshSession->data->{_session_uid} );
        $req->steps( [
                'getUser',        @{ $self->p->betweenAuthAndData },
                'setSessionInfo', $self->p->groupsAndMacros,
                'setLocalGroups',
            ]
        );
        $req->{error} = $self->p->process($req);

        if ( $req->error > 0 ) {

            # PE_BADCREDENTIAL is returned by UserDB modules when the user was
            # explicitely not found. And not in case of temporary failures
            if ( $req->error == PE_BADCREDENTIALS ) {
                $self->logger->error( "User: "
                      . $req->user
                      . " no longer exists, removing offline session" );
                $refreshSession->remove;
            }
            else {
                $self->logger->error( "Could not resolve user: " . $req->user );
            }
            return $self->p->sendError( $req, 'invalid_grant', 400 );
        }

        # Cleanup sessionInfo
        delete $req->sessionInfo->{_utime};
        delete $req->sessionInfo->{_startTime};

        # Update refresh session
        $self->updateRefreshToken( $refreshSession->id, $req->sessionInfo );
        $session = $refreshSession;
        for ( keys %{ $req->sessionInfo } ) {
            $refreshSession->data->{$_} = $req->sessionInfo->{$_};
        }

        $user_id = $self->getUserIDForRP( $req, $rp, $req->sessionInfo );
        $self->logger->debug("Found corresponding user: $user_id");

        $auth_time = $refreshSession->data->{auth_time};

        # Generate access_token
        my $accessTokenSession = $self->newAccessToken(
            $rp,
            {
                scope              => $refreshSession->data->{scope},
                rp                 => $rp,
                offline_session_id => $refreshSession->id,
            }
        );

        unless ($accessTokenSession) {
            $self->userLogger->error(
                "Unable to create OIDC session for access_token");
            return $self->p->sendError( $req,
                'Unable to create Access Token', 500 );
        }

        $access_token = $accessTokenSession->id;

        $self->logger->debug("Generated access token: $access_token");
    }

    # Compute hash to store in at_hash
    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
    my $at_hash = $self->createHash( $access_token, $hash_level )
      if $hash_level;

    # ID token payload
    # TODO: refactor to use _generateIDToken
    my $id_token_exp =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenExpiration}
      || $self->conf->{oidcServiceIDTokenExpiration};
    $id_token_exp += time;

    # Authentication level using refresh tokens should probably stay at 0
    my $id_token_acr = "loa-0";

    my $id_token_payload_hash = {
        iss => $self->iss,                  # Issuer Identifier
        sub => $user_id,                    # Subject Identifier
        aud => $self->getAudiences($rp),    # Audience
        exp => $id_token_exp,               # expiration
        iat => time,                        # Issued time
             # TODO: is this the right value when using refresh tokens??
        auth_time => $auth_time,       # Authentication time
        acr       => $id_token_acr,    # Authentication Context Class Reference
        azp       => $client_id,       # Authorized party
                                       # TODO amr
    };

    my $nonce = $refreshSession->data->{nonce};
    $id_token_payload_hash->{nonce}     = $nonce   if defined $nonce;
    $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;

    # If we forced sending claims in ID token
    if ( $self->force_id_claims($rp) ) {
        my $claims =
          $self->buildUserInfoResponse( $req, $refreshSession->data->{scope},
            $rp, $session );

        foreach ( keys %$claims ) {
            $id_token_payload_hash->{$_} = $claims->{$_}
              unless ( $_ eq "sub" );
        }
    }

    # Create ID Token
    my $id_token = $self->createIDToken( $req, $id_token_payload_hash, $rp );

    unless ($id_token) {
        $self->logger->error(
            "Failed to generate ID Token for service: $client_id");
        return $self->p->sendError( $req, 'server_error', 500 );
    }

    $self->logger->debug("Generated id token: $id_token");

    # Send token response
    my $expires_in =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenExpiration}
      || $self->conf->{oidcServiceAccessTokenExpiration};

    my $token_response = {
        access_token => $access_token,
        token_type   => 'Bearer',
        expires_in   => $expires_in,
        id_token     => $id_token,
    };

    # TODO
    #my $cRP = $apacheSession->data->{_oidcConnectedRP} || '';
    #unless ( $cRP =~ /\b$rp\b/ ) {
    #    $self->p->updateSession( $req, { _oidcConnectedRP => "$rp,$cRP" },
    #        $apacheSession->id );
    #}

    $self->logger->debug("Send token response");

    return $self->p->sendJSONresponse( $req, $token_response );

}

# Handle userinfo endpoint
sub userInfo {
    my ( $self, $req ) = @_;
    $self->logger->debug("URL detected as an OpenID Connect USERINFO URL");

    my $access_token = $self->getEndPointAccessToken($req);

    unless ($access_token) {
        $self->logger->error("Unable to get access_token");
        return $self->returnBearerError( 'invalid_request',
            "Access token not found in request", 401 );
    }

    $self->logger->debug("Received Access Token $access_token");

    my $accessTokenSession = $self->getAccessToken($access_token);

    unless ($accessTokenSession) {
        $self->userLogger->error(
            "Unable to get access token session for id $access_token");
        return $self->returnBearerError( 'invalid_request',
            'Invalid request', 401 );
    }

    # Get access token session data
    my $scope           = $accessTokenSession->data->{scope};
    my $rp              = $accessTokenSession->data->{rp};
    my $user_session_id = $accessTokenSession->data->{user_session_id};

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

    my $userinfo_sign_alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserInfoSignAlg};

    unless ($userinfo_sign_alg) {
        return $self->p->sendJSONresponse( $req, $userinfo_response );
    }
    else {
        my $userinfo_jwt =
          $self->createJWT( $userinfo_response, $userinfo_sign_alg, $rp );
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
        $self->logger->error("Unable to find user session") unless ($session);
    }
    else {
        my $offline_session_id = $tokenData->{offline_session_id};
        if ($offline_session_id) {
            $session = $self->getRefreshToken($offline_session_id);
            $self->logger->error("Unable to find refresh session")
              unless ($session);
        }
    }
    return $session;
}

sub introspection {
    my ( $self, $req ) = @_;
    $self->logger->debug("URL detected as an OpenID Connect INTROSPECTION URL");

    my $rp = $self->checkEndPointAuthenticationCredentials($req);
    return $self->p->sendError( $req, 'invalid_client', 401 ) unless ($rp);

    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsPublic} )
    {
        $self->logger->error(
            "Public clients are not allowed to acces the introspection endpoint"
        );
        return $self->p->sendError( $req, 'unauthorized_client', 401 );
    }

    my $token = $req->param('token');
    return $self->p->sendError( $req, 'invalid_request', 400 ) unless ($token);

    my $response    = { active => JSON::false };
    my $oidcSession = $self->getOpenIDConnectSession($token);
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
            $response->{client_id} =
              $self->oidcRPList->{ $oidcSession->{data}->{rp} }
              ->{oidcRPMetaDataOptionsClientID}
              if $oidcSession->{data}->{rp};
            $response->{iss} = $self->iss;
            $response->{exp} =
              $oidcSession->{data}->{_utime} + $self->conf->{timeout};
        }
        else {
            $self->logger->error("Count not find session tied to Access Token");
        }
    }
    return $self->p->sendJSONresponse( $req, $response );
}

# Handle jwks endpoint
sub jwks {
    my ( $self, $req ) = @_;
    $self->logger->debug("URL detected as an OpenID Connect JWKS URL");

    my $jwks = { keys => [] };

    my $public_key_sig = $self->conf->{oidcServicePublicKeySig};
    my $key_id_sig     = $self->conf->{oidcServiceKeyIdSig};
    if ($public_key_sig) {
        my $key = $self->key2jwks($public_key_sig);
        $key->{kty} = "RSA";
        $key->{use} = "sig";
        $key->{kid} = $key_id_sig if $key_id_sig;
        push @{ $jwks->{keys} }, $key;
    }
    $self->logger->debug("Send JWKS response sent");
    return $self->p->sendJSONresponse( $req, $jwks );
}

# Handle register endpoint
sub registration {
    my ( $self, $req ) = @_;
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

    my $client_metadata       = $self->decodeJSON($client_metadata_json);
    my $registration_response = {};

    # Check redirect_uris
    unless ( $client_metadata->{redirect_uris} ) {
        $self->logger->error("Field redirect_uris is mandatory");
        return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    }

    # RP identifier
    my $registration_time = time;
    my $rp                = "register-$registration_time";

    # Generate Client ID and Client Password
    my $client_id     = random_string("ssssssssssssssssssssssssssssss");
    my $client_secret = random_string("ssssssssssssssssssssssssssssss");

    # Register known parameters
    my $client_name =
      $client_metadata->{client_name} || "Self registered client";
    my $logo_uri = $client_metadata->{logo_uri};
    my $id_token_signed_response_alg =
      $client_metadata->{id_token_signed_response_alg} || "RS256";
    my $userinfo_signed_response_alg =
      $client_metadata->{userinfo_signed_response_alg};
    my $redirect_uris = $client_metadata->{redirect_uris};

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
    $conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserInfoSignAlg} = $userinfo_signed_response_alg
      if defined $userinfo_signed_response_alg;

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

    if ( $self->confAcc->saveConf($conf) ) {

        # Reload RP list
        $self->loadRPs();

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
    $self->logger->debug("URL  detected as an OpenID Connect END SESSION URL");
    $self->logger->debug("User is already logged out");

    my $post_logout_redirect_uri = $req->param('post_logout_redirect_uri');
    my $state                    = $req->param('state');

    if ($post_logout_redirect_uri) {

        # Check redirect URI is allowed
        my $redirect_uri_allowed = 0;
        foreach ( keys %{ $self->conf->{oidcRPMetaDataOptions} } ) {
            my $logout_rp = $_;
            my $redirect_uris =
              $self->conf->{oidcRPMetaDataOptions}->{$logout_rp}
              ->{oidcRPMetaDataOptionsPostLogoutRedirectUris};

            foreach ( split( /\s+/, $redirect_uris ) ) {
                if ( $post_logout_redirect_uri eq $_ ) {
                    $self->logger->debug(
"$post_logout_redirect_uri is an allowed logout redirect URI for RP $logout_rp"
                    );
                    $redirect_uri_allowed = 1;
                }
            }
        }

        unless ($redirect_uri_allowed) {
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

sub badAuthRequest {
    my ( $self, $req ) = @_;
    return $self->p->sendError( $req,
        $req->uri . ' may not be called by an authenticated user', 400 );
}

# Nothing to do here
sub logout {
    my ( $self, $req ) = @_;
    if ( my $s = $req->userData->{_oidcConnectedRP} ) {
        my @rps = grep /\w/, split( ',', $s );
        foreach my $rp (@rps) {
            my $rpConf = $self->conf->{oidcRPMetaDataOptions}->{$rp};
            unless ($rpConf) {
                $self->logger->error("Unknown Relying Party $rp");
                return PE_ERROR;
            }
            if ( my $url = $rpConf->{oidcRPMetaDataOptionsLogoutUrl} ) {
                if ( $rpConf->{oidcRPMetaDataOptionsLogoutType} eq 'front' ) {
                    if ( $rpConf->{oidcRPMetaDataOptionsLogoutSessionRequired} )
                    {
                        my $user_id = $self->getUserIDForRP( $req, $rp,
                            $req->{sessionInfo} );
                        $url .= ( $url =~ /\?/ ? '&' : '?' )
                          . build_urlencoded(
                            iss => $self->iss,
                            sid => $user_id
                          );
                    }
                    $req->info( qq'<iframe src="$url" class="noborder">'
                          . '</iframe>' );
                }
                else {
                    # TODO #1194
                }
            }
        }
    }
    return PE_OK;
}

# Internal methods

sub metadata {
    my ( $self, $req ) = @_;
    my $issuerDBOpenIDConnectPath = $self->conf->{issuerDBOpenIDConnectPath};
    my $authorize_uri     = $self->conf->{oidcServiceMetaDataAuthorizeURI};
    my $token_uri         = $self->conf->{oidcServiceMetaDataTokenURI};
    my $userinfo_uri      = $self->conf->{oidcServiceMetaDataUserInfoURI};
    my $jwks_uri          = $self->conf->{oidcServiceMetaDataJWKSURI};
    my $registration_uri  = $self->conf->{oidcServiceMetaDataRegistrationURI};
    my $endsession_uri    = $self->conf->{oidcServiceMetaDataEndSessionURI};
    my $checksession_uri  = $self->conf->{oidcServiceMetaDataCheckSessionURI};
    my $introspection_uri = $self->conf->{oidcServiceMetaDataIntrospectionURI};

    my $path   = $self->path . '/';
    my $issuer = $self->iss;
    $path = "/" . $path unless ( $issuer =~ /\/$/ );
    my $baseUrl = $issuer . $path;

    my @acr = keys %{ $self->conf->{oidcServiceMetaDataAuthnContext} };

    # List response types depending on allowed flows
    my $response_types = [];
    my $grant_types    = [];
    if ( $self->conf->{oidcServiceAllowAuthorizationCodeFlow} ) {
        push( @$response_types, "code" );
        push( @$grant_types,    "authorization_code" );
    }
    if ( $self->conf->{oidcServiceAllowImplicitFlow} ) {
        push( @$response_types, "id_token", "id_token token" );
        push( @$grant_types, "implicit" );
    }

    # If one of the RPs has password grant enabled
    if (
        grep {
            $self->oidcRPList->{$_}->{oidcRPMetaDataOptionsAllowPasswordGrant}
        } keys %{ $self->oidcRPList }
      )
    {
        push( @$grant_types, "password" );
    }

    # If one of the RPs has refresh tokens enabled
    if (
        grep { $self->oidcRPList->{$_}->{oidcRPMetaDataOptionsRefreshToken} }
        keys %{ $self->oidcRPList }
      )
    {
        push( @$grant_types, "refresh_token" );
    }

    if ( $self->conf->{oidcServiceAllowHybridFlow} ) {
        push( @$response_types,
            "code id_token",
            "code token", "code id_token token" );
        push( @$grant_types, "hybrid" );
    }

    # Create OpenID configuration hash;
    return $self->p->sendJSONresponse(
        $req,
        {
            issuer => $issuer,

            # Endpoints
            token_endpoint         => $baseUrl . $token_uri,
            userinfo_endpoint      => $baseUrl . $userinfo_uri,
            jwks_uri               => $baseUrl . $jwks_uri,
            authorization_endpoint => $baseUrl . $authorize_uri,
            end_session_endpoint   => $baseUrl . $endsession_uri,
            check_session_iframe   => $baseUrl . $checksession_uri,
            introspection_endpoint => $baseUrl . $introspection_uri,

            # Logout capabilities
            backchannel_logout_supported          => JSON::false,
            backchannel_logout_session_supported  => JSON::false,
            frontchannel_logout_supported         => JSON::true,
            frontchannel_logout_session_supported => JSON::true,
            (
                $self->conf->{oidcServiceAllowDynamicRegistration}
                ? ( registration_endpoint => $baseUrl . $registration_uri )
                : ()
            ),

            # Scopes
            scopes_supported => [qw/openid profile email address phone/],
            response_types_supported => $response_types,
            grant_types_supported    => $grant_types,
            acr_values_supported     => \@acr,
            subject_types_supported  => ["public"],
            token_endpoint_auth_methods_supported =>
              [qw/client_secret_post client_secret_basic/],
            introspection_endpoint_auth_methods_supported =>
              [qw/client_secret_post client_secret_basic/],
            claims_supported                 => [qw/sub iss auth_time acr/],
            request_parameter_supported      => JSON::true,
            request_uri_parameter_supported  => JSON::true,
            require_request_uri_registration => JSON::false,

            # Algorithms
            id_token_signing_alg_values_supported =>
              [qw/none HS256 HS384 HS512 RS256 RS384 RS512/],
            userinfo_signing_alg_values_supported =>
              [qw/none HS256 HS384 HS512 RS256 RS384 RS512/],

            # PKCE
            code_challenge_methods_supported => [qw/plain S256/],
        }
    );

    # response_modes_supported

    # id_token_encryption_alg_values_supported
    # id_token_encryption_enc_values_supported

    # userinfo_encryption_alg_values_supported
    # userinfo_encryption_enc_values_supported
    # request_object_signing_alg_values_supported
    # request_object_encryption_alg_values_supported
    # request_object_encryption_enc_values_supported

    # token_endpoint_auth_signing_alg_values_supported
    # display_values_supported
    # claim_types_supported
    # RECOMMENDED # claims_supported
    # service_documentation
    # claims_locales_supported
    # ui_locales_supported
    # claims_parameter_supported

    # op_policy_uri
    # op_tos_uri
}

# Store request parameters in %ENV
sub exportRequestParameters {
    my ( $self, $req ) = @_;

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

    # Extract request_uri/request parameter
    my $request = $req->param('request');
    if ( $req->param('request_uri') ) {
        $request = $self->getRequestJWT( $req->param('request_uri') );
    }

    if ($request) {
        my $request_data = $self->getJWTJSONData($request);
        foreach ( keys %$request_data ) {
            $req->env->{ "llng_oidc_" . $_ } = $request_data->{$_};
        }
    }

    if ( $req->param('client_id') ) {
        my $rp = $self->getRP( $req->param('client_id') );
        $req->env->{"llng_oidc_rp"} = $rp if $rp;

        # Store target authentication level in pdata
        my $targetAuthnLevel = $self->conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsAuthnLevel};
        $req->pdata->{targetAuthnLevel} = $targetAuthnLevel
          if $targetAuthnLevel;
    }

    return PE_OK;
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
            $self->logger->debug(
"Corrupted Consent / Session -> RP=$rp, Scope=$scope, Epoch=$epoch"
            );
            return PE_ERROR;
        }
    }

    # Update persistent session
    $self->p->updatePersistentSession( $req,
        { _oidcConsents => to_json( \@oidcConsents ) } )
      if $count;
    return $count;
}

sub _generateIDToken {
    my ( $self, $req, $oidc_request, $rp, $extra_claims ) = @_;

    my $response_type = $oidc_request->{'response_type'};
    my $client_id     = $oidc_request->{'client_id'};

    my $id_token_exp =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenExpiration}
      || $self->conf->{oidcServiceIDTokenExpiration};
    $id_token_exp += time;

    my $authenticationLevel = $req->{sessionInfo}->{authenticationLevel} || 0;

    my $id_token_acr = "loa-$authenticationLevel";
    foreach ( keys %{ $self->conf->{oidcServiceMetaDataAuthnContext} } ) {
        if ( $self->conf->{oidcServiceMetaDataAuthnContext}->{$_} eq
            $authenticationLevel )
        {
            $id_token_acr = $_;
            last;
        }
    }

    my $user_id = $self->getUserIDForRP( $req, $rp, $req->{sessionInfo} );

    my $id_token_payload_hash = {
        iss       => $self->iss,                            # Issuer Identifier
        sub       => $user_id,                              # Subject Identifier
        aud       => $self->getAudiences($rp),              # Audience
        exp       => $id_token_exp,                         # expiration
        iat       => time,                                  # Issued time
        auth_time => $req->{sessionInfo}->{_lastAuthnUTime}
        ,    # Authentication time
        acr => $id_token_acr,    # Authentication Context Class Reference
        azp => $client_id,       # Authorized party
                                 # TODO amr
        nonce => $oidc_request->{'nonce'}    # Nonce
    };

    for ( keys %{$extra_claims} ) {
        $id_token_payload_hash->{$_} = $extra_claims->{$_}
          if $extra_claims->{$_};
    }

    if (   $response_type !~ /\btoken\b/
        || $self->force_id_claims($rp) )
    {

        # No access_token
        # Claims must be set in id_token
        my $claims =
          $self->buildUserInfoResponseFromId( $req, $oidc_request->{'scope'},
            $rp, $req->id );

        foreach ( keys %$claims ) {
            $id_token_payload_hash->{$_} = $claims->{$_}
              unless ( $_ eq "sub" );
        }
    }

    # Create ID Token
    return $self->createIDToken( $req, $id_token_payload_hash, $rp );
}

sub _redirectToUrl {
    my ( $self, $req, $response_url ) = @_;

    # We must clear hidden form fields saved from the request (#2085)
    $self->p->clearHiddenFormValue($req);
    $self->logger->debug("Redirect user to $response_url");
    $req->urldc($response_url);

    return PE_REDIRECT;
}

1;
