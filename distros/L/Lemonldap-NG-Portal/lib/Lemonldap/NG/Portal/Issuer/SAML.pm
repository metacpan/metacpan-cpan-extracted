package Lemonldap::NG::Portal::Issuer::SAML;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Lib::SAML;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SAML_ART_ERROR
  PE_SAML_DESTINATION_ERROR
  PE_SAML_SESSION_ERROR
  PE_SAML_SIGNATURE_ERROR
  PE_SAML_SLO_ERROR
  PE_SAML_SSO_ERROR
  PE_SAML_UNKNOWN_ENTITY
  PE_SAML_SERVICE_NOT_ALLOWED
  PE_UNAUTHORIZEDPARTNER
);

our $VERSION = '2.0.5';

extends 'Lemonldap::NG::Portal::Main::Issuer',
  'Lemonldap::NG::Portal::Lib::SAML';

has rule           => ( is => 'rw' );
has ssoUrlRe       => ( is => 'rw' );
has ssoUrlArtifact => ( is => 'rw' );
has ssoGetUrl      => ( is => 'rw' );

use constant sessionKind => 'ISAML';
use constant lsDump      => '_lassoSessionDumpI';
use constant liDump      => '_lassoIdentityDumpI';

# INTERFACE

# Simply store SP in $req->env
use constant beforeAuth => 'storeEnv';

# INITIALIZATION

sub init {
    my ($self) = @_;

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug( "SAML rule -> " . $self->conf->{issuerDBSAMLRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{issuerDBSAMLRule} ) );
    unless ($rule) {
        $self->error( "Bad SAML rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->{rule} = $rule;

    # Prepare SSO URL catching
    my $saml_sso_get_url = $self->ssoGetUrl(
        $self->getMetaDataURL(
            "samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect", 1
        )
    );
    my $saml_sso_get_url_ret = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect", 2 );
    my $saml_sso_post_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceHTTPPost",
        1 );
    my $saml_sso_post_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceHTTPPost",
        2 );
    my $saml_sso_art_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact", 1 );
    my $saml_sso_art_url_ret = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact", 2 );
    $self->ssoUrlRe(
qr/^($saml_sso_get_url|$saml_sso_get_url_ret|$saml_sso_post_url|$saml_sso_post_url_ret|$saml_sso_art_url|$saml_sso_art_url_ret)(?:\?.*)?$/i
    );
    $self->ssoUrlArtifact(
        qr/^($saml_sso_art_url|$saml_sso_art_url_ret)(?:\?.*)?$/i);

    # Launch parents initialization subroutines, then launch IdP en SP lists
    my $res = (
        $self->Lemonldap::NG::Portal::Main::Issuer::init()

          # Load SAML service
          and $self->Lemonldap::NG::Portal::Lib::SAML::init()

          # Load SAML service providers
          and $self->loadSPs()

          # Load SAML identity providers
          # Required to manage SLO in Proxy mode
          and $self->loadIDPs()
    );
    return 0 unless ($res);

    if ( $self->conf->{samlOverrideIDPEntityID} ) {
        $self->lassoServer->ProviderID(
            $self->conf->{samlOverrideIDPEntityID} );
    }

    # Single logout routes
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceSOAP",
        1, 'sloServer', ['POST'] );
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceSOAP",
        2, 'sloServer', ['POST'] );
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect",
        1, 'sloServer', ['GET'] );
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect",
        2, 'sloServer', ['GET'] );
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        1, 'sloServer', ['POST'] );
    $self->addUnauthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        2, 'sloServer', ['POST'] );

    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceSOAP",
        1, 'authSloServer', ['POST'] );
    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceSOAP",
        2, 'authSloServer', ['POST'] );
    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect",
        1, 'authSloServer', ['GET'] );
    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect",
        2, 'authSloServer', ['GET'] );
    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        1, 'authSloServer', ['POST'] );
    $self->addAuthRouteFromMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        2, 'authSloServer', ['POST'] );

    # SOAP routes (access without authentication)
    $self->addRouteFromMetaDataURL(
        'samlIDPSSODescriptorArtifactResolutionServiceArtifact',
        3, 'artifactServer', ['POST'] );
    $self->addRouteFromMetaDataURL(
        'samlAttributeAuthorityDescriptorAttributeServiceSOAP',
        1, 'attributeServer', ['POST'] );

    $self->addUnauthRoute(
        $self->path => { relaySingleLogoutSOAP => 'sloRelaySoap' },
        [ 'GET', 'POST' ]
    );
    $self->addAuthRoute(
        $self->path => { relaySingleLogoutPOST => 'sloRelayPost' },
        [ 'GET', 'POST' ]
    );
    $self->addUnauthRoute(
        $self->path => { relaySingleLogoutPOST => 'sloRelayPost' },
        [ 'GET', 'POST' ]
    );
    $self->addUnauthRoute(
        $self->path => { relaySingleLogoutTermination => 'sloRelayTerm' },
        [ 'GET', 'POST' ]
    );
    return $res;
}

# RUNNING METHODS

# "beforeAuth" entry point. Store just SP and SP confKey in $req->env
sub storeEnv {
    my ( $self, $req ) = @_;
    return PE_OK
      if ( $req->uri !~ $self->ssoUrlRe or $req->uri =~ $self->ssoUrlArtifact );
    my ( $request, $response, $method, $relaystate, $artifact ) =
      $self->checkMessage( $req, $req->uri, $req->method, $req->content_type );
    return PE_OK if ( $artifact or !$request );
    my $login = $self->createLogin( $self->lassoServer );
    $self->disableSignatureVerification($login);
    $self->processAuthnRequestMsg( $login, $request );
    if ( my $sp = $login->remote_providerID() ) {
        $req->env->{llng_saml_sp} = $sp;
        if ( my $spConfKey = $self->spList->{$sp}->{confKey} ) {
            $req->env->{llng_saml_spconfkey} = $spConfKey;
        }
    }
    return PE_OK;
}

sub ssoMatch {
    my ( $self, $req ) = @_;
    my $url = $self->normalize_url( $req->uri, $self->conf->{issuerDBSAMLPath},
        $self->ssoGetUrl );
    return (
        $url =~ $self->ssoUrlRe or $req->data->{_proxiedRequest}
        ? 1
        : 0
    );
}

