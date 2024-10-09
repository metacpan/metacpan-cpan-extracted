package Lemonldap::NG::Portal::Auth::SAML;

use strict;
use MIME::Base64 qw/encode_base64/;
use Mouse;
use HTML::Entities qw(encode_entities);
use Lemonldap::NG::Portal::Lib::SAML;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_CONFIRM
  PE_IDPCHOICE
  PE_LOGOUT_OK
  PE_REDIRECT
  PE_SAML_ART_ERROR
  PE_SAML_CONDITIONS_ERROR
  PE_SAML_DESTINATION_ERROR
  PE_SAML_ERROR
  PE_SAML_IDPSSOINITIATED_NOTALLOWED
  PE_SAML_SESSION_ERROR
  PE_SAML_SIGNATURE_ERROR
  PE_SLO_ERROR
  PE_SAML_SSO_ERROR
  PE_SAML_UNKNOWN_ENTITY
  PE_SENDRESPONSE
);

our $VERSION = '2.19.0';

extends qw(
  Lemonldap::NG::Portal::Main::Auth
  Lemonldap::NG::Portal::Lib::SAML
);

# INTERFACE

has ssoAssConsumerRe => ( is => 'rw' );
has sloRe            => ( is => 'rw' );
has artRe            => ( is => 'rw' );
has catch            => ( is => 'rw' );
use constant sessionKind => 'SAML';
use constant lsDump      => '_lassoSessionDump';
use constant liDump      => '_lassoIdentityDump';
use constant niDump      => '_lassoNameIdDump';
use constant sIndex      => '_lassoSessionIndex';
use constant afterData   => 'authFinish';

sub forAuthUser { 'handleAuthRequests' }

# INITIALIZATION

