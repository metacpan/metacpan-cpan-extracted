package Lemonldap::NG::Portal::Issuer::OpenIDConnect;

use strict;
use JSON qw(from_json to_json);
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADURL
  PE_CONFIRM
  PE_ERROR
  PE_LOGOUT_OK
  PE_REDIRECT
  PE_OK
  PE_UNAUTHORIZEDPARTNER
  PE_OIDC_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.5';

extends 'Lemonldap::NG::Portal::Main::Issuer',
  'Lemonldap::NG::Portal::Lib::OpenIDConnect',
  'Lemonldap::NG::Common::Conf::AccessLib';

# INTERFACE

sub beforeAuth { 'exportRequestParameters' }

# INITIALIZATION

use constant sessionKind => 'OIDCI';

has rule => ( is => 'rw' );
has configStorage => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->{p}->HANDLER->localConfig->{configStorage};
    }
);
has ssoMatchUrl => ( is => 'rw' );

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
        $self->error( "Bad OIDC rule -> " . $hd->tsv->{jail}->error );
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
        oidcServiceMetaDataEndSessionURI   => 'endSessionDone',
        oidcServiceMetaDataCheckSessionURI => 'checkSession',
        oidcServiceMetaDataTokenURI        => 'token',
        oidcServiceMetaDataUserInfoURI     => 'userInfo',
        oidcServiceMetaDataJWKSURI         => 'jwks',
        oidcServiceMetaDataRegistrationURI => 'registration',
    );

    # Manage user requests
    $self->addRouteFromConf(
        'Auth',
        oidcServiceMetaDataCheckSessionURI => 'checkSession',
        oidcServiceMetaDataTokenURI        => 'badAuthRequest',
        oidcServiceMetaDataUserInfoURI     => 'badAuthRequest',
        oidcServiceMetaDataJWKSURI         => 'badAuthRequest',
        oidcServiceMetaDataRegistrationURI => 'badAuthRequest',
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
                          . "was not authorized to access to $rp" );
                    return PE_UNAUTHORIZEDPARTNER;
                }
            }

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
                return $self->reAuth($req);
            }

            my $max_age         = $oidc_request->{'max_age'};
            my $_lastAuthnUTime = $req->{sessionInfo}->{_lastAuthnUTime};
            if ( $max_age && time > $_lastAuthnUTime + $max_age ) {
                $self->logger->debug(
"Reauthentication forced because authentication time ($_lastAuthnUTime) is too old (>$max_age s)"
                );
                return $self->reAuth($req);
            }

            # Check scope validity
            unless ( $oidc_request->{'scope'} =~ /^[a-zA-Z_\-\s]+$/ ) {
                $self->logger->error( "Submitted scope is not valid: "
                      . $oidc_request->{'scope'} );
                return PE_ERROR;
            }

            # Check openid scope
            unless ( $oidc_request->{'scope'} =~ /\bopenid\b/ ) {
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
                my $user_id_attribute =
                  $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsUserIDAttr}
                  || $self->conf->{whatToTrace};
                my $user_id = $req->{sessionInfo}->{$user_id_attribute};
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
                        if ( $consent_scope =~ /\b$requested_scope\b/ ) {
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
                        push @{$_oidcConsents}, @RPoidcConsent;
                        $self->logger->debug(
                            "Append Relying Party $rp Consent");
                        $self->p->updatePersistentSession( $req,
                            { _oidcConsents => to_json($_oidcConsents) } );

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
                        my $icon = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                          ->{oidcRPMetaDataOptionsIcon};
                        my $imgSrc;

                        if ($icon) {
                            $imgSrc =
                              ( $icon =~ m#^https?://# )
                              ? $icon
                              : $self->p->staticPrefic . "/common/" . $icon;
                        }

                        my $scope_messages = {
                            openid  => 'yourIdentity',
                            profile => 'yourProfile',
                            email   => 'yourEmail',
                            address => 'yourAddress',
                            phone   => 'yourPhone',
                        };
                        my @list;
                        foreach my $requested_scope (
                            split( /\s/, $oidc_request->{'scope'} ) )
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

            # Authorization Code Flow
            if ( $flow eq "authorizationcode" ) {

                # Store data in session
                my $codeSession = $self->getOpenIDConnectSession(
                    undef,
                    {
                        redirect_uri    => $oidc_request->{'redirect_uri'},
                        scope           => $oidc_request->{'scope'},
                        user_session_id => $req->id,
                        _utime          => time,
                        nonce           => $oidc_request->{'nonce'},
                        code_challenge  => $oidc_request->{'code_challenge'},
                        code_challenge_method =>
                          $oidc_request->{'code_challenge_method'},
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

                $self->logger->debug("Redirect user to $response_url");
                $req->urldc($response_url);

                return PE_REDIRECT;
            }

            # Implicit Flow
            if ( $flow eq "implicit" ) {

                my $access_token;
                my $at_hash;

                if ( $response_type =~ /\btoken\b/ ) {

                    # Store data in access token
                    # Generate access_token
                    my $accessTokenSession = $self->getOpenIDConnectSession(
                        undef,
                        {
                            scope           => $oidc_request->{'scope'},
                            rp              => $rp,
                            user_session_id => $req->id,
                            _utime          => time,
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
                    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
                    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
                    $at_hash = $self->createHash( $access_token, $hash_level );
                }

                # ID token payload
                my $id_token_exp = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsIDTokenExpiration};
                $id_token_exp += time;

                my $authenticationLevel =
                  $req->{sessionInfo}->{authenticationLevel};
                my $id_token_acr;
                foreach (
                    keys %{ $self->conf->{oidcServiceMetaDataAuthnContext} } )
                {
                    if ( $self->conf->{oidcServiceMetaDataAuthnContext}->{$_} eq
                        $authenticationLevel )
                    {
                        $id_token_acr = $_;
                        last;
                    }
                }

                my $user_id_attribute =
                  $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsUserIDAttr}
                  || $self->conf->{whatToTrace};
                my $user_id = $req->{sessionInfo}->{$user_id_attribute};

                my $id_token_payload_hash = {
                    iss => $self->conf->{oidcServiceMetaDataIssuer}
                    ,    # Issuer Identifier
                    sub => $user_id,         # Subject Identifier
                    aud => [$client_id],     # Audience
                    exp => $id_token_exp,    # expiration
                    iat => time,             # Issued time
                    auth_time => $req->{sessionInfo}->{_lastAuthnUTime}
                    ,                        # Authentication time
                    azp   => $client_id,                 # Authorized party
                                                         # TODO amr
                    nonce => $oidc_request->{'nonce'}    # Nonce
                };

                $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;
                $id_token_payload_hash->{'acr'} = $id_token_acr
                  if $id_token_acr;

                # Create ID Token
                my $id_token =
                  $self->createIDToken( $id_token_payload_hash, $rp );

                $self->logger->debug("Generated id token: $id_token");

                # Send token response
                my $expires_in = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsAccessTokenExpiration};

                # Build Response
                my $response_url = $self->buildImplicitAuthnResponse(
                    $oidc_request->{'redirect_uri'},
                    $access_token, $id_token, $expires_in,
                    $oidc_request->{'state'},
                    $session_state
                );

                $self->logger->debug("Redirect user to $response_url");
                $req->urldc($response_url);

                return PE_REDIRECT;
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
                my $codeSession = $self->getOpenIDConnectSession(
                    undef,
                    {
                        redirect_uri    => $oidc_request->{'redirect_uri'},
                        scope           => $oidc_request->{'scope'},
                        user_session_id => $req->id,
                        _utime          => time,
                        nonce           => $oidc_request->{'nonce'},
                    }
                );

                # Generate code
                my $code = $codeSession->id();

                $self->logger->debug("Generated code: $code");

                # Compute hash to store in c_hash
                $c_hash = $self->createHash( $code, $hash_level );

                if ( $response_type =~ /\btoken\b/ ) {

                    # Generate access_token
                    my $accessTokenSession = $self->getOpenIDConnectSession(
                        undef,
                        {
                            scope           => $oidc_request->{'scope'},
                            rp              => $rp,
                            user_session_id => $req->id,
                            _utime          => time,
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
                    $at_hash = $self->createHash( $access_token, $hash_level );
                }

                if ( $response_type =~ /\bid_token\b/ ) {

                    # ID token payload
                    my $id_token_exp =
                      $self->conf->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsIDTokenExpiration};
                    $id_token_exp += time;

                    my $id_token_acr =
                      "loa-" . $req->{sessionInfo}->{authenticationLevel};

                    my $user_id_attribute =
                      $self->conf->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsUserIDAttr}
                      || $self->conf->{whatToTrace};
                    my $user_id = $req->{sessionInfo}->{$user_id_attribute};

                    my $id_token_payload_hash = {
                        iss => $self->conf->{oidcServiceMetaDataIssuer}
                        ,    # Issuer Identifier
                        sub => $user_id,         # Subject Identifier
                        aud => [$client_id],     # Audience
                        exp => $id_token_exp,    # expiration
                        iat => time,             # Issued time
                        auth_time => $req->{sessionInfo}->{_lastAuthnUTime}
                        ,                        # Authentication time
                        acr => $id_token_acr
                        ,    # Authentication Context Class Reference
                        azp   => $client_id,                 # Authorized party
                                                             # TODO amr
                        nonce => $oidc_request->{'nonce'}    # Nonce
                    };

                    $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;
                    $id_token_payload_hash->{'c_hash'}  = $c_hash  if $c_hash;

                    # Create ID Token
                    $id_token =
                      $self->createIDToken( $id_token_payload_hash, $rp );

                    $self->logger->debug("Generated id token: $id_token");
                }

                my $expires_in = $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsAccessTokenExpiration};

                # Build Response
                my $response_url = $self->buildHybridAuthnResponse(
                    $oidc_request->{'redirect_uri'}, $code,
                    $access_token,                   $id_token,
                    $expires_in,                     $oidc_request->{'state'},
                    $session_state
                );

                $self->logger->debug("Redirect user to $response_url");
                $req->urldc($response_url);
                return PE_REDIRECT;
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

                    $self->logger->debug("Redirect user to $response_url");
                    $req->urldc($response_url);
                    return PE_REDIRECT;
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
    $self->logger->error("Unknown OIDC endpoint $path, skipping");
    return PE_ERROR;
}

# Handle token endpoint
sub token {
    my ( $self, $req ) = @_;
    $self->logger->debug("URL detected as an OpenID Connect TOKEN URL");

    # Check authentication
    my ( $client_id, $client_secret ) =
      $self->getEndPointAuthenticationCredentials($req);

    unless ($client_id) {
        $self->logger->error(
"No authentication provided to get token, or authentication type not supported"
        );
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    # Verify that client_id is registered in configuration
    my $rp = $self->getRP($client_id);

    unless ($rp) {
        $self->userLogger->error(
            "No registered Relying Party found with client_id $client_id");
        return $self->p->sendError( $req, 'invalid_request', 400 );
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
            return $self->p->sendError( $req, 'invalid_request', 400 );
        }
        unless ( $client_secret eq $self->conf->{oidcRPMetaDataOptions}->{$rp}
            ->{oidcRPMetaDataOptionsClientSecret} )
        {
            $self->logger->error("Wrong credentials for $rp");
            return $self->p->sendError( $req, 'invalid_request', 400 );
        }
    }

    # Get code session
    my $code = $req->param('code');

    unless ($code) {
        $self->logger->error("No code found on token endpoint");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    $self->logger->debug("OpenID Connect Code: $code");

    my $codeSession = $self->getOpenIDConnectSession($code);

    unless ($codeSession) {
        $self->logger->error("Unable to find OIDC session $code");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

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

    # Check we have the same redirect_uri value
    unless ( $req->param("redirect_uri") eq $codeSession->data->{redirect_uri} )
    {
        $self->userLogger->error( "Provided redirect_uri does not match "
              . $codeSession->data->{redirect_uri} );
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    # Get user identifier
    my $apacheSession =
      $self->p->getApacheSession( $codeSession->data->{user_session_id},
        noInfo => 1 );

    unless ($apacheSession) {
        $self->userLogger->error(
            "Unable to find user session linked to OIDC session $code");
        $codeSession->remove();
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    my $user_id_attribute =
      $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsUserIDAttr}
      || $self->conf->{whatToTrace};
    my $user_id = $apacheSession->data->{$user_id_attribute};

    $self->logger->debug("Found corresponding user: $user_id");

    # Generate access_token
    my $accessTokenSession = $self->getOpenIDConnectSession(
        undef,
        {
            scope           => $codeSession->data->{scope},
            rp              => $rp,
            user_session_id => $apacheSession->id,
            _utime          => time,
        }
    );

    unless ($accessTokenSession) {
        $self->userLogger->error(
            "Unable to create OIDC session for access_token");
        $codeSession->remove();
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

    my $access_token = $accessTokenSession->id;

    $self->logger->debug("Generated access token: $access_token");

    # Compute hash to store in at_hash
    my $alg = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenSignAlg};
    my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
    my $at_hash = $self->createHash( $access_token, $hash_level );

    # ID token payload
    my $id_token_exp = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsIDTokenExpiration};
    $id_token_exp += time;

    my $id_token_acr = "loa-" . $apacheSession->data->{authenticationLevel};

    my $id_token_payload_hash = {
        iss => $self->conf->{oidcServiceMetaDataIssuer},    # Issuer Identifier
        sub => $user_id,                                    # Subject Identifier
        aud => [$client_id],                                # Audience
        exp => $id_token_exp,                               # expiration
        iat => time,                                        # Issued time
        auth_time => $apacheSession->data->{_lastAuthnUTime}
        ,    # Authentication time
        acr => $id_token_acr,    # Authentication Context Class Reference
        azp => $client_id,       # Authorized party
                                 # TODO amr
    };

    my $nonce = $codeSession->data->{nonce};
    $id_token_payload_hash->{nonce} = $nonce if defined $nonce;
    $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;

    # Create ID Token
    my $id_token = $self->createIDToken( $id_token_payload_hash, $rp );

    $self->logger->debug("Generated id token: $id_token");

    # Send token response
    my $expires_in = $self->conf->{oidcRPMetaDataOptions}->{$rp}
      ->{oidcRPMetaDataOptionsAccessTokenExpiration};

    my $token_response = {
        access_token => $access_token,
        token_type   => 'Bearer',
        expires_in   => $expires_in,
        id_token     => $id_token,
    };

    my $cRP = $apacheSession->data->{_oidcConnectedRP} || '';
    unless ( $cRP =~ /\b$rp\b/ ) {
        $self->p->updateSession( $req, { _oidcConnectedRP => "$rp,$cRP" },
            $apacheSession->id );
    }

    $self->logger->debug("Send token response");

    $codeSession->remove();
    return $self->p->sendJSONresponse( $req, $token_response );
}

# Handle uerinfo endpoint
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

    my $accessTokenSession = $self->getOpenIDConnectSession($access_token);

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

    my $userinfo_response =
      $self->buildUserInfoResponse( $scope, $rp, $user_session_id );
    unless ($userinfo_response) {
        return $self->returnBearerError( 'invalid_request', 'Invalid request',
            401 );
    }

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
    unless ($client_metadata_json) {
        return $self->p->sendError( $req, 'Missing POST data', 400 );
    }

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
    my $conf = $self->confAcc->getConf( { raw => 1 } );

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
                        my $user_id_attribute =
                          $self->conf->{oidcRPMetaDataOptions}->{$rp}
                          ->{oidcRPMetaDataOptionsUserIDAttr}
                          || $self->conf->{whatToTrace};
                        my $user_id = $req->{sessionInfo}->{$user_id_attribute};
                        my $iss     = $self->conf->{oidcServiceMetaDataIssuer};
                        $url .= ( $url =~ /\?/ ? '&' : '?' )
                          . build_urlencoded(
                            iss => $iss,
                            sid => $user_id
                          );
                    }
                    $req->info( qq'<iframe src="$url" class="noborder">'
                          . '</iframe>' );
                }
                else {
                    # TODO
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
    my $authorize_uri    = $self->conf->{oidcServiceMetaDataAuthorizeURI};
    my $token_uri        = $self->conf->{oidcServiceMetaDataTokenURI};
    my $userinfo_uri     = $self->conf->{oidcServiceMetaDataUserInfoURI};
    my $jwks_uri         = $self->conf->{oidcServiceMetaDataJWKSURI};
    my $registration_uri = $self->conf->{oidcServiceMetaDataRegistrationURI};
    my $endsession_uri   = $self->conf->{oidcServiceMetaDataEndSessionURI};
    my $checksession_uri = $self->conf->{oidcServiceMetaDataCheckSessionURI};

    my $path   = $self->path . '/';
    my $issuer = $self->conf->{oidcServiceMetaDataIssuer};
    $path = "/" . $path unless ( $issuer =~ /\/$/ );
    my $baseUrl = $issuer . $path;

    my @acr = keys %{ $self->conf->{oidcServiceMetaDataAuthnContext} };

    # Add a slash to path value if issuer has no trailing slash

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

            # Logout capabilities
            backchannel_logout_supported          => JSON::true,
            backchannel_logout_session_supported  => JSON::true,
            frontchannel_logout_supported         => JSON::true,
            frontchannel_logout_session_supported => JSON::true,
            (
                $self->conf->{oidcServiceAllowDynamicRegistration}
                ? ( registration_endpoint => $baseUrl . $registration_uri )
                : ()
            ),

            # Scopes
            scopes_supported => [qw/openid profile email address phone/],
            response_types_supported => [
                "code",
                "id_token",
                "id_token token",
                "code id_token",
                "code token",
                "code id_token token"
            ],
            grant_types_supported   => [qw/authorization_code implicit hybrid/],
            acr_values_supported    => \@acr,
            subject_types_supported => ["public"],
            token_endpoint_auth_methods_supported =>
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
    }

    return PE_OK;
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

1;