# Main method (launched only for authenticated users, see Main/Issuer)
sub run {
    my ( $self, $req ) = @_;
    my $login;
    my $protocolProfile;
    my $artifact_method;
    my $authn_context;

    # Check activation rule
    unless ( $self->rule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->error('SAML service not authorized');
        return PE_SAML_SERVICE_NOT_ALLOWED;
    }

    # Session ID
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->{id};

    # Session creation timestamp
    my $time = $req->{sessionInfo}->{_utime} || time();

    # Get HTTP request information to know
    # if we are receving SAML request or response
    my $url                     = $req->uri;
    my $request_method          = $req->param('issuerMethod') || $req->method;
    my $content_type            = $req->content_type();
    my $idp_initiated           = $req->param('IDPInitiated');
    my $idp_initiated_sp        = $req->param('sp');
    my $idp_initiated_spConfKey = $req->param('spConfKey');

    # Normalize URL to be tolerant to SAML Path
    $url = $self->normalize_url( $url, $self->conf->{issuerDBSAMLPath},
        $self->ssoGetUrl );

    # Get domain GET attribute
    my $domain = $req->param('domain');

    if ($domain) {
        $self->logger->debug("Found domain $domain in SAML GET parameter");
    }

    # 1.1. SSO (SSO URL or Proxy Mode)
    if ( $url =~ $self->ssoUrlRe or $req->data->{_proxiedRequest} ) {

        $self->logger->debug("URL $url detected as an SSO request URL");

        # Check message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $req, $url, $request_method, $content_type );

        # Create Login object
        my $login = $self->createLogin( $self->lassoServer );

        # Ignore signature verification
        $self->disableSignatureVerification($login);

        if ($request) {
            $req->data->{_proxiedSamlRequest} = $login->request();
            $req->data->{_proxiedRequest}     = $request;
            $req->data->{_proxiedMethod}      = $method;
            $req->data->{_proxiedRelayState}  = $relaystate,
              $req->data->{_proxiedArtifact}  = $artifact;
        }

        # Process the request or use IDP initiated mode
        if ( $request or $idp_initiated ) {

            # Load Session and Identity if they exist
            my $session  = $req->{sessionInfo}->{ $self->lsDump };
            my $identity = $req->{sessionInfo}->{ $self->liDump };

            if ($session) {
                unless ( $self->setSessionFromDump( $login, $session ) ) {
                    $self->logger->error("Unable to load Lasso Session");
                    return PE_SAML_SSO_ERROR;
                }
                $self->logger->debug("Lasso Session loaded");
            }

            if ($identity) {
                unless ( $self->setIdentityFromDump( $login, $identity ) ) {
                    $self->logger->error("Unable to load Lasso Identity");
                    return PE_SAML_SSO_ERROR;
                }
                $self->logger->debug("Lasso Identity loaded");
            }

            my $result;

            # Create fake request if IDP initiated mode
            if ($idp_initiated) {

                # Need sp or spConfKey parameter
                unless ( $idp_initiated_sp or $idp_initiated_spConfKey ) {
                    $self->userLogger->warn(
"sp or spConfKey parameter needed to make IDP initiated SSO"
                    );
                    return PE_SAML_SSO_ERROR;
                }

                unless ($idp_initiated_sp) {

                    # Get SP from spConfKey
                    foreach ( keys %{ $self->spList } ) {
                        if ( $self->spList->{$_}->{confKey} eq
                            $idp_initiated_spConfKey )
                        {
                            $idp_initiated_sp = $_;
                            last;
                        }
                    }
                }
                else {
                    unless ( defined $self->spList->{$idp_initiated_sp} ) {
                        $self->userLogger->error(
                            "SP $idp_initiated_sp not known");
                        return PE_SAML_UNKNOWN_ENTITY;
                    }
                    $idp_initiated_spConfKey =
                      $self->spList->{$idp_initiated_sp}->{confKey};
                }

                # Check if IDP Initiated SSO is allowed
                unless ( $self->conf->{samlSPMetaDataOptions}
                    ->{$idp_initiated_spConfKey}
                    ->{samlSPMetaDataOptionsEnableIDPInitiatedURL} )
                {
                    $self->userLogger->error(
"IDP Initiated SSO not allowed for SP $idp_initiated_spConfKey"
                    );
                    return PE_SAML_SSO_ERROR;
                }

                $result =
                  $self->initIdpInitiatedAuthnRequest( $login,
                    $idp_initiated_sp );
                unless ($result) {
                    $self->logger->error(
                        "SSO: Fail to init IDP Initiated authentication request"
                    );
                    return PE_SAML_SSO_ERROR;
                }

                # Force NameID Format
                my $nameIDFormatKey =
                  $self->conf->{samlSPMetaDataOptions}
                  ->{$idp_initiated_spConfKey}
                  ->{samlSPMetaDataOptionsNameIDFormat} || "email";
                eval {
                    $login->request()->NameIDPolicy()
                      ->Format( $self->getNameIDFormat($nameIDFormatKey) );
                };

                # Force AllowCreate to TRUE
                eval { $login->request()->NameIDPolicy()->AllowCreate(1); };
            }

            # Process authentication request
            if ($artifact) {
                $result = $self->processArtResponseMsg( $login, $request );
            }
            else {
                $result = $self->processAuthnRequestMsg( $login, $request );
            }

            unless ($result) {
                $self->logger->error(
                    "SSO: Fail to process authentication request");
                return PE_SAML_SSO_ERROR;
            }

            # Get SP entityID
            my $sp = $request ? $login->remote_providerID() : $idp_initiated_sp;

            $self->logger->debug("Found entityID $sp in SAML message");
            $req->env->{llng_saml_sp} = $sp;

            # SP conf key
            my $spConfKey = $self->spList->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->userLogger->error(
                    "$sp do not match any SP in configuration");
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->logger->debug("$sp match $spConfKey SP in configuration");
            $req->env->{llng_saml_spconfkey} = $spConfKey;

            if ( my $rule = $self->spRules->{$sp} ) {
                unless ( $rule->( $req, $req->sessionInfo ) ) {
                    $self->userLogger->warn( 'User '
                          . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                          . "was not authorizated to access to $sp" );
                    return PE_UNAUTHORIZEDPARTNER;
                }
            }

            # Do we check signature?
            my $checkSSOMessageSignature =
              $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsCheckSSOMessageSignature};

            if ($checkSSOMessageSignature) {

                $self->forceSignatureVerification($login);

                if ($artifact) {
                    $result = $self->processArtResponseMsg( $login, $request );
                }
                else {
                    $result = $self->processAuthnRequestMsg( $login, $request );
                }

                unless ($result) {
                    $self->logger->error("Signature is not valid");
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->logger->debug("Signature is valid");
                }
            }
            else {
                $self->logger->debug("Message signature will not be checked");
            }

            # Force AllowCreate to TRUE for transient/persistent NameIDPolicy
            if ( $login->request()->NameIDPolicy ) {
                my $nif = $login->request()->NameIDPolicy->Format();
                if (   $nif eq $self->getNameIDFormat("transient")
                    or $nif eq $self->getNameIDFormat("persistent") )
                {
                    $self->logger->debug(
                        "Force AllowCreate flag in NameIDPolicy");
                    eval { $login->request()->NameIDPolicy()->AllowCreate(1); };
                }
            }

            # Validate request
            unless ( $self->validateRequestMsg( $login, 1, 1 ) ) {
                $self->logger->error("Unable to validate SSO request message");
                return PE_SAML_SSO_ERROR;
            }

            $self->logger->debug("SSO: authentication request is valid");

            # Get ForceAuthn flag
            my $force_authn;

            eval { $force_authn = $login->request()->ForceAuthn(); };
            if ($@) {
                $self->logger->warn(
                    "Unable to get ForceAuthn flag, set it to false");
                $force_authn = 0;
            }

            $self->logger->debug(
                "Found ForceAuthn flag with value $force_authn");

            # Force authentication if flag is on, or previous flag still active
            if (
                $force_authn
                and (
                    time - $req->sessionInfo->{_utime} >
                    $self->conf->{portalForceAuthnInterval} )
              )
            {

                $self->userLogger->info(
                    "SAML SP $sp ask to refresh session of "
                      . $req->sessionInfo->{ $self->conf->{whatToTrace} } );

                # Replay authentication process
                return $self->reAuth($req);
            }

            # Check Destination (only in non proxy mode)
            unless ( $req->data->{_proxiedRequest} ) {
                return PE_SAML_DESTINATION_ERROR
                  unless ( $self->checkDestination( $login->request, $url ) );
            }

            # Map authenticationLevel with SAML2 authentication context
            my $authenticationLevel =
              $req->{sessionInfo}->{authenticationLevel};

            $authn_context =
              $self->authnLevel2authnContext($authenticationLevel);

            $self->logger->debug("Authentication context is $authn_context");

            # Get SP options notOnOrAfterTimeout
            my $notOnOrAfterTimeout =
              $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsNotOnOrAfterTimeout};

            # Build Assertion
            unless (
                $self->buildAssertion(
                    $req, $login, $authn_context, $notOnOrAfterTimeout
                )
              )
            {
                $self->logger->error("Unable to build assertion");
                return PE_SAML_SSO_ERROR;
            }

            $self->logger->debug("SSO: assertion is built");

            # Get default NameID Format from configuration
            # Set to "email" if no value in configuration
            my $nameIDFormatKey =
              $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsNameIDFormat} || "email";
            my $nameIDFormat;

            # Check NameID Policy in request
            if ( $login->request()->NameIDPolicy ) {
                $nameIDFormat = $login->request()->NameIDPolicy->Format();
                $self->logger->debug(
                    "Get NameID format $nameIDFormat from request");
            }

            # NameID unspecified is forced to default NameID format
            if (  !$nameIDFormat
                or $nameIDFormat eq $self->getNameIDFormat("unspecified") )
            {
                $nameIDFormat = $self->getNameIDFormat($nameIDFormatKey);
            }

            # Get session key associated with NameIDFormat
            # Not for unspecified, transient, persistent, entity, encrypted
            my $nameIDFormatConfiguration = {
                $self->getNameIDFormat("email") => 'samlNameIDFormatMapEmail',
                $self->getNameIDFormat("x509")  => 'samlNameIDFormatMapX509',
                $self->getNameIDFormat("windows") =>
                  'samlNameIDFormatMapWindows',
                $self->getNameIDFormat("kerberos") =>
                  'samlNameIDFormatMapKerberos',
            };

            my $nameIDSessionKey =
              $self->conf->{ $nameIDFormatConfiguration->{$nameIDFormat} };

            # Override default NameID Mapping
            if ( $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
                ->{samlSPMetaDataOptionsNameIDSessionKey} )
            {
                $nameIDSessionKey =
                  $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
                  ->{samlSPMetaDataOptionsNameIDSessionKey};
            }

            my $nameIDContent;
            if ( defined $req->{sessionInfo}->{$nameIDSessionKey} ) {
                $nameIDContent =
                  $self->p->getFirstValue(
                    $req->{sessionInfo}->{$nameIDSessionKey} );
            }

            # Manage Entity NameID format
            if ( $nameIDFormat eq $self->getNameIDFormat("entity") ) {
                $nameIDContent = $self->getMetaDataURL( "samlEntityID", 0, 1 );
            }

            # Manage Transient NameID format
            if ( $nameIDFormat eq $self->getNameIDFormat("transient") ) {
                eval {
                    my @assert = $login->response->Assertion;
                    $nameIDContent = $assert[0]->Subject->NameID->content;
                };
            }

            if ( $login->nameIdentifier ) {
                $login->nameIdentifier->Format($nameIDFormat);
                $login->nameIdentifier->content($nameIDContent)
                  if $nameIDContent;
            }
            else {
                my $nameIdentifier = Lasso::Saml2NameID->new();
                $nameIdentifier->Format($nameIDFormat);
                $nameIdentifier->content($nameIDContent)
                  if $nameIDContent;
                $login->nameIdentifier($nameIdentifier);
            }

            $self->logger->debug(
                "NameID Format is " . $login->nameIdentifier->Format );
            $self->logger->debug(
                "NameID Content is " . $login->nameIdentifier->content );

            # Push attributes
            my @attributes;

            foreach (
                keys %{
                    $self->conf->{samlSPMetaDataExportedAttributes}
                      ->{$spConfKey}
                }
              )
            {

                # Extract fields from exportedAttr value
                my ( $mandatory, $name, $format, $friendly_name ) =
                  split( /;/,
                    $self->conf->{samlSPMetaDataExportedAttributes}
                      ->{$spConfKey}->{$_} );

                # Name is required
                next unless $name;

                # Error if corresponding attribute is not in user session
                my $value = $req->{sessionInfo}->{$_};
                unless ( defined $value ) {
                    if ($mandatory) {
                        $self->logger->error(
"Session key $_ is required to set SAML $name attribute"
                        );
                        return PE_SAML_SSO_ERROR;
                    }
                    else {
                        $self->logger->debug(
"SAML2 attribute $name has no value but is not mandatory, skip it"
                        );
                        next;
                    }
                }

                $self->logger->debug(
                    "SAML2 attribute $name will be set with $_ session key");

                # SAML2 attribute
                my $attribute =
                  $self->createAttribute( $name, $format, $friendly_name );

                unless ($attribute) {
                    $self->logger->error(
                        "Unable to create a new SAML attribute");
                    return PE_SAML_SSO_ERROR;
                }

                # Set attribute value(s)
                my @values = split $self->conf->{multiValuesSeparator}, $value;
                my @saml2values;

                foreach (@values) {

                    # SAML2 attribute value
                    my $saml2value = $self->createAttributeValue( $_,
                        $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
                          ->{samlSPMetaDataOptionsForceUTF8} );

                    unless ($saml2value) {
                        $self->logger->error(
                            "Unable to create a new SAML attribute value");
                        $self->checkLassoError($@);
                        return PE_SAML_SSO_ERROR;
                    }

                    push @saml2values, $saml2value;

                    $self->logger->debug("Push $_ in SAML attribute $name");

                }

                $attribute->AttributeValue(@saml2values);

                # Push attribute in attribute list
                push @attributes, $attribute;

            }

            # Get response assertion
            my @response_assertions = $login->response->Assertion;

            unless ( $response_assertions[0] ) {
                $self->logger->error("Unable to get response assertion");
                return PE_SAML_SSO_ERROR;
            }

            # Rewrite Issuer with domain
            if ($domain) {
                my $original_issuer = $login->response->Issuer->content;
                $self->logger->debug(
                    "Add domain $domain to Issuer $original_issuer");
                my $new_issuer = $original_issuer . "?domain=$domain";
                $login->response->Issuer->content($new_issuer);
                $login->response->Assertion->Issuer->content($new_issuer);
            }

            # Set subject NameID
            $response_assertions[0]
              ->set_subject_name_id( $login->nameIdentifier );

            # Set basic conditions
            my $oneTimeUse = $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsOneTimeUse} // 0;

            my $conditionNotOnOrAfter = $notOnOrAfterTimeout || "86400";
            eval {
                $response_assertions[0]
                  ->set_basic_conditions( 60, $conditionNotOnOrAfter,
                    $oneTimeUse );
            };
            if ($@) {
                $self->logger->debug("Basic conditions not set: $@");
            }

            # Create attribute statement
            if ( scalar @attributes ) {

                my $attribute_statement;

                eval {
                    $attribute_statement =
                      Lasso::Saml2AttributeStatement->new();
                };
                if ($@) {
                    $self->checkLassoError($@);
                    return PE_SAML_SSO_ERROR;
                }

                # Register attributes in attribute statement
                $attribute_statement->Attribute(@attributes);

                # Add attribute statement in response assertion
                my @attributes_statement = ($attribute_statement);
                $response_assertions[0]
                  ->AttributeStatement(@attributes_statement);
            }

            # Get AuthnStatement
            my @authn_statements = $response_assertions[0]->AuthnStatement();

            # Set sessionIndex
            my $sessionIndexSession = $self->getSamlSession();
            return PE_SAML_SESSION_ERROR unless $sessionIndexSession;

            $sessionIndexSession->update(
                { '_utime' => time, '_saml_id' => $session_id } );
            my $sessionIndex = $sessionIndexSession->id;

            $authn_statements[0]->SessionIndex($sessionIndex);

            $self->logger->debug(
                "Set sessionIndex $sessionIndex (linked to session $session_id)"
            );

            # Set SessionNotOnOrAfter
            my $sessionNotOnOrAfterTimeout =
              $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSessionNotOnOrAfterTimeout};
            $sessionNotOnOrAfterTimeout ||= $self->conf->{timeout};
            my $timeout             = $time + $sessionNotOnOrAfterTimeout;
            my $sessionNotOnOrAfter = $self->timestamp2samldate($timeout);
            $authn_statements[0]->SessionNotOnOrAfter($sessionNotOnOrAfter);

            $self->logger->debug(
                "Set sessionNotOnOrAfter $sessionNotOnOrAfter");

            # Register AuthnStatement in assertion
            $response_assertions[0]->AuthnStatement(@authn_statements);

            # Set response assertion
            $login->response->Assertion(@response_assertions);

            # Signature
            my $signSSOMessage =
              $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSignSSOMessage} // -1;

            if ( $signSSOMessage == 0 ) {
                $self->logger->debug("SSO response will not be signed");
                $self->disableSignature($login);
            }
            elsif ( $signSSOMessage == 1 ) {
                $self->logger->debug("SSO response will be signed");
                $self->forceSignature($login);
            }
            else {
                $self->logger->debug(
                    "SSO response signature according to metadata");
            }

            # log that a SAML authn response is build
            my $user      = $req->{sessionInfo}->{ $self->conf->{whatToTrace} };
            my $nameIDLog = '';
            foreach my $format (qw(persistent transient)) {
                if ( $login->nameIdentifier->Format eq
                    $self->getNameIDFormat($format) )
                {
                    $nameIDLog =
                      " with $format NameID " . $login->nameIdentifier->content;
                    last;
                }
            }
            $self->userLogger->notice(
"SAML authentication response sent to SAML SP $spConfKey for $user$nameIDLog"
            );

            # Build SAML response
            $protocolProfile = $login->protocolProfile();

            # Artifact
            # Choose method
            if (   $artifact
                or $protocolProfile ==
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_BRWS_ART )
            {
                $artifact = 1;
                if (   $method == $self->getHttpMethod("post")
                    || $method == $self->getHttpMethod("artifact-post") )
                {
                    $artifact_method = $self->getHttpMethod("artifact-post");

                }
                else {
                    $artifact_method = $self->getHttpMethod("artifact-get");
                }
            }

            if ( $protocolProfile ==
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_BRWS_ART )
            {

                # Build artifact message
                unless ( $self->buildArtifactMsg( $login, $artifact_method ) ) {
                    $self->logger->error(
                        "Unable to build SSO artifact response message");
                    return PE_SAML_ART_ERROR;
                }

                $self->logger->debug("SSO: artifact response is built");

                # Get artifact ID and Content, and store them
                my $artifact_id      = $login->get_artifact;
                my $artifact_message = $login->get_artifact_message;

                $self->storeArtifact( $artifact_id, $artifact_message,
                    $session_id );
            }

            # No artifact
            else {

                unless ( $self->buildAuthnResponseMsg($login) ) {
                    $self->logger->error(
                        "Unable to build SSO response message");
                    return PE_SAML_SSO_ERROR;
                }

                $self->logger->debug("SSO: authentication response is built");

            }

            # Save Identity and Session
            if ( $login->is_identity_dirty ) {

                # Update session
                $self->logger->debug("Save Lasso identity in session");
                $self->p->updatePersistentSession( $req,
                    { $self->liDump => $login->get_identity->dump },
                    undef, $session_id );
            }

            if ( $login->is_session_dirty ) {
                $self->logger->debug("Save Lasso session in session");
                $self->p->updateSession( $req,
                    { $self->lsDump => $login->get_session->dump },
                    $session_id );
            }

            # Keep SAML elements for later queries
            my $nameid = $login->nameIdentifier;

            $self->logger->debug( "Store NameID "
                  . $nameid->dump
                  . " and SessionIndex $sessionIndex for session $session_id" );

            my $infos;

            $infos->{type}          = 'saml';           # Session type
            $infos->{_utime}        = $time;            # Creation time
            $infos->{_saml_id}      = $session_id;      # SSO session id
            $infos->{_nameID}       = $nameid->dump;    # SAML NameID
            $infos->{_sessionIndex} = $sessionIndex;    # SAML SessionIndex

            my $samlSessionInfo = $self->getSamlSession( undef, $infos );

            return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

            my $saml_session_id = $samlSessionInfo->id;

            $self->logger->debug(
                "Link session $session_id to SAML session $saml_session_id");

            # Send SSO Response

            # Register IDP in Common Domain Cookie if needed
            if (    $self->conf->{samlCommonDomainCookieActivation}
                and $self->conf->{samlCommonDomainCookieWriter} )
            {
                my $cdc_idp = $self->getMetaDataURL( "samlEntityID", 0, 1 );

                $self->logger->debug(
                    "Will register IDP $cdc_idp in Common Domain Cookie");

                # Redirection to CDC Writer page in a hidden iframe
                my $cdc_writer_url =
                  $self->conf->{samlCommonDomainCookieWriter};
                $cdc_writer_url .= (
                    $self->conf->{samlCommonDomainCookieWriter} =~ /\?/
                    ? '&idp=' . $cdc_idp
                    : '?url=' . $cdc_idp
                );

                my $cdc_iframe =
                    qq'<iframe src="$cdc_writer_url"'
                  . ' alt="Common Dommain Cookie" marginwidth="0"'
                  . ' marginheight="0" scrolling="no" class="hiddenFrame"'
                  . ' width="0" height="0" frameborder="0"></iframe>';

                $req->info(
                    $self->loadTemplate(
                        $req, 'simpleInfo',
                        params => { trspan => 'updateCdc' }
                      )
                      . $cdc_iframe
                );
            }

            # HTTP-POST
            if ( (
                       !$artifact
                    and $protocolProfile eq
                    Lasso::Constants::LOGIN_PROTOCOL_PROFILE_BRWS_POST
                )
                or (    $artifact
                    and $artifact_method ==
                    $self->getHttpMethod("artifact-post") )
              )
            {

                # Use autosubmit form
                my $sso_url  = $login->msg_url;
                my $sso_body = $login->msg_body;

                $req->postUrl($sso_url);

                if (    $artifact_method
                    and $artifact_method ==
                    $self->getHttpMethod("artifact-post") )
                {
                    $req->{postFields} = { 'SAMLart' => $sso_body };
                }
                else {
                    $req->{postFields} = { 'SAMLResponse' => $sso_body };
                }

                # RelayState
                $req->{postFields}->{'RelayState'} = $relaystate
                  if ($relaystate);

                $req->steps( ['autoPost'] );
                return PE_OK;
            }

            # HTTP-REDIRECT
            if ( $protocolProfile eq
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_REDIRECT or $artifact )
            {

                # Redirect user to response URL
                my $sso_url = $login->msg_url;
                $self->logger->debug("Redirect user to $sso_url");

                $req->{urldc} = $sso_url;
                $req->mustRedirect(1);
                $req->steps( [] );

                return PE_OK;
            }

        }

        elsif ($response) {
            $self->logger->debug(
                "Authentication responses are not managed by this module");
            return PE_OK;
        }

        else {

            # No request or response
            # This should not happen
            $self->logger->debug("No request or response found");
            return PE_OK;
        }

    }
    $self->logger->debug("Not an issuer request $url");
    return PE_OK;
}