sub init {
    my ($self) = @_;

    my $saml_acs_art_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact");
    my $saml_acs_post_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPPost");
    my $saml_acs_get_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPRedirect");
    $self->ssoAssConsumerRe(
        qr/^($saml_acs_art_url|$saml_acs_post_url|$saml_acs_get_url)(?:\?.*)?$/i
    );
    my $saml_slo_soap_url =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_soap_url_ret =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_get_url = $self->getMetaDataURL(
        "samlSPSSODescriptorSingleLogoutServiceHTTPRedirect", 1 );
    my $saml_slo_get_url_ret = $self->getMetaDataURL(
        "samlSPSSODescriptorSingleLogoutServiceHTTPRedirect", 2 );
    my $saml_slo_post_url =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceHTTPPost",
        1 );
    my $saml_slo_post_url_ret =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceHTTPPost",
        2 );
    $self->sloRe(
qr/^($saml_slo_soap_url|$saml_slo_soap_url_ret|$saml_slo_get_url|$saml_slo_get_url_ret|$saml_slo_post_url|$saml_slo_post_url_ret)(?:\?.*)?$/i
    );

    my $saml_ars_url = $self->getMetaDataURL(
        "samlSPSSODescriptorArtifactResolutionServiceArtifact");
    $self->artRe(qr/^($saml_ars_url)(?:\?.*)?$/i);
    $self->catch(
qr/^($saml_acs_art_url|$saml_acs_post_url|$saml_acs_get_url$saml_slo_soap_url|$saml_slo_soap_url_ret|$saml_slo_get_url|$saml_slo_get_url_ret|$saml_slo_post_url|$saml_slo_post_url_ret)(?:\?.*)?$/i
    );

    # Load SAML service and SAML IdP list
    return ( $self->SUPER::init and $self->loadIDPs );
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;

    # 1. Get HTTP request information to know
    # if we are receving SAML request or response
    my $url            = $req->uri;
    my $request_method = $req->method;
    my $content_type   = $req->content_type;

    # 1.1 SSO assertion consumer
    if ( $url =~ $self->ssoAssConsumerRe ) {
        $self->logger->debug(
            "URL $url detected as an SSO assertion consumer URL");

        # Check SAML Message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $req, $url, $request_method, $content_type,
            "login" );

        # Create Login object
        my $login = $self->createLogin( $self->lassoServer );

        # Ignore signature verification
        $self->disableSignatureVerification($login);

        if ($response) {

            # Process authentication response
            my $result;
            if ($artifact) {
                $result = $self->processArtResponseMsg( $login, $response );
            }
            else {
                $result = $self->processAuthnResponseMsg( $login, $response );
            }

            unless ($result) {
                $self->logger->error(
                    "SAML SSO: Fail to process authentication response");
                return PE_SAML_SSO_ERROR;
            }

            $self->logger->debug("SSO: authentication response is valid");

            # Get IDP entityID
            my $idp = $login->remote_providerID();

            $self->logger->debug("Found entityID $idp in SAML message");

            # IDP conf key
            my $idpConfKey = $self->getIDPConfKey($idp);

            unless ($idpConfKey) {
                $self->userLogger->error(
                    "$idp do not match any IDP in configuration");
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->logger->debug("$idp match $idpConfKey IDP in configuration");

            # Do we check signature?
            my $checkSSOMessageSignature =
              $self->idpOptions->{$idp}
              ->{samlIDPMetaDataOptionsCheckSSOMessageSignature};

            if ($checkSSOMessageSignature) {

                $self->forceSignatureVerification($login);

                if ($artifact) {
                    $result = $self->processArtResponseMsg( $login, $response );
                }
                else {
                    $result =
                      $self->processAuthnResponseMsg( $login, $response );
                }

                unless ($result) {
                    $self->userLogger->error("Signature is not valid");
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->logger->debug("Signature is valid");
                }
            }
            else {
                $self->logger->debug("Message signature will not be checked");
            }

            # Get SAML response
            my $saml_response = $login->response();
            unless ($saml_response) {
                $self->userLogger->error("No SAML response found");
                return PE_SAML_SSO_ERROR;
            }

            # Call samlGotAuthnResponse
            my $h =
              $self->p->processHook( $req, 'samlGotAuthnResponse', $idp,
                $login );
            return PE_SAML_SSO_ERROR if ( $h != PE_OK );

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $saml_response, $url ) );

            # Replay protection if this is a response to a created authn request
            my $assertion_responded = $saml_response->InResponseTo;
            if ($assertion_responded) {
                unless ( $self->replayProtection($assertion_responded) ) {

                    # Assertion was already consumed or is expired
                    # Force authentication replay
                    $self->userLogger->error(
"Message $assertion_responded already used or expired, replay authentication"
                    );
                    delete $req->{urldc};
                    $req->mustRedirect(1);
                    $req->steps( [] );
                    $req->continue(1);
                    return PE_OK;
                }
            }
            else {
                $self->logger->debug(
"Assertion is not a response to a created authentication request, do not control replay"
                );
            }

            # Get SAML assertion
            my $assertion = $self->getAssertion($login);

            unless ($assertion) {
                $self->userLogger->error("No assertion found");
                return PE_SAML_SSO_ERROR;
            }

            # Do we check conditions?
            my $checkTime =
              $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsCheckTime};
            my $checkAudience =
              $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsCheckAudience};

            # Check conditions - time and audience
            unless (
                $self->validateConditions(
                    $assertion, $self->getMetaDataURL( "samlEntityID", 0, 1 ),
                    $checkTime, $checkAudience
                )
              )
            {
                $self->userLogger->error("Conditions not validated");
                return PE_SAML_CONDITIONS_ERROR;
            }

            my $relayStateURL =
              $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsRelayStateURL};

            #  Extract RelayState information
            if ( $self->extractRelayState( $req, $relaystate, $relayStateURL ) )
            {
                $self->logger->debug("RelayState $relaystate extracted");
            }

            # Check if we accept direct login from IDP
            my $allowLoginFromIDP =
              $self->idpOptions->{$idp}
              ->{samlIDPMetaDataOptionsAllowLoginFromIDP};
            if ( !$assertion_responded and !$allowLoginFromIDP ) {
                $self->userLogger->error(
                    "Direct login from IDP $idpConfKey is not allowed");
                return PE_SAML_IDPSSOINITIATED_NOTALLOWED;
            }

            # Check authentication context
            my $responseAuthnContext;
            eval {
                $responseAuthnContext =
                  $assertion->AuthnStatement()->AuthnContext()
                  ->AuthnContextClassRef();
            };
            if ($@) {
                $self->logger->debug(
                    "Unable to get authentication context from $idpConfKey");
                $responseAuthnContext = $self->getAuthnContext("unspecified");
            }
            else {
                $self->logger->debug(
                    "Found authentication context: $responseAuthnContext");
            }

            # Map authentication context to authentication level
            $req->sessionInfo->{authenticationLevel} =
              $self->authnContext2authnLevel($responseAuthnContext);

            # Force redirection to portal if no urldc found
            # (avoid displaying the whole SAML URL in user browser URL field)
            $req->mustRedirect(1) unless ( $req->urldc );

            # Get SessionIndex
            my $session_index;

            eval {
                $session_index = $assertion->AuthnStatement()->SessionIndex();
            };
            if ( $@ or !defined($session_index) ) {
                $self->logger->debug("No SessionIndex found");
            }
            else {
                $self->logger->debug("Found SessionIndex $session_index");
            }

            # Get NameID
            my $nameid = $login->nameIdentifier;
            unless ($nameid) {
                $self->userLogger->error("No NameID element found");
                return PE_SAML_SSO_ERROR;
            }

            my $nameid_content = $nameid->content;
            unless ($nameid_content) {
                $self->userLogger->error("No NameID value found");
                return PE_SAML_SSO_ERROR;
            }

            $self->logger->debug("Found NameID content $nameid_content");

            # Set user
            my $user = $nameid_content;
            my $userAttribute =
              $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsUserAttribute};

            if ($userAttribute) {
                $self->logger->debug(
                    "Try to set user value from SAML attribute $userAttribute");

                my $force_utf8 =
                  $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsForceUTF8};

                my $attr_statement = $assertion->AttributeStatement();
                if ($attr_statement) {

                    # Get attributes
                    my @attributes = $attr_statement->Attribute();
                    #
                    # Try to get value
                    my $value =
                      $self->getAttributeValue( $userAttribute, undef, undef,
                        \@attributes, $force_utf8 );

                    # Store value as user
                    if ( defined $value ) {
                        $user = $value;
                        $self->logger->debug(
                            "Found value $value for attribute $userAttribute");
                    }
                    else {
                        $self->logger->warn(
"No value for $userAttribute found in SAML assertion"
                        );
                    }
                }
                else {
                    $self->logger->warn(
                        "No attributes found in SAML assertion");
                }
            }

            $req->user($user);
            $self->logger->debug("Set user value to $user");

            # Store Lasso objects
            $req->data->{_lassoLogin}   = $login;
            $req->data->{_idp}          = $idp;
            $req->data->{_idpConfKey}   = $idpConfKey;
            $req->data->{_nameID}       = $nameid;
            $req->data->{_sessionIndex} = $session_index;

            # Store Token
            my $saml_token = $assertion->export_to_xml;

            $self->logger->debug("SAML Token: $saml_token");

            $req->data->{_samlToken} = $saml_token;

            # Restore initial SAML request in case of proxying
            if ($assertion_responded) {

                my $saml_sessions =
                  Lemonldap::NG::Common::Apache::Session->searchOn(
                    $self->amOpts, "ProxyID", $assertion_responded );

                if (
                    my @saml_sessions_keys = grep {
                        $saml_sessions->{$_}->{_session_kind} eq
                          $self->sessionKind
                    } keys %$saml_sessions
                  )
                {

                    # Warning if more than one session found
                    if ( $#saml_sessions_keys > 0 ) {
                        $self->logger->warn(
"More than one SAML proxy session found for ID $assertion_responded"
                        );
                    }

                    # Take the first session
                    my $saml_session = shift @saml_sessions_keys;

                    # Get session
                    $self->logger->debug(
"Retrieve SAML proxy session $saml_session for ID $assertion_responded"
                    );

                    my $samlSessionInfo = $self->getSamlSession($saml_session);

                    $req->data->{_proxiedRequest} =
                      $samlSessionInfo->data->{Request};
                    $req->data->{_proxiedMethod} =
                      $samlSessionInfo->data->{Method};
                    $req->data->{_proxiedRelayState} =
                      $samlSessionInfo->data->{RelayState};
                    $req->data->{_proxiedArtifact} =
                      $samlSessionInfo->data->{Artifact};

               # Save values in hidden fields in case of other user interactions
                    $self->p->setHiddenFormValue( $req, 'SAMLRequest',
                        $self->{_proxiedRequest} );
                    $self->p->setHiddenFormValue( $req, 'Method',
                        $self->{_proxiedMethod} );
                    $self->p->setHiddenFormValue( $req, 'RelayState',
                        $self->{_proxiedRelayState} );
                    $self->p->setHiddenFormValue( $req, 'SAMLart',
                        $self->{_proxiedArtifact} );

                    # Delete session
                    $samlSessionInfo->remove();
                }
            }

            return PE_OK;
        }
        elsif ($request) {

            # Do nothing
            $self->logger->debug(
                "This module do not manage SSO request, see IssuerDBSAML");

            return PE_OK;
        }
        else {

            # This should not happen
            $self->userLogger->error("SSO request or response was not found");

            return PE_SAML_ERROR;
        }

    }

    # 1.2 SLO
    elsif ( $url =~ $self->sloRe ) {
        $self->logger->debug("URL $url detected as an SLO URL");

        # TODO: call authLogout instead of duplicating SLO
        $req->steps( [ @{ $self->p->beforeLogout }, 'deleteSession' ] );

        # Don't fail on "beforeLogout" errors
        $req->data->{nofail} = 1;

        # Check SAML Message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $req, $url, $request_method, $content_type,
            "logout" );

        # Create Logout object
        my $logout = $self->createLogout( $self->lassoServer );

        # Ignore signature verification
        $self->disableSignatureVerification($logout);

        if ($response) {

            # Process logout response
            my $result = $self->processLogoutResponseMsg( $logout, $response );

            unless ($result) {
                $self->userLogger->error("Fail to process logout response");
                return PE_SLO_ERROR;
            }

            $self->logger->debug("Logout response is valid");

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $logout->response, $url ) );

            # Get IDP entityID
            my $idp = $logout->remote_providerID();

            $self->logger->debug("Found entityID $idp in SAML message");

            # IDP conf key
            my $idpConfKey = $self->getIDPConfKey($idp);

            unless ($idpConfKey) {
                $self->userLogger->error(
                    "$idp do not match any IDP in configuration");
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->logger->debug("$idp match $idpConfKey IDP in configuration");

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->idpOptions->{$idp}
              ->{samlIDPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {

                $self->forceSignatureVerification($logout);

                $result = $self->processLogoutResponseMsg( $logout, $response );

                unless ($result) {
                    $self->userLogger->error("Signature is not valid");
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->logger->debug("Signature is valid");
                }
            }
            else {
                $self->logger->debug("Message signature will not be checked");
            }

            # Replay protection
            my $samlID = $logout->response()->InResponseTo;

            unless ( $self->replayProtection($samlID) ) {

                # Logout request was already consumed or is expired
                $self->userLogger->error(
                    "Message $samlID already used or expired");
                return PE_SLO_ERROR;
            }

            # If URL in RelayState, different from portal, redirect user
            if ( $self->extractRelayState( $req, $relaystate ) ) {
                $self->logger->debug("RelayState $relaystate extracted");
                $self->logger->debug(
                    "URL " . $req->urldc . " found in RelayState" );
            }

            if (    $req->urldc
                and $req->portal !~ /$req->{urldc}\/?/ )
            {
                $req->steps( [] );
                $req->user('TODO');
                return PE_OK;
            }

            # Else, inform user that logout is OK
            $req->user('TODO');
            return PE_OK;
        }

        elsif ($request) {

            # Logout error
            my $logout_error = 0;

            # Lasso::Session dump
            my $session_dump;

            # Process logout request
            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                $self->userLogger->error("Fail to process logout request");
                return PE_SLO_ERROR;
            }

            $self->logger->debug("Logout request is valid");

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $logout->request, $url ) );

            # Get IDP entityID
            my $idp = $logout->remote_providerID();

            $self->logger->debug("Found entityID $idp in SAML message");

            # IDP conf key
            my $idpConfKey = $self->getIDPConfKey($idp);

            unless ($idpConfKey) {
                $self->userLogger->error(
                    "$idp do not match any IDP in configuration");
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->logger->debug("$idp match $idpConfKey IDP in configuration");

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->idpOptions->{$idp}
              ->{samlIDPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {
                unless ( $self->checkSignatureStatus($logout) ) {
                    $self->userLogger->error("Signature is not valid");
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->logger->debug("Signature is valid");
                }
            }
            else {
                $self->logger->debug("Message signature will not be checked");
            }

            # Get NameID and SessionIndex
            my $name_id       = $logout->request()->NameID;
            my $session_index = $logout->request()->SessionIndex;
            my $user          = $name_id->content;

            unless ($name_id) {
                $self->userLogger->error(
                    "Fail to get NameID from logout request");
                $logout_error = 1;
            }

            $self->logger->debug("Logout request NameID content: $user");

            # Get SAML sessions with the same NameID

            my $local_sessions =
              Lemonldap::NG::Common::Apache::Session->searchOn( $self->amOpts,
                "_nameID", $name_id->dump );

            if (
                my @local_sessions_keys = grep {
                    $local_sessions->{$_}->{_session_kind} eq $self->sessionKind
                } keys %$local_sessions
              )
            {

                # At least one session was found
                foreach (@local_sessions_keys) {

                    my $local_session = $_;

                    # Get session
                    $self->logger->debug(
                        "Retrieve SAML session $local_session for user $user");

                    my $sessionInfo = $self->getSamlSession($local_session);

              # If session index is defined and not equal to SAML session index,
              # jump to next session
                    if ( defined $session_index
                        and $session_index ne
                        $sessionInfo->data->{_sessionIndex} )
                    {
                        $self->logger->debug(
"Session $local_session has not the good session index, skipping"
                        );
                        next;
                    }

                    # Delete session
                    else {

                        # Open real session
                        my $real_session = $sessionInfo->data->{_saml_id};

                        my $ssoSession =
                          $self->p->getApacheSession($real_session);

                        # Import SSO session in $req
                        $self->importRealSession( $req, $ssoSession );

                  # Get Lasso::Session dump
                  # This value is erased if a next session match the SLO request
                        if (   $ssoSession
                            && $ssoSession->data->{ $self->lsDump } )
                        {
                            $self->logger->debug(
"Get Lasso::Session dump from session $real_session"
                            );
                            $session_dump =
                              $ssoSession->data->{ $self->lsDump };
                        }

                # Real session will be deleted after (see $req->steps... before)

                        # Delete SAML session
                        my $del_saml_result = $sessionInfo->remove();

                        $self->logger->debug(
"Delete SAML session $local_session result: $del_saml_result"
                        );

                        $logout_error = 1 unless $del_saml_result;
                    }
                }

                # Set session from dump
                unless ( $self->setSessionFromDump( $logout, $session_dump ) ) {
                    $self->userLogger->error(
                        "Cannot set session from dump in logout");
                    $logout_error = 1;
                }

            }
            else {

                # No corresponding session found
                $self->logger->debug("No SAML session found for user $user");

                $logout_error = 1;

            }

            # Validate request if no previous error
            unless ($logout_error) {
                unless ( $self->validateLogoutRequest($logout) ) {
                    $self->userLogger->error("SLO request is not valid");
                }
            }

            # Set RelayState
            if ($relaystate) {
                $logout->msg_relayState($relaystate);
                $self->logger->debug("Set $relaystate in RelayState");
            }

            # Do we set signature?
            my $signSLOMessage =
              $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsSignSLOMessage};

            if ( $signSLOMessage == 0 ) {
                $self->logger->debug(
                    "SLO message to IDP $idpConfKey will not be signed");
                $self->disableSignature($logout);
            }
            elsif ( $signSLOMessage == 1 ) {
                $self->logger->debug(
                    "SLO message to IDP $idpConfKey will be signed");
                $self->forceSignature($logout);
            }
            else {
                $self->logger->debug(
"SLO message to IDP $idpConfKey signature according to metadata"
                );
            }

            # Logout response
            unless ( $self->buildLogoutResponseMsg($logout) ) {
                $self->logger->error("Unable to build SLO response");
                return PE_SLO_ERROR;
            }

            # Send response depending on request method
            # HTTP-REDIRECT
            if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT ) {

                # Redirect user to response URL
                my $slo_url = $logout->msg_url;
                $self->logger->debug("Redirect user to $slo_url");

                $req->urldc($slo_url);

                return PE_OK;
            }

            # HTTP-POST
            elsif ( $method == Lasso::Constants::HTTP_METHOD_POST ) {

                # Use autosubmit form
                my $slo_url  = $logout->msg_url;
                my $slo_body = $logout->msg_body;

                $req->postUrl($slo_url);
                $req->postFields( { 'SAMLResponse' => $slo_body } );

                # RelayState
                if ($relaystate) {
                    $req->{postFields}->{'RelayState'} =
                      encode_entities($relaystate);
                    $req->data->{safeHiddenFormValues}->{RelayState} = 1;
                }

                # TODO: verify this
                push @{ $req->steps }, 'autoPost';
                return PE_OK;
            }

            # HTTP-SOAP
            elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {

                my $slo_body = $logout->msg_body;

                $self->logger->debug("SOAP response $slo_body");

                $req->response( [
                        200,
                        [
                            'Content-Type'   => 'text/xml',
                            'Content-Length' => length($slo_body)
                        ],
                        [$slo_body]
                    ]
                );
                $req->steps( [
                        @{ $self->p->beforeLogout },
                        sub {
                            my ($req) = @_;
                            my $res = $self->p->deleteSession($req);
                            return (
                                $res eq PE_LOGOUT_OK ? PE_SENDRESPONSE : $res );
                        }
                    ]
                );

                $req->user('SOAP client');
                return PE_OK;
            }

        }
        else {

            # This should not happen
            $self->userLogger->error("SLO request or response was not found");

            # Redirect user
            $req->mustRedirect(1);
            $req->steps( [] );
            return PE_REDIRECT;
        }
    }

    # 1.3 Artifact
    elsif ( $url =~ $self->artRe ) {

        $self->logger->debug(
            "URL $url detected as an artifact resolution service URL");

        # Artifact request are sent with SOAP trough POST
        my $art_request = $req->content;
        my $art_response;

        # Create Login object
        my $login = $self->createLogin( $self->lassoServer );

        # Process request message
        unless ( $self->processArtRequestMsg( $login, $art_request ) ) {
            $self->userLogger->error(
                "Unable to process artifact request message");
            return PE_SAML_ART_ERROR;
        }

        # Check Destination
        return PE_SAML_DESTINATION_ERROR
          unless ( $self->checkDestination( $login->request, $url ) );

        # Create artifact response
        unless ( $art_response = $self->createArtifactResponse( $req, $login ) )
        {
            $self->logger("Unable to create artifact response message");
            return PE_SAML_ART_ERROR;
        }

        $req->response( [
                200,
                [
                    'Content-Type'   => 'text/xml',
                    'Content-Length' => length($art_response)
                ],
                [$art_response]
            ]
        );
        $req->user('SOAP client');
        return PE_SENDRESPONSE;
    }

    # 2. IDP resolution

    # Search a selected IdP
    my $idp = $self->getIDP($req);

    # Use Common Domain Cookie
    if (   !$idp
        and $self->conf->{samlCommonDomainCookieActivation}
        and $self->conf->{samlCommonDomainCookieReader} )
    {
        $self->logger->debug(
            "Will try to use Common Domain Cookie for IDP resolution");

        # Add current URL to CDC Reader URL
        my $return_url = encode_base64( $self->p->fullUrl($req), '' );

        my $cdc_reader_url = $self->conf->{samlCommonDomainCookieReader};

        $cdc_reader_url .= ( $cdc_reader_url =~ /\?/ ? '&' : '?' )
          . build_urlencoded( url => $return_url );

        $self->logger->debug("Redirect user to $cdc_reader_url");

        $req->urldc($cdc_reader_url);

        $req->steps( [] );
        return PE_REDIRECT;
    }

    # Use SAML Discovery Protocol
    if (   !$idp
        and $self->conf->{samlDiscoveryProtocolActivation}
        and defined $self->conf->{samlDiscoveryProtocolURL} )
    {
        $self->logger->debug(
            "Will try to use SAML Discovery Protocol for IDP resolution");

        if ( $req->urldc ) {
            $req->pdata->{_url} = encode_base64( $req->urldc, '' );
        }
        my $disco_url = $self->conf->{samlDiscoveryProtocolURL};
        my $portal    = $req->portal;
        $disco_url .= ( $disco_url =~ /\?/ ? '&' : '?' )
          . build_urlencoded(
            entityID      => $self->getMetaDataURL( 'samlEntityID', 0, 1 ),
            return        => $portal,
            returnIDParam => 'idp'
          );

        if ( defined $self->conf->{samlDiscoveryProtocolPolicy} ) {
            my $dppolicy = $self->conf->{samlDiscoveryProtocolPolicy};
            $disco_url .= "&" . build_urlencoded( policy => $dppolicy );
        }

        if ( defined $self->conf->{samlDiscoveryProtocolIsPassive} ) {
            my $dpispassive = $self->conf->{samlDiscoveryProtocolIsPassive};
            $disco_url .= "&"
              . build_urlencoded(
                isPassive => $dpispassive
                ? "true"
                : "false"
              );
        }

        $self->logger->debug("Redirect user to $disco_url");

        $req->urldc($disco_url);

        $req->steps( [] );
        return PE_REDIRECT;
    }

    # If IDP was not resolved, let the user choose its IDP
    unless ($idp) {
        $self->logger->debug("Redirecting user to IDP list");

        # Control url parameter
        my $urlcheck = $self->p->controlUrl($req);
        return $urlcheck unless ( $urlcheck == PE_OK );

        # IDP list
        my @list       = ();

        foreach ( keys %{ $self->idpList } ) {
            my $idpName = $self->{idpList}->{$_}->{name};
            $idpName = $self->{idpList}->{$_}->{displayName}
              if $self->{idpList}->{$_}->{displayName};
            my $icon    = $self->{idpList}->{$_}->{icon};
            my $order   = $self->{idpList}->{$_}->{order} // 0;
            my $tooltip = $self->{idpList}->{$_}->{tooltip} || $idpName;
            my $img_src = '';

            if ($icon) {
                $img_src =
                  ( $icon =~ m#^https?://# )
                  ? $icon
                  : $self->p->staticPrefix . "/common/" . $icon;
            }
            $self->logger->debug( "IDP "
                  . $self->{idpList}->{$_}->{name}
                  . " -> DisplayName : $idpName with Icon : $img_src at order : $order"
            );
            push @list,
              {
                val   => $_,
                name  => $idpName,
                title => $tooltip,
                icon  => $img_src,
                order => $order
              };
        }
        @list =
          sort {
                 $a->{order} <=> $b->{order}
              or $a->{name} cmp $b->{name}
              or $a->{val} cmp $b->{val}
          } @list;
        $req->data->{list} = \@list;

        #TODO: check this
        $req->data->{login} = 1;
        return PE_IDPCHOICE;
    }

    # 3. Build authentication request

    # IDP conf key
    my $idpConfKey = $self->getIDPConfKey($idp);

    unless ($idpConfKey) {
        $self->userLogger->error("$idp do not match any IDP in configuration");
        return PE_SAML_UNKNOWN_ENTITY;
    }

    $self->logger->debug("$idp match $idpConfKey IDP in configuration");

    # IDP ForceAuthn
    my $forceAuthn =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsForceAuthn};

    # IDP IsPassive
    my $isPassive =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsIsPassive};

    # IDP NameIDFormat
    my $nameIDFormat =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsNameIDFormat};
    $nameIDFormat = $self->getNameIDFormat($nameIDFormat) if $nameIDFormat;

    # IDP HTTP method
    my $method = $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsSSOBinding};
    $method = $self->getHttpMethod($method);

    # If no method defined, get first HTTP method
    unless ( defined $method ) {
        my $protocolType = Lasso::Constants::MD_PROTOCOL_TYPE_SINGLE_SIGN_ON;
        $method =
          $self->getFirstHttpMethod( $self->lassoServer, $idp, $protocolType );
    }

    # Failback to HTTP-REDIRECT
    unless ( defined $method and $method != -1 ) {
        $self->logger->debug(
            "No method found with IDP $idpConfKey for SSO profile");
        $method = $self->getHttpMethod("redirect");
    }

    $self->logger->debug( "Use method "
          . $self->getHttpMethodString($method)
          . " with IDP $idpConfKey for SSO profile" );

    # Set signature
    my $signSSOMessage =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsSignSSOMessage} // -1;

    # Authentication Context
    my $requestedAuthnContext =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsRequestedAuthnContext}
      // '';
    $requestedAuthnContext = $self->getAuthnContext($requestedAuthnContext)
      if $requestedAuthnContext;

    # Create SSO request
    my $login = $self->createAuthnRequest(
        $req,          $self->lassoServer, $idp,
        $method,       $forceAuthn,        $isPassive,
        $nameIDFormat, 0,                  $signSSOMessage,
        $requestedAuthnContext
    );

    unless ($login) {
        $self->userLogger->error(
            "Could not create authentication request on $idpConfKey");
        return PE_SAML_SSO_ERROR;
    }

    $self->logger->debug("Authentication request created");

    # Keep assertion ID in memory to prevent replay
    my $samlID = $login->request()->ID;
    unless ( $self->storeReplayProtection($samlID) ) {
        $self->logger->error("Unable to store assertion ID");
        return PE_SAML_SSO_ERROR;
    }

    # Keep initial SAML request data in memory in case of proxing
    if ( $req->data->{_proxiedSamlRequest} ) {

        my $infos;

        $infos->{type}       = 'proxy';
        $infos->{_utime}     = time;
        $infos->{Request}    = $req->data->{_proxiedRequest};
        $infos->{Method}     = $req->data->{_proxiedMethod};
        $infos->{RelayState} = $req->data->{_proxiedRelayState};
        $infos->{Artifact}   = $req->data->{_proxiedArtifact};
        $infos->{ProxyID}    = $samlID;

        my $samlSessionInfo = $self->getSamlSession( undef, $infos );

        return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

        $self->logger->debug(
            "Keep initial SAML request data in memory for ID $samlID");
    }

    # Send SSO request depending on request method
    # HTTP-REDIRECT
    if (   $method == $self->getHttpMethod('redirect')
        or $method == $self->getHttpMethod('artifact-get') )
    {

        # Redirect user to response URL
        my $sso_url = $login->msg_url;
        $self->logger->debug("Redirect user to $sso_url");

        $req->urldc($sso_url);

        return PE_REDIRECT;
    }

    # HTTP-POST
    elsif ($method == $self->getHttpMethod('post')
        or $method == $self->getHttpMethod('artifact-post') )
    {

        # Use autosubmit form
        my $sso_url  = $login->msg_url;
        my $sso_body = $login->msg_body;

        $req->postUrl($sso_url);

        if ( $method == $self->getHttpMethod("artifact-post") ) {
            $req->{postFields} = { 'SAMLart' => $sso_body };
        }
        else {
            $req->{postFields} = { 'SAMLRequest' => $sso_body };
        }

        # RelayState
        if ( $login->msg_relayState ) {
            $req->{postFields}->{'RelayState'} =
              encode_entities( $login->msg_relayState );
            $req->data->{safeHiddenFormValues}->{RelayState} = 1;
        }

        # TODO: verify this
        $req->steps( ['autoPost'] );
        $req->continue(1);
        return PE_OK;
    }

    # No SOAP transport for SSO request
    return PE_SAML_SSO_ERROR;
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    my $login          = $req->data->{_lassoLogin};
    my $idp            = $req->data->{_idp};
    my $idpConfKey     = $req->data->{_idpConfKey};
    my $nameIdentifier = $req->data->{_nameID};
    my $session_index  = $req->data->{_sessionIndex};

    # Get SAML assertion
    my $assertion = $self->getAssertion($login);

    unless ($assertion) {
        $self->userLogger->error("No assertion found");
        return PE_SAML_SSO_ERROR;
    }

    # Force UTF-8
    my $force_utf8 =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsForceUTF8};

    # Try to get attributes if attribute statement is present in assertion
    my $attr_statement = $assertion->AttributeStatement();
    if ($attr_statement) {

        # Get attributes
        my @attributes = $attr_statement->Attribute();

        # Wanted attributes are defined in IDP configuration
        foreach ( keys %{ $self->idpAttributes->{$idp} } ) {

            # Extract fields from exportedAttr value
            my ( $mandatory, $name, $format, $friendly_name ) =
              split( /;/, $self->idpAttributes->{$idp}->{$_} );

            # Try to get value
            my $value =
              $self->getAttributeValue( $name, $format, $friendly_name,
                \@attributes, $force_utf8 );

            # Store value in sessionInfo
            $req->{sessionInfo}->{$_} = $value if defined $value;
        }
    }

    # Store other information in session
    $req->{sessionInfo}->{_idp}        = $idp;
    $req->{sessionInfo}->{_idpConfKey} = $idpConfKey;

    # Adapt _utime with SessionNotOnOrAfter
    my $sessionNotOnOrAfter;
    eval {
        $sessionNotOnOrAfter =
          $assertion->AuthnStatement()->SessionNotOnOrAfter();
    };

    if ( $@ or !$sessionNotOnOrAfter ) {
        $self->logger->debug("No SessionNotOnOrAfter value found");
    }
    else {

        my $samltime = $self->samldate2timestamp($sessionNotOnOrAfter);
        my $utime    = time();
        my $timeout  = $self->conf->{timeout};
        my $adaptSessionUtime =
          $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsAdaptSessionUtime};

        if ( ( $utime + $timeout > $samltime ) and $adaptSessionUtime ) {

            # Use SAML time to determine the start of the session
            my $new_utime = $samltime - $timeout;
            $req->{sessionInfo}->{_utime} = $new_utime;
            $self->logger->debug(
"Adapt _utime with SessionNotOnOrAfter value, new _utime: $new_utime"
            );
        }

    }

    # Establish federation (required for attribute request in UserDBSAML)
    unless ( $self->acceptSSO($login) ) {
        $self->userLogger->error(
            "Error while accepting SSO from IDP $idpConfKey");
        return PE_SAML_SSO_ERROR;
    }

    # Get created Lasso::Session and Lasso::Identity
    my $session  = $login->get_session;
    my $identity = $login->get_identity;

    # Dump Lasso objects in session
    $req->{sessionInfo}->{ $self->lsDump } = $session->dump()  if $session;
    $req->{sessionInfo}->{ $self->liDump } = $identity->dump() if $identity;
    $req->{sessionInfo}->{ $self->niDump } = $nameIdentifier->dump()
      if ref($nameIdentifier);
    $req->{sessionInfo}->{ $self->sIndex } = $session_index if $session_index;

    # Keep SAML Token in session
    my $store_samlToken =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsStoreSAMLToken};
    if ($store_samlToken) {
        $self->logger->debug("Store SAML Token in session");
        $req->{sessionInfo}->{_samlToken} = $req->data->{_samlToken};
    }
    else {
        $self->logger->debug("SAML Token will not be stored in session");
    }

    $req->data->{_lassoLogin} = $login;

    return PE_OK;
}