sub artifactServer {
    my ( $self, $req ) = @_;
    $self->logger->debug( "URL "
          . $req->uri
          . " detected as an artifact resolution service URL" );

    # Artifact request are sent with SOAP trough POST
    my $art_request = $req->content;
    my $art_response;

    # Create Login object
    my $login = $self->createLogin( $self->lassoServer );

    # Process request message
    unless ( $self->processArtRequestMsg( $login, $art_request ) ) {
        return $self->p->sendError( $req,
            'Unable to process artifact request message', 400 );
    }

    # Check Destination
    unless ( $self->checkDestination( $login->request, $req->uri ) ) {
        return $self->p->sendError( $req, 'Bad request', 400 );
    }

    # Create artifact response
    unless ( $art_response = $self->createArtifactResponse( $req, $login ) ) {
        return $self->p->sendError( $req,
            "Unable to create artifact response message", 400 );
    }

    $self->{SOAPMessage} = $art_response;

    # Return SOAP message
    $self->logger->debug("Send SOAP Message: $art_response");
    return [
        200,
        [
            'Content-Type'   => 'application/xml',
            'Content-Length' => length($art_response)
        ],
        [$art_response]
    ];
}

sub soapSloServer {
    my ( $self, $req ) = @_;
    my $url            = $req->uri;
    my $request_method = $req->param('issuerMethod') || $req->method;
    my $content_type   = $req->content_type();

    $self->logger->debug("URL $url detected as an SLO URL");

    # Check SAML Message
    my ( $request, $response, $method, $relaystate, $artifact ) =
      $self->checkMessage( $req, $url, $request_method, $content_type,
        "logout" );

    # Create Logout object
    my $logout = $self->createLogout( $self->lassoServer );

    # Ignore signature verification
    $self->disableSignatureVerification($logout);

    if ($request) {

        # Process logout request
        unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
            return $self->p->sendError( $req,
                "SLO: Fail to process logout request", 400 );
        }

        $self->logger->debug("SLO: Logout request is valid");

        # We accept only SOAP here
        unless ( $method eq $self->getHttpMethod('soap') ) {
            return $self->p->sendError( $req,
                "Only SOAP requests allowed here", 400 );
        }

        # Get SP entityID
        my $sp = $logout->remote_providerID();

        $self->logger->debug("Found entityID $sp in SAML message");

        # SP conf key
        my $spConfKey = $self->spList->{$sp}->{confKey};

        unless ($spConfKey) {
            return $self->p->sendError( $req,
                "$sp do not match any SP in configuration", 400 );
        }

        $self->logger->debug("$sp match $spConfKey SP in configuration");

        # Do we check signature?
        my $checkSLOMessageSignature =
          $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
          ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

        if ($checkSLOMessageSignature) {

            $self->forceSignatureVerification($logout);

            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                return $self->p->sendError( $req, "Signature is not valid",
                    400 );
            }
            else {
                $self->logger->debug("Signature is valid");
            }
        }
        else {
            $self->logger->debug("Message signature will not be checked");
        }

        # Get SAML request
        my $saml_request = $logout->request();
        unless ($saml_request) {
            return $self->p->sendError( $req, "No SAML request found", 400 );
        }

        # Check Destination
        return $self->sendSLOSoapErrorResponse( $req, $logout, $method )
          unless ( $self->checkDestination( $saml_request, $url ) );

        # Get session index
        my $session_index;
        eval { $session_index = $logout->request()->SessionIndex; };

        # SLO requests without session index are not accepted in SOAP mode
        unless ( defined $session_index ) {
            $self->p->sendError( $req,
                "No session index in SLO request from $spConfKey SP", 400 );
        }

        # Get session index
        my $sessionIndexSession = $self->getSamlSession($session_index);
        return $self->p->sendError( $req, 'SAML session not found', 400 )
          unless $sessionIndexSession;

        my $local_session_id = $sessionIndexSession->data->{_saml_id};

        $sessionIndexSession->remove;

        $self->logger->debug(
"Get session id $local_session_id (from session index $session_index)"
        );

        # Open local session
        my $local_session = $self->p->getApacheSession($local_session_id);

        unless ($local_session) {
            return $self->p->sendError( $req, "No local session found", 400 );
        }

        # Load Session and Identity if they exist
        my $session  = $local_session->data->{ $self->lsDump };
        my $identity = $local_session->data->{ $self->liDump };

        if ($session) {
            unless ( $self->setSessionFromDump( $logout, $session ) ) {
                return $self->p->sendError( $req,
                    "Unable to load Lasso Session", 400 );
            }
            $self->logger->debug("Lasso Session loaded");
        }

        if ($identity) {
            unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
                return $self->p->sendError( $req,
                    "Unable to load Lasso Identity", 400 );
            }
            $self->logger->debug("Lasso Identity loaded");
        }

        # Close SAML sessions
        unless ( $self->deleteSAMLSecondarySessions($local_session_id) ) {
            return $self->p->sendError( $req, "Fail to delete SAML sessions",
                400 );
        }

        # Close local session
        unless ( $self->p->_deleteSession( $req, $local_session ) ) {
            return $self->p->sendError( $req,
                "Fail to delete session $local_session_id", 400 );
        }

        # Validate request if no previous error
        unless ( $self->validateLogoutRequest($logout) ) {
            return $self->p->sendError( $req, "SLO request is not valid", 400 );
        }

        # Try to send SLO request trough SOAP
        $self->resetProviderIdIndex($logout);
        while ( my $providerID = $self->getNextProviderId($logout) ) {

            # Send logout request
            my ( $rstatus, $rmethod, $rinfo ) =
              $self->sendLogoutRequestToProvider( $logout, $providerID,
                $self->getHttpMethod('soap'), 0 );

            if ($rstatus) {
                $self->logger->debug("SOAP SLO successful on $providerID");
            }
            else {
                $self->logger->debug("SOAP SLO error on $providerID");
            }
        }

        # Set RelayState
        if ($relaystate) {
            $logout->msg_relayState($relaystate);
            $self->logger->debug("Set $relaystate in RelayState");
        }

        # Signature
        my $signSLOMessage = $self->{samlSPMetaDataOptions}->{$spConfKey}
          ->{samlSPMetaDataOptionsSignSLOMessage} // 0;

        if ( $signSLOMessage == 0 ) {
            $self->logger->debug("SLO response will not be signed");
            $self->disableSignature($logout);
        }
        elsif ( $signSLOMessage == 1 ) {
            $self->logger->debug("SLO response will be signed");
            $self->forceSignature($logout);
        }
        else {
            $self->logger->debug(
                "SLO response signature according to metadata");
        }

        # Send logout response
        unless ( $self->buildLogoutResponseMsg($logout) ) {
            $self->logger->error("Unable to build SLO response");
            return $self->p->sendError( $req, 'Unable to build SLO response',
                400 );
        }
        my $slo_body = $logout->msg_body;
        return [
            200,
            [
                'Content-Type'   => 'application/xml',
                'Content-Length' => length($slo_body)
            ],
            [$slo_body]
        ];
    }

}

sub logout {
    my ( $self, $req ) = @_;
    return PE_OK if ( $req->data->{samlSLOCalled} );

    # Session ID
    my $session_id = $req->{sessionInfo}->{_session_id} || $req->{id};

    # Close SAML sessions
    unless ( $self->deleteSAMLSecondarySessions($session_id) ) {
        $self->logger->error("Fail to delete SAML sessions");
    }

    # Create Logout object
    my $logout = $self->createLogout( $self->lassoServer );

    # Load Session and Identity if they exist
    my $session  = $req->{sessionInfo}->{ $self->lsDump };
    my $identity = $req->{sessionInfo}->{ $self->liDump };

    if ($session) {
        unless ( $self->setSessionFromDump( $logout, $session ) ) {
            $self->logger->error("Unable to load Lasso Session");
            return PE_SAML_SLO_ERROR;
        }
        $self->logger->debug("Lasso Session loaded");
    }

    # No need to initiate logout requests on SP, if no SAML session is
    # available into the session.
    else {
        $self->logger->debug('No SAML session available into this session');
        return PE_OK;
    }

    if ($identity) {
        unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
            $self->logger->error("Unable to load Lasso Identity");
            return PE_SAML_SLO_ERROR;
        }
        $self->logger->debug("Lasso Identity loaded");
    }

    # Proceed to logout on all others SP.
    # Verify that logout response is correctly sent. If we have to wait for
    # providers during HTTP-REDIRECT process, return PE_INFO to notify to wait
    # for them.
    # Redirect on logout page when all is done.
    if ( $self->sendLogoutRequestToProviders( $req, $logout ) ) {
        $self->{urldc} = $req->script_name . "?logout=1";
        return PE_OK;
    }

    return PE_OK;
}