# Saves the link between IDP-side Session ID/NameID and LLNG session
sub authFinish {
    my ( $self, $req ) = @_;

    # Get saved Lasso objects
    my $nameid        = $req->sessionInfo->{ $self->niDump };
    my $session_index = $req->sessionInfo->{ $self->sIndex };

    # Auth::SAML was not used for this session
    return unless ($nameid);

    # Real session was stored, get id and utime
    my $id    = $req->{id};
    my $utime = $req->{sessionInfo}->{_utime};

    $self->logger->debug( "Store NameID "
          . $nameid
          . ( $session_index ? " and SessionIndex $session_index" : "" )
          . " for session $id" );

    my $infos;
    $infos->{type}          = 'saml';            # Session type
    $infos->{_utime}        = $utime;            # Creation time
    $infos->{_saml_id}      = $id;               # SSO session id
    $infos->{_nameID}       = $nameid;           # SAML NameID
    $infos->{_sessionIndex} = $session_index;    # SAML SessionIndex

    # Save SAML session
    my $samlSessionInfo = $self->getSamlSession( undef, $infos );

    return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

    my $session_id = $samlSessionInfo->id;

    $self->logger->debug("Link session $id to SAML session $session_id");

    return PE_OK;
}

sub authLogout {
    my ( $self, $req ) = @_;
    my $idp        = $req->sessionInfo->{_idp};
    my $idpConfKey = $req->sessionInfo->{_idpConfKey};
    my $session_id = $req->sessionInfo->{_session_id};
    my $method;

    # Real session was previously deleted,
    # remove corresponding SAML sessions
    $self->deleteSAMLSecondarySessions($session_id);

    # Recover Lasso::Session dump
    my $session_dump = $req->{sessionInfo}->{ $self->lsDump };

    unless ($session_dump) {
        $self->userLogger->error("Could not get session dump from session");
        return PE_SLO_ERROR;
    }

    # IDP HTTP method
    $method = $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsSLOBinding};
    $method = $self->getHttpMethod($method);

    # If no method defined, get first HTTP method
    unless ( defined $method ) {
        my $protocolType = Lasso::Constants::MD_PROTOCOL_TYPE_SINGLE_LOGOUT;
        $method =
          $self->getFirstHttpMethod( $self->lassoServer, $idp, $protocolType );
    }

    # Skip SLO if no method found
    unless ( defined $method and $method != -1 ) {
        $self->logger->debug(
            "No method found with IDP $idpConfKey for SLO profile");
        return PE_OK;
    }

    $self->logger->debug( "Use method "
          . $self->getHttpMethodString($method)
          . " with IDP $idpConfKey for SLO profile" );

    # Set signature
    my $signSLOMessage =
      $self->idpOptions->{$idp}->{samlIDPMetaDataOptionsSignSLOMessage} // 0;

    # Build Logout Request
    my $logout =
      $self->createLogoutRequest( $req, $self->lassoServer, $session_dump,
        $method, $signSLOMessage );
    unless ($logout) {
        $self->logger->error("Could not create logout request");
        return PE_SLO_ERROR;
    }

    $self->logger->debug("Logout request created");

    # Keep request ID in memory to prevent replay
    unless ( $self->storeReplayProtection( $logout->request()->ID ) ) {
        $self->logger->error("Unable to store Logout request ID");
        return PE_SLO_ERROR;
    }

    # Send request depending on request method
    # HTTP-REDIRECT
    if (   $method == Lasso::Constants::HTTP_METHOD_REDIRECT
        or $method == Lasso::Constants::HTTP_METHOD_ARTIFACT_GET )
    {

        # Redirect user to response URL
        my $slo_url = $logout->msg_url;
        $self->logger->debug("Redirect user to $slo_url");

        $req->urldc($slo_url);

        # Redirect done in Portal
        return PE_OK;
    }

    # HTTP-POST
    elsif ($method == Lasso::Constants::HTTP_METHOD_POST
        or $method == Lasso::Constants::HTTP_METHOD_ARTIFACT_POST )
    {

        # Use autosubmit form
        my $slo_url  = $logout->msg_url;
        my $slo_body = $logout->msg_body;
        $self->logger->debug("Redirect user to $slo_url using autoPost");

        $req->postUrl($slo_url);
        $req->postFields( { 'SAMLRequest' => $slo_body } );

        # RelayState
        if ( $logout->msg_relayState ) {
            $req->{postFields}->{'RelayState'} =
              encode_entities( $logout->msg_relayState );
            $req->data->{safeHiddenFormValues}->{RelayState} = 1;
        }

        # Post done in Portal
        $req->steps( [ 'deleteSession', 'autoPost' ] );
        return PE_OK;
    }

    # HTTP-SOAP
    elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {

        my $slo_url  = $logout->msg_url;
        my $slo_body = $logout->msg_body;

        # Send SOAP request and manage response
        my $response = $self->sendSOAPMessage( $slo_url, $slo_body );

        unless ($response) {
            $self->logger->error("No logout response to SOAP request");
            return PE_SLO_ERROR;
        }

        # Create Logout object
        $logout = $self->createLogout( $self->lassoServer );

        # Do we check signature?
        my $checkSLOMessageSignature =
          $self->idpOptions->{$idp}
          ->{samlIDPMetaDataOptionsCheckSLOMessageSignature};

        unless ($checkSLOMessageSignature) {
            $self->disableSignatureVerification($logout);
        }

        # Process logout response
        my $result = $self->processLogoutResponseMsg( $logout, $response );

        unless ($result) {
            $self->logger->error("Fail to process logout response");
            return PE_SLO_ERROR;
        }

        $self->logger->debug("Logout response is valid");

        # Replay protection
        my $samlID = $logout->response()->InResponseTo;

        unless ( $self->replayProtection($samlID) ) {

            # Logout request was already consumed or is expired
            $self->userLogger->error("Message $samlID already used or expired");
            return PE_SLO_ERROR;
        }

        return PE_OK;
    }
    else {
        $self->userLogger->error("Lasso method $method not implemented here");
        return PE_SLO_ERROR;
    }
}