sub sloRelaySoap {
    my ( $self, $req ) = @_;
    $self->logger->debug(
        "URL " . $req->uri . " detected as a SOAP relay service URL" );

    # Check if relay parameter is present (mandatory)
    my $relayID;
    unless ( $relayID = $req->param('relay') ) {
        $self->logger->error("No relayID detected");
        return $self->imgnok($req);
    }

    # Retrieve the corresponding data from samlStorage
    my $relayInfos = $self->getSamlSession($relayID);
    unless ($relayInfos) {
        $self->logger->error("Could not get relay session $relayID");
        return $self->imgnok($req);
    }

    $self->logger->debug("Found relay session $relayID");

    # Rebuild the logout object
    my $logout;
    unless ( $logout = $self->createLogout( $self->lassoServer ) ) {
        $self->logger->error("Could not rebuild logout object");
        return $self->imgnok($req);
    }

    # Load Session and Identity if they exist
    my $session    = $relayInfos->data->{ $self->lsDump };
    my $identity   = $relayInfos->data->{ $self->liDump };
    my $providerID = $relayInfos->data->{_providerID};
    my $relayState = $relayInfos->data->{_relayState} // '';
    my $spConfKey  = $self->spList->{$providerID}->{confKey};

    if ($session) {
        unless ( $self->setSessionFromDump( $logout, $session ) ) {
            $self->logger->error("Unable to load Lasso Session");
            return $self->imgnok($req);
        }
        $self->logger->debug("Lasso Session loaded");
    }

    if ($identity) {
        unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
            $self->logger->error("Unable to load Lasso Identity");
            return $self->imgnok($req);
        }
        $self->logger->debug("Lasso Identity loaded");
    }

    # Send the logout request
    my ( $rstatus, $rmethod, $rinfo ) =
      $self->sendLogoutRequestToProvider( $req, $logout, $providerID,
        Lasso::Constants::HTTP_METHOD_SOAP,
        undef, $relayState );
    unless ($rstatus) {
        $self->logger->error(
            "Fail to process SOAP logout request to $providerID");
        return $self->imgnok($req);
    }

    # Store success status for this SLO request
    my $sloStatusSessionInfos =
      $self->getSamlSession( $relayState, { $spConfKey => 1 } );

    if ($sloStatusSessionInfos) {
        $self->logger->debug(
            "Store SLO status for $spConfKey in session $relayState");
    }
    else {
        $self->logger->warn(
            "Unable to store SLO status for $spConfKey in session $relayState");
    }

    # Delete relay session
    $relayInfos->remove();

    # SLO response is OK
    $self->logger->debug("Display OK status for SLO on $spConfKey");
    return $self->imgok($req);
}

sub sloRelayPost {
    my ( $self, $req ) = @_;
    $self->logger->debug(
        "URL " . $req->uri . " detected as a POST relay service URL" );

    # Check if relay parameter is present (mandatory)
    my $relayID;
    unless ( $relayID = $req->param('relay') ) {
        return $self->p->sendError( $req, 'No relayID detected' );
    }

    # Retrieve the corresponding data from samlStorage
    my $relayInfos = $self->getSamlSession($relayID);
    unless ($relayInfos) {
        return $self->p->sendError( $req,
            "Could not get relay session $relayID" );
    }

    $self->logger->debug("Found relay session $relayID");

    # Get data to build POST form
    $req->{postUrl}                     = $relayInfos->data->{url};
    $req->{postFields}->{'SAMLRequest'} = $relayInfos->data->{body};
    $req->{postFields}->{'RelayState'}  = $relayInfos->data->{relayState};

    # Delete relay session
    $relayInfos->remove();
    $req->frame(1);
    return $self->p->do( $req, ['autoPost'] );
}

sub sloRelayTerm {
    my ( $self, $req ) = @_;
    $self->logger->debug( "URL "
          . $req->uri
          . " detected as a SLO Termination relay service URL" );

    # Check if relay parameter is present (mandatory)
    my $relayID = $self->p->getHiddenFormValue( $req, 'relay', '', 0 )
      || $req->param('relay');
    unless ($relayID) {
        return $self->p->sendError( $req, 'No relayID detected' );
    }

    # Retrieve the corresponding data from samlStorage
    my $relayInfos = $self->getSamlSession($relayID);
    unless ($relayInfos) {
        return $self->p->sendError( $req,
            "Could not get relay session $relayID" );
    }

    $self->logger->debug("Found relay session $relayID");

    # Get data from relay session
    my $logout_dump  = $relayInfos->data->{_logout};
    my $session_dump = $relayInfos->data->{_session};
    my $method       = $relayInfos->data->{_method};

    unless ($logout_dump) {
        $self->logger->error("Could not get logout dump");
        return PE_SAML_SLO_ERROR;
    }

    # Rebuild Lasso::Logout object
    my $logout = $self->createLogout( $self->lassoServer, $logout_dump );

    unless ($logout) {
        $self->logger->error("Could not build Lasso::Logout");
        return PE_SAML_SLO_ERROR;
    }

    # Inject session
    unless ($session_dump) {
        $self->logger->error("Could not get session dump");
        return PE_SAML_SLO_ERROR;
    }

    unless ( $self->setSessionFromDump( $logout, $session_dump ) ) {
        $self->logger->error("Could not set session from dump");
        return PE_SAML_SLO_ERROR;
    }

    # Get Lasso::Session
    my $session = $logout->get_session();

    unless ($session) {
        $self->lmLog( "Could not get session from logout", 'error' );
        return PE_SAML_SLO_ERROR;
    }

    # Loop on assertions and remove them if SLO status is OK
    $self->resetProviderIdIndex($logout);

    while ( my $sp = $self->getNextProviderId($logout) ) {

        # Try to get SLO status from SLO session
        my $spConfKey = $self->spList->{$sp}->{confKey};
        my $status    = $relayInfos->data->{$spConfKey};

        # Remove assertion if status is OK
        if ($status) {
            eval { $session->remove_assertion($sp); };

            if ($@) {
                $self->logger->warn("Unable to remove assertion for $sp");
            }
            else {
                $self->logger->debug("Assertion removed for $sp");
            }
        }
        else {
            $self->logger->debug(
                "SLO status was not ok for $sp, assertion not removed");
        }
    }

    # Reinject session
    unless ( $session->is_empty() ) {
        $self->setSessionFromDump( $logout, $session->dump );
    }

    # Delete relay session
    $relayInfos->remove();

    # Send SLO response
    if ( my $tmp =
        $self->sendLogoutResponseToServiceProvider( $req, $logout, $method ) )
    {
        return $tmp;
    }
    else {
        $self->logger->error("Fail to send SLO response");
        return PE_SAML_SLO_ERROR;
    }

}

sub authSloServer {
    my ( $self, $req ) = @_;
    $self->p->importHandlerData($req);
    return $self->sloServer($req);
}