sub handleAuthRequests {
    my ( $self, $req ) = @_;
    if ( $req->uri =~ $self->sloRe ) {
        return $self->extractFormInfo($req);
    }
    return PE_OK;
}

# TODO: authForce

sub getDisplayType {
    return "logo";
}

# Internal methods

sub getIDPConfKey {
    my ( $self, $entityID ) = @_;

    # Make sure we don't modify the hash by reading it
    if ( $self->idpList->{$entityID} ) {
        return $self->idpList->{$entityID}->{confKey};
    }
    return undef;
}

sub getEntityID {
    my ( $self, $confKey ) = @_;

    foreach ( keys %{ $self->idpList } ) {
        my $idpConfKey = $self->idpList->{$_}->{confKey} // "";
        if ( $confKey eq $idpConfKey ) {
            return $_;
        }
    }
    return undef;
}

# Try to find an IdP using :
# * HTTP parameter
# * Rules
#
# @return Array containing :
# * IdP found (or undef)
# * Cookie value if exists
sub getIDP {
    my ( $self, $req ) = @_;
    my $idp;
    my $idpName;

    # Case 1: Recover IDP from idp URL Parameter
    unless ( $idp = $req->param("idp") ) {

        # Case 2: Recover IDP from idpName URL Parameter
        if ( $idpName = $req->param("idpName") ) {
            $idp = $self->getEntityID($idpName);
            $self->logger->debug(
                "IDP $idp selected from idpName URL Parameter ($idpName)")
              if $idp;
        }

        # Case 3: check all IDP resolution rules
        # The first match win
        else {
            foreach ( keys %{ $self->idpList } ) {
                my $idpConfKey = $self->idpList->{$_}->{confKey};
                my $cond       = $self->idpRules->{$_} or next;
                if ( $cond->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug(
                        "IDP $idpConfKey selected from resolution rule");
                    $idp = $_;
                    last;
                }
            }
        }
        $self->logger->debug('No IDP selected') unless ($idp);
    }
    else {
        $self->logger->debug("IDP $idp selected from idp URL Parameter");
    }

    # Lazy load IDP
    $self->lazy_load_entityid($idp) if $idp;

    # Case 6: auto select IDP if only one IDP defined and WAYF is disabled
    if (
        scalar keys %{ $self->idpList } == 1
        and not( $self->conf->{samlDiscoveryProtocolActivation}
            and defined $self->conf->{samlDiscoveryProtocolURL} )
      )
    {
        ($idp) = keys %{ $self->idpList };
        $self->logger->debug("Selecting the only defined SAML IDP: $idp");
    }

    # Alert when selected IDP is unknown
    if ( $idp and !exists $self->idpList->{$idp} ) {
        $self->logger->error("Required IDP $idp does not exists");
        $idp = undef;
    }

    return $idp;
}

1;