sub sloServer {
    my ( $self, $req ) = @_;
    my $url            = $req->uri;
    my $request_method = $req->param('issuerMethod') || $req->method;
    my $content_type   = $req->content_type();
    $self->logger->debug("URL $url detected as an SLO URL");

    # Check SAML Message
    my ( $request, $response, $method, $relaystate, $artifact ) =
      $self->checkMessage( $req, $url, $request_method, $content_type,
        "logout" );

    # Create Logout object
    my $logout = $self->createLogout( $self->lassoServer );

    # Ignore signature verification
    $self->disableSignatureVerification($logout);

    # Disable Content-Security-Policy header since logout can be embedded in
    # a frame
    $req->frame(1);

    if ($request) {

        # Process logout request
        unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
            return $self->p->sendError( $req,
                "SLO: Fail to process logout request", 400 );
        }

        $self->logger->debug("SLO: Logout request is valid");

        # Get SP entityID
        my $sp = $logout->remote_providerID();
        $req->env->{llng_saml_sp} = $sp;

        $self->logger->debug("Found entityID $sp in SAML message");

        # SP conf key
        my $spConfKey = $self->spList->{$sp}->{confKey};

        unless ($spConfKey) {
            return $self->p->sendError( $req,
                "$sp do not match any SP in configuration", 400 );
        }

        $self->logger->debug("$sp match $spConfKey SP in configuration");
        $req->env->{llng_saml_spconfkey} = $spConfKey;

        # Load Session and Identity if they exist
        my ( $session, $session_index, $identity, $local_session_id );

        eval { $session_index = $logout->request()->SessionIndex; };

        # SLO requests without session index can be accepted
        unless ( defined $session_index ) {
            $self->logger->warn(
                "No session index in SLO request from $spConfKey SP");
        }

        if ($session_index) {
            my $sessionIndexSession = $self->getSamlSession($session_index);
            return $self->p->sendError( $req, 'SAML session not found', 400 )
              unless $sessionIndexSession;

            $local_session_id = $sessionIndexSession->data->{_saml_id};

            $sessionIndexSession->remove;

            $self->logger->debug(
"Get session id $local_session_id (from session index $session_index)"
            );
        }
        else {
            $local_session_id = $req->id;
            $self->logger->debug(
                "Get session id $local_session_id (from cookie)");
        }
        if ( $req->{sessionInfo} ) {
            $session  = $req->{sessionInfo}->{ $self->lsDump };
            $identity = $req->{sessionInfo}->{ $self->liDump };
        }
        unless ($session) {

            # Open local session
            my $local_session = $self->p->getApacheSession($local_session_id);

            unless ($local_session) {
                $self->logger->error("No local session found");
                return $self->sendSLOErrorResponse( $req, $logout, $method );
            }

            # Load Session and Identity if they exist
            $session  = $local_session->data->{ $self->lsDump };
            $identity = $local_session->data->{ $self->liDump };

            # Import user data in $req (for other "logout" subs)
            $req->id( $local_session->data->{_session_id} );
            $req->sessionInfo( $local_session->data );
            $req->user( $local_session->data->{ $self->conf->{whatToTrace} } );
        }

        if ($session) {
            unless ( $self->setSessionFromDump( $logout, $session ) ) {
                return $self->p->sendError( $req,
                    "Unable to load Lasso Session", 400 );
            }
            $self->logger->debug("Lasso Session loaded");
        }

        if ($identity) {
            unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
                return $self->p->sendError( $req,
                    "Unable to load Lasso Identity", 400 );
            }
            $self->logger->debug("Lasso Identity loaded");
        }

        # Do we check signature?
        my $checkSLOMessageSignature =
          $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
          ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

        if ($checkSLOMessageSignature) {

            $self->forceSignatureVerification($logout);

            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                return $self->p->sendError( $req, "Signature is not valid",
                    400 );
            }
            else {
                $self->logger->debug("Signature is valid");
            }
        }
        else {
            $self->logger->debug("Message signature will not be checked");
        }

        # Check Destination
        return $self->sendSLOErrorResponse( $req, $logout, $method )
          unless ( $self->checkDestination( $logout->request, $url ) );

        # Validate request if no previous error
        unless ( $self->validateLogoutRequest($logout) ) {
            return $self->p->sendError( $req, "SLO request is not valid", 400 );
        }

        # Set RelayState
        if ($relaystate) {
            $logout->msg_relayState($relaystate);
            $self->logger->debug("Set $relaystate in RelayState");
        }

        my $sloInfos;
        $sloInfos->{type}    = 'sloStatus';
        $sloInfos->{_utime}  = time;
        $sloInfos->{_logout} = $logout->dump;
        $sloInfos->{_session} =
          $logout->get_session() ? $logout->get_session()->dump : "";
        $sloInfos->{_method} = $method;

        # Create SLO status session and get ID
        my $sloStatusSessionInfo = $self->getSamlSession( undef, $sloInfos );
        my $relayID = $sloStatusSessionInfo->id;

        $self->logger->debug("Create relay session $relayID");

        # Prepare logout on all others SP
        my $provider_nb =
          $self->sendLogoutRequestToProviders( $req, $logout, $relayID );

        # Close SAML sessions
        unless ( $self->deleteSAMLSecondarySessions($local_session_id) ) {
            $self->logger->error("Fail to delete SAML sessions");
        }

        # Close local session
        # This flag is for logout() to say that SAML logout is already done
        $req->data->{samlSLOCalled} = 1;

        # Launch normal logout and ignore errors
        $self->p->do( $req, [ @{ $self->p->beforeLogout }, 'deleteSession' ] );

        # Signature
        my $signSLOMessage = $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
          ->{samlSPMetaDataOptionsSignSLOMessage};

        unless ($signSLOMessage) {
            $self->logger->debug("Do not sign this SLO response");
            return $self->sendSLOErrorResponse( $req, $logout, $method )
              unless ( $self->disableSignature($logout) );
        }

        # If no waiting SP, return directly SLO response
        unless ($provider_nb) {
            return $self->sendLogoutResponseToServiceProvider( $req, $logout,
                $method );
        }

        # Else build SLO status relay URL and display info
        else {
            $req->{urldc} =
              $self->conf->{portal} . '/saml/relaySingleLogoutTermination';
            $self->p->setHiddenFormValue( $req, 'relay', $relayID, '', 0 );
            return $self->p->do( $req, [] );
        }
    }

    elsif ($response) {

        # Process logout response
        my $result = $self->processLogoutResponseMsg( $logout, $response );

        unless ($result) {
            $self->logger->error("Fail to process logout response");
            $self->imgnok($req);
        }

        $self->logger->debug("Logout response is valid");

        # Check Destination
        $self->imgnok($req)
          unless ( $self->checkDestination( $logout->response, $url ) );

        # Get SP entityID
        my $sp = $logout->remote_providerID();

        $self->logger->debug("Found entityID $sp in SAML message");

        # SP conf key
        my $spConfKey = $self->spList->{$sp}->{confKey};

        unless ($spConfKey) {
            $self->logger->error("$sp do not match any SP in configuration");
            $self->imgnok($req);
        }

        $self->logger->debug("$sp match $spConfKey SP in configuration");

        # Do we check signature?
        my $checkSLOMessageSignature =
          $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
          ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

        if ($checkSLOMessageSignature) {
            unless ( $self->checkSignatureStatus($logout) ) {
                $self->logger->error("Signature is not valid");
                $self->imgnok($req);
            }
            else {
                $self->logger->debug("Signature is valid");
            }
        }
        else {
            $self->logger->debug("Message signature will not be checked");
        }

        # Store success status for this SLO request
        if ($relaystate) {
            my $sloStatusSessionInfos = $self->getSamlSession($relaystate);

            if ($sloStatusSessionInfos) {
                $sloStatusSessionInfos->update( { $spConfKey => 1 } );
                $self->logger->debug(
                    "Store SLO status for $spConfKey in session $relaystate");
            }
            else {
                $self->logger->warn(
"Unable to store SLO status for $spConfKey in session $relaystate"
                );
            }
        }
        else {
            $self->logger->warn(
"Unable to store SLO status for $spConfKey because there is no RelayState"
            );
        }

        # SLO response is OK
        $self->logger->debug("Display OK status for SLO on $spConfKey");
        $self->imgok($req);
    }

    else {

        # No request or response
        # This should not happen
        return $self->p->sendError( $req, "No request or response found", 400 );
    }
}

sub attributeServer {
    my ( $self, $req, ) = @_;
    my $url = $req->uri;
    $self->logger->debug("URL $url detected as an attribute service URL");

    # Attribute request are sent with SOAP trough POST
    my $att_request = $req->content;
    my $att_response;

    # Process request
    my $query =
      $self->processAttributeRequest( $self->lassoServer, $att_request );
    unless ($query) {
        return $self->p->sendError( $req,
            "Unable to process attribute request", 400 );
    }

    # Get SP entityID
    my $sp = $query->remote_providerID();

    $self->logger->debug("Found entityID $sp in SAML message");

    # SP conf key
    my $spConfKey = $self->spList->{$sp}->{confKey};

    unless ($spConfKey) {
        return $self->p->sendError( $req,
            "$sp do not match any SP in configuration", 400 );
    }

    $self->logger->debug("$sp match $spConfKey SP in configuration");

    # Check Destination
    unless ( $self->checkDestination( $query->request, $url ) ) {
        return $self->p->sendError( $req, "Bad destination $url", 400 );
    }

    # Validate request
    unless ( $self->validateAttributeRequest($query) ) {
        return $self->p->sendError( $req, "Attribute request not valid", 400 );
    }

    # Get NameID
    my $name_id = $query->nameIdentifier();

    unless ($name_id) {
        $self->p->sendError( $req, "Fail to get NameID from attribute request",
            400 );
    }

    my $user = $name_id->content();

    # Get sessionInfo for the given NameID
    my $sessionInfo;

    my $saml_sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $self->amOpts,
        "_nameID", $name_id->dump );

    if (
        my @saml_sessions_keys =
        grep { $saml_sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$saml_sessions
      )
    {

        # Warning if more than one session found
        if ( $#saml_sessions_keys > 0 ) {
            $self->logger->warn(
                "More than one SAML session found for user $user");
        }

        # Take the first session
        my $saml_session = shift @saml_sessions_keys;

        # Get session
        $self->logger->debug(
            "Retrieve SAML session $saml_session for user $user");

        my $samlSessionInfo = $self->getSamlSession($saml_session);

        # Get real session
        my $real_session = $samlSessionInfo->data->{_saml_id};

        $self->logger->debug(
            "Retrieve real session $real_session for user $user");

        $sessionInfo = $self->p->getApacheSession($real_session);

        unless ($sessionInfo) {
            return $self->p->sendError( $req,
                "Cannot get session $real_session", 500 );
        }

    }
    else {
        return $self->p->sendError( $req,
            "No SAML session found for user $user", 400 );
    }

    # Get requested attributes
    my @requested_attributes;
    eval { @requested_attributes = $query->request()->Attribute(); };
    if ($@) {
        $self->checkLassoError($@);
        return $self->p->sendError( $req, "Unable to get requested attributes",
            400 );
    }

    # Returned attributes
    my @returned_attributes;

    # Browse SP authorized attributes
    foreach (
        keys %{ $self->conf->{samlSPMetaDataExportedAttributes}->{$spConfKey} }
      )
    {
        my $sp_attr = $_;

        # Extract fields from exportedAttr value
        my ( $mandatory, $name, $format, $friendly_name ) =
          split( /;/,
            $self->conf->{samlSPMetaDataExportedAttributes}->{$spConfKey}
              ->{$sp_attr} );

        foreach (@requested_attributes) {
            my $req_attr       = $_;
            my $rname          = $req_attr->Name();
            my $rformat        = $req_attr->NameFormat();
            my $rfriendly_name = $req_attr->FriendlyName();

            # Skip if name does not match
            next unless ( $rname =~ /^$name$/ );

            # Check format and friendly name
            next if ( $rformat and $rformat !~ /^$format$/ );
            next
              if (  $rfriendly_name
                and $rfriendly_name !~ /^$friendly_name$/ );

            $self->logger->debug(
                "SP $spConfKey is authorized to access attribute $rname");

            $self->logger->debug(
                "Attribute $rname is linked to $sp_attr session key");

            # Check if values are given
            my $rvalue =
              $self->getAttributeValue( $rname, $rformat, $rfriendly_name,
                [$req_attr] );

            $self->logger->debug(
                "Some values are explicitely requested: $rvalue")
              if defined $rvalue;

            # Get session value
            if ( $sessionInfo->data->{$sp_attr} ) {

                my @values = split $self->conf->{multiValuesSeparator},
                  $sessionInfo->data->{$sp_attr};
                my @saml2values;

                # SAML2 attribute
                my $ret_attr =
                  $self->createAttribute( $rname, $rformat, $rfriendly_name );

                unless ($ret_attr) {
                    return $self->p->sendError( $req,
                        "Unable to create a new SAML attribute", 500 );
                }

                foreach (@values) {

                    my $local_value = $_;

                    # Check if values were set in requested attribute
                    # In this case, only requested values can be returned
                    if (
                        $rvalue
                        and !map( /^$local_value$/,
                            split(
                                $self->conf->{multiValuesSeparator}, $rvalue
                            ) )
                      )
                    {
                        $self->logger->warn(
"$local_value value is not in requested values, it will not be sent"
                        );
                        next;
                    }

                    # SAML2 attribute value
                    my $saml2value = $self->createAttributeValue( $local_value,
                        $self->conf->{samlSPMetaDataOptions}->{$spConfKey}
                          ->{samlSPMetaDataOptionsForceUTF8} );

                    unless ($saml2value) {
                        return $self->p->sendError( $req,
                            "Unable to create a new SAML attribute value",
                            400 );
                    }

                    push @saml2values, $saml2value;

                    $self->logger->debug(
                        "Push $local_value in SAML attribute $name");

                }

                $ret_attr->AttributeValue(@saml2values);

                # Push attribute in attribute list
                push @returned_attributes, $ret_attr;

            }
            else {
                $self->logger->debug("No session value for $sp_attr");
            }

        }

    }

    # Create attribute statement
    if ( scalar @returned_attributes ) {
        my $attribute_statement;

        eval { $attribute_statement = Lasso::Saml2AttributeStatement->new(); };
        if ($@) {
            $self->checkLassoError($@);
            return $self->p->sendError( $req, 'An error occurs, see IdP logs',
                500 );
        }

        # Register attributes in attribute statement
        $attribute_statement->Attribute(@returned_attributes);

        # Create assetion
        my $assertion;

        eval { $assertion = Lasso::Saml2Assertion->new(); };
        if ($@) {
            $self->checkLassoError($@);
            return $self->p->sendError( $req, 'An error occurs, see IdP logs',
                500 );
        }

        # Add attribute statement in response assertion
        my @attributes_statement = ($attribute_statement);
        $assertion->AttributeStatement(@attributes_statement);

        # Set response assertion
        $query->response->Assertion( ($assertion) );
    }

    # Build response
    $att_response = $self->buildAttributeResponse($query);

    unless ($att_response) {
        $self->p->sendError( $req, "Unable to build attribute response", 500 );
    }

    return [
        200,
        [
            'Content-Type'   => 'application/xml',
            'Content-Length' => length($att_response)
        ],
        [$att_response]
    ];
}

# INTERNAL METHODS

sub imgok {
    my ( $self, $req, ) = @_;
    return $self->sendImage( $req, 'icons/ok.png' );
}

sub imgnok {
    my ( $self, $req, ) = @_;
    return $self->sendImage( $req, 'icons/warning.png' );
}

sub sendImage {
    my ( $self, $req,, $img ) = @_;
    return [
        302,
        [
                'Location' => $self->conf->{portal}
              . $self->p->staticPrefix
              . '/common/'
              . $img,
        ],
        [],
    ];
}

# Normalize url to be tolerant to SAML Path
# Usefull if SAML Path is a regex
# @return normalized url
sub normalize_url {
    my ( $self, $url, $samlPath, $metadataUrl ) = @_;

    my $initialPath = "";
    my $finalPath   = "";

    # Get current (bad) path
    if ( $url =~ m/($samlPath)/ ) {
        $initialPath = $1;
    }

    # Get destination (good) path
    if ( $metadataUrl =~ m/($samlPath)/ ) {
        $finalPath = $1;
    }

    if (    $initialPath ne ""
        and $finalPath ne ""
        and $initialPath ne $finalPath )
    {
        $self->logger->debug(
            "Normalizing url path form $initialPath to $finalPath");
        $url =~ s/$initialPath/$finalPath/;
    }

    return $url;
}

1;
