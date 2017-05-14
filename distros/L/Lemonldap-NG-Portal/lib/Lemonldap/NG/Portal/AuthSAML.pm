## @file
# SAML Service Provider - Authentication

## @class
# SAML Service Provider - Authentication
package Lemonldap::NG::Portal::AuthSAML;

use strict;
use MIME::Base64;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_SAML;    #inherits
use Lemonldap::NG::Common::Conf::SAML::Metadata;

our $VERSION = '1.9.8';
our @ISA     = qw(Lemonldap::NG::Portal::_SAML);

## @apmethod int authInit()
# Load Lasso and metadata
# @return Lemonldap::NG::Portal error code
sub authInit {
    my $self = shift;

    # Load SAML service
    return PE_SAML_LOAD_SERVICE_ERROR unless $self->loadService();

    # Load SAML identity providers
    return PE_SAML_LOAD_IDP_ERROR unless $self->loadIDPs();

    PE_OK;
}

## @apmethod int extractFormInfo()
# Check authentication statement or create authentication request
# @return Lemonldap::NG::Portal error code
sub extractFormInfo {
    my $self   = shift;
    my $server = $self->{_lassoServer};

    # 1. Get HTTP request informations to know
    # if we are receving SAML request or response
    my $url            = $self->url( -absolute => 1 );
    my $request_method = $self->request_method();
    my $content_type   = $self->content_type();

    my $saml_acs_art_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact");
    my $saml_acs_post_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPPost");
    my $saml_acs_get_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPRedirect");
    my $saml_slo_soap_url =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_soap_url_ret =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 2 );
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
    my $saml_ars_url = $self->getMetaDataURL(
        "samlSPSSODescriptorArtifactResolutionServiceArtifact");

    # 1.1 SSO assertion consumer
    if ( $url =~
/^(\Q$saml_acs_art_url\E|\Q$saml_acs_post_url\E|\Q$saml_acs_get_url\E)$/io
      )
    {
        $self->lmLog( "URL $url detected as an SSO assertion consumer URL",
            'debug' );

        # Check SAML Message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $url, $request_method, $content_type, "login" );

        # Create Login object
        my $login = $self->createLogin($server);

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
                $self->lmLog( "SSO: Fail to process authentication response",
                    'error' );
                return PE_SAML_SSO_ERROR;
            }

            $self->lmLog( "SSO: authentication response is valid", 'debug' );

            # Get IDP entityID
            my $idp = $login->remote_providerID();

            $self->lmLog( "Found entityID $idp in SAML message", 'debug' );

            # IDP conf key
            my $idpConfKey = $self->{_idpList}->{$idp}->{confKey};

            unless ($idpConfKey) {
                $self->lmLog( "$idp do not match any IDP in configuration",
                    'error' );
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->lmLog( "$idp match $idpConfKey IDP in configuration",
                'debug' );

            # Do we check signature?
            my $checkSSOMessageSignature =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
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
                    $self->lmLog( "Signature is not valid", 'error' );
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Get SAML response
            my $saml_response = $login->response();
            unless ($saml_response) {
                $self->lmLog( "No SAML response found", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $saml_response, $url ) );

            # Replay protection if this is a response to a created authn request
            my $assertion_responded = $saml_response->InResponseTo;
            if ($assertion_responded) {
                unless ( $self->replayProtection($assertion_responded) ) {

                    # Assertion was already consumed or is expired
                    # Force authentication replay
                    $self->lmLog(
"Message $assertion_responded already used or expired, replay authentication",
                        'error'
                    );
                    delete $self->{urldc};
                    $self->{mustRedirect} = 1;
                    return $self->_subProcess(qw(autoRedirect));
                }
            }
            else {
                $self->lmLog(
"Assertion is not a response to a created authentication request, do not control replay",
                    'debug'
                );
            }

            # Get SAML assertion
            my $assertion = $self->getAssertion($login);

            unless ($assertion) {
                $self->lmLog( "No assertion found", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            # Do we check conditions?
            my $checkTime =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsCheckTime};
            my $checkAudience =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsCheckAudience};

            unless (
                $self->validateConditions(
                    $assertion, $self->getMetaDataURL( "samlEntityID", 0, 1 ),
                    $checkTime, $checkAudience
                )
              )
            {
                $self->lmLog( "Conditions not validated", 'error' );
                return PE_SAML_CONDITIONS_ERROR;
            }

            my $relayStateURL =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsRelayStateURL};

            #  Extract RelayState information
            if ( $self->extractRelayState( $relaystate, $relayStateURL ) ) {
                $self->lmLog( "RelayState $relaystate extracted", 'debug' );
            }

            # Check if we accept direct login from IDP
            my $allowLoginFromIDP =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsAllowLoginFromIDP};
            if ( !$assertion_responded and !$allowLoginFromIDP ) {
                $self->lmLog(
                    "Direct login from IDP $idpConfKey is not allowed",
                    'error' );
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
                $self->lmLog(
                    "Unable to get authentication context from $idpConfKey",
                    'debug' );
                $responseAuthnContext = $self->getAuthnContext("unspecified");
            }
            else {
                $self->lmLog(
                    "Found authentication context: $responseAuthnContext",
                    'debug' );
            }

            # Map authentication context to authentication level
            $self->{sessionInfo}->{authenticationLevel} =
              $self->authnContext2authnLevel($responseAuthnContext);

            # Force redirection to portal if no urldc found
            # (avoid displaying the whole SAML URL in user browser URL field)
            $self->{mustRedirect} = 1 unless ( $self->{urldc} );

            # Get SessionIndex
            my $session_index;

            eval {
                $session_index = $assertion->AuthnStatement()->SessionIndex();
            };
            if ( $@ or !defined($session_index) ) {
                $self->lmLog( "No SessionIndex found", 'debug' );
            }
            else {
                $self->lmLog( "Found SessionIndex $session_index", 'debug' );
            }

            # Get NameID
            my $nameid = $login->nameIdentifier;

            # Set user
            my $user = $nameid->content;

            unless ($user) {
                $self->lmLog( "No NameID value found", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            $self->lmLog( "Found NameID: $user", 'debug' );
            $self->{user} = $user;

            # Store Lasso objects
            $self->{_lassoLogin}   = $login;
            $self->{_idp}          = $idp;
            $self->{_idpConfKey}   = $idpConfKey;
            $self->{_nameID}       = $nameid;
            $self->{_sessionIndex} = $session_index;

            # Store Token
            my $saml_token = $assertion->export_to_xml;

            $self->lmLog( "SAML Token: $saml_token", 'debug' );

            $self->{_samlToken} = $saml_token;

            # Restore initial SAML request in case of proxying
            if ($assertion_responded) {
                my $moduleOptions = $self->{samlStorageOptions} || {};
                $moduleOptions->{backend} = $self->{samlStorage};
                my $module = "Lemonldap::NG::Common::Apache::Session";

                my $saml_sessions =
                  $module->searchOn( $moduleOptions, "ProxyID",
                    $assertion_responded );

                if ( my @saml_sessions_keys = keys %$saml_sessions ) {

                    # Warning if more than one session found
                    if ( $#saml_sessions_keys > 0 ) {
                        $self->lmLog(
"More than one SAML proxy session found for ID $assertion_responded",
                            'warn'
                        );
                    }

                    # Take the first session
                    my $saml_session = shift @saml_sessions_keys;

                    # Get session
                    $self->lmLog(
"Retrieve SAML proxy session $saml_session for ID $assertion_responded",
                        'debug'
                    );

                    my $samlSessionInfo = $self->getSamlSession($saml_session);

                    $self->{_proxiedRequest} =
                      $samlSessionInfo->data->{Request};
                    $self->{_proxiedMethod} = $samlSessionInfo->data->{Method};
                    $self->{_proxiedRelayState} =
                      $samlSessionInfo->data->{RelayState};
                    $self->{_proxiedArtifact} =
                      $samlSessionInfo->data->{Artifact};

               # Save values in hidden fields in case of other user interactions
                    $self->setHiddenFormValue( 'SAMLRequest',
                        $self->{_proxiedRequest} );
                    $self->setHiddenFormValue( 'Method',
                        $self->{_proxiedMethod} );
                    $self->setHiddenFormValue( 'RelayState',
                        $self->{_proxiedRelayState} );
                    $self->setHiddenFormValue( 'SAMLart',
                        $self->{_proxiedArtifact} );

                    # Delete session
                    $samlSessionInfo->remove();
                }
            }

            return PE_OK;
        }
        elsif ($request) {

            # Do nothing
            $self->lmLog(
                "This module do not manage SSO request, see IssuerDBSAML",
                'debug' );

            return PE_OK;
        }
        else {

            # This should not happen
            $self->lmLog( "SSO request or response was not found", 'error' );

            # Redirect user
            $self->{mustRedirect} = 1;
            return $self->_subProcess(qw(autoRedirect));
        }

    }

    # 1.2 SLO
    elsif ( $url =~
/^(\Q$saml_slo_soap_url\E|\Q$saml_slo_soap_url_ret\E|\Q$saml_slo_get_url\E|\Q$saml_slo_get_url_ret\E|Q$saml_slo_post_url\E|\Q$saml_slo_post_url_ret\E)$/io
      )
    {
        $self->lmLog( "URL $url detected as an SLO URL", 'debug' );

        # Check SAML Message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $url, $request_method, $content_type, "logout" );

        # Create Logout object
        my $logout = $self->createLogout($server);

        # Ignore signature verification
        $self->disableSignatureVerification($logout);

        if ($response) {

            # Process logout response
            my $result = $self->processLogoutResponseMsg( $logout, $response );

            unless ($result) {
                $self->lmLog( "Fail to process logout response", 'error' );
                return PE_SAML_SLO_ERROR;
            }

            $self->lmLog( "Logout response is valid", 'debug' );

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $logout->response, $url ) );

            # Get IDP entityID
            my $idp = $logout->remote_providerID();

            $self->lmLog( "Found entityID $idp in SAML message", 'debug' );

            # IDP conf key
            my $idpConfKey = $self->{_idpList}->{$idp}->{confKey};

            unless ($idpConfKey) {
                $self->lmLog( "$idp do not match any IDP in configuration",
                    'error' );
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->lmLog( "$idp match $idpConfKey IDP in configuration",
                'debug' );

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {

                $self->forceSignatureVerification($logout);

                $result = $self->processLogoutResponseMsg( $logout, $response );

                unless ($result) {
                    $self->lmLog( "Signature is not valid", 'error' );
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Replay protection
            my $samlID = $logout->response()->InResponseTo;

            unless ( $self->replayProtection($samlID) ) {

                # Logout request was already consumed or is expired
                $self->lmLog( "Message $samlID already used or expired",
                    'error' );
                return PE_SAML_SLO_ERROR;
            }

            # If URL in RelayState, different from portal, redirect user
            if ( $self->extractRelayState($relaystate) ) {
                $self->lmLog( "RelayState $relaystate extracted", 'debug' );
                $self->lmLog( "URL " . $self->{urldc} . " found in RelayState",
                    'debug' );
            }

            return $self->_subProcess(qw(autoRedirect))
              if (  $self->{urldc}
                and $self->{portal} !~ /\Q$self->{urldc}\E\/?/ );

            # Else, inform user that logout is OK
            return PE_LOGOUT_OK;
        }

        elsif ($request) {

            # Logout error
            my $logout_error = 0;

            # Lasso::Session dump
            my $session_dump;

            # Process logout request
            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                $self->lmLog( "Fail to process logout request", 'error' );
                $logout_error = 1;
            }

            $self->lmLog( "Logout request is valid", 'debug' );

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $logout->request, $url ) );

            # Get IDP entityID
            my $idp = $logout->remote_providerID();

            $self->lmLog( "Found entityID $idp in SAML message", 'debug' );

            # IDP conf key
            my $idpConfKey = $self->{_idpList}->{$idp}->{confKey};

            unless ($idpConfKey) {
                $self->lmLog( "$idp do not match any IDP in configuration",
                    'error' );
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->lmLog( "$idp match $idpConfKey IDP in configuration",
                'debug' );

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {
                unless ( $self->checkSignatureStatus($logout) ) {
                    $self->lmLog( "Signature is not valid", 'error' );
                    return PE_SAML_SIGNATURE_ERROR;
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Get NameID and SessionIndex
            my $name_id       = $logout->request()->NameID;
            my $session_index = $logout->request()->SessionIndex;
            my $user          = $name_id->content;

            unless ($name_id) {
                $self->lmLog( "Fail to get NameID from logout request",
                    'error' );
                $logout_error = 1;
            }

            $self->lmLog( "Logout request NameID content: $user", 'debug' );

            # Get SAML sessions with the same NameID
            my $moduleOptions = $self->{samlStorageOptions} || {};
            $moduleOptions->{backend} = $self->{samlStorage};
            my $module = "Lemonldap::NG::Common::Apache::Session";

            my $local_sessions =
              $module->searchOn( $moduleOptions, "_nameID", $name_id->dump );

            if ( my @local_sessions_keys = keys %$local_sessions ) {

                # At least one session was found
                foreach (@local_sessions_keys) {

                    my $local_session = $_;

                    # Get session
                    $self->lmLog(
                        "Retrieve SAML session $local_session for user $user",
                        'debug' );

                    my $sessionInfo = $self->getSamlSession($local_session);

              # If session index is defined and not equal to SAML session index,
              # jump to next session
                    if ( defined $session_index
                        and $session_index ne
                        $sessionInfo->data->{_sessionIndex} )
                    {
                        $self->lmLog(
"Session $local_session has not the good session index, skipping",
                            'debug'
                        );
                        next;
                    }

                    # Delete session
                    else {

                        # Open real session
                        my $real_session = $sessionInfo->data->{_saml_id};

                        my $ssoSession =
                          $self->getApacheSession( $real_session, 1 );

                  # Get Lasso::Session dump
                  # This value is erased if a next session match the SLO request
                        if (   $ssoSession
                            && $ssoSession->data->{_lassoSessionDump} )
                        {
                            $self->lmLog(
"Get Lasso::Session dump from session $real_session",
                                'debug'
                            );
                            $session_dump =
                              $ssoSession->data->{_lassoSessionDump};
                        }

                        # Delete real session
                        my $del_real_result =
                          $self->_deleteSession($ssoSession);

                        $self->lmLog(
"Delete real session $real_session result: $del_real_result",
                            'debug'
                        );

                        $logout_error = 1 unless $del_real_result;

                        # Delete SAML session
                        my $del_saml_result = $sessionInfo->remove();

                        $self->lmLog(
"Delete SAML session $local_session result: $del_saml_result",
                            'debug'
                        );

                        $logout_error = 1 unless $del_saml_result;
                    }
                }

                # Set session from dump
                unless ( $self->setSessionFromDump( $logout, $session_dump ) ) {
                    $self->lmLog( "Cannot set session from dump in logout",
                        'error' );
                    $logout_error = 1;
                }

            }
            else {

                # No corresponding session found
                $self->lmLog( "No SAML session found for user $user", 'debug' );

                $logout_error = 1;

            }

            # Validate request if no previous error
            unless ($logout_error) {
                unless ( $self->validateLogoutRequest($logout) ) {
                    $self->lmLog( "SLO request is not valid", 'error' );
                }
            }

            # Set RelayState
            if ($relaystate) {
                $logout->msg_relayState($relaystate);
                $self->lmLog( "Set $relaystate in RelayState", 'debug' );
            }

            # Do we set signature?
            my $signSLOMessage =
              $self->{samlIDPMetaDataOptions}->{$idpConfKey}
              ->{samlIDPMetaDataOptionsSignSLOMessage};

            if ( $signSLOMessage == 0 ) {
                $self->lmLog(
                    "SLO message to IDP $idpConfKey will not be signed",
                    'debug' );
                $self->disableSignature($logout);
            }
            elsif ( $signSLOMessage == 1 ) {
                $self->lmLog( "SLO message to IDP $idpConfKey will be signed",
                    'debug' );
                $self->forceSignature($logout);
            }
            else {
                $self->lmLog(
"SLO message to IDP $idpConfKey signature according to metadata",
                    'debug'
                );
            }

            # Logout response
            unless ( $self->buildLogoutResponseMsg($logout) ) {
                $self->lmLog( "Unable to build SLO response", 'error' );
                return PE_SAML_SLO_ERROR;
            }

            # Send response depending on request method
            # HTTP-REDIRECT
            if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT ) {

                # Redirect user to response URL
                my $slo_url = $logout->msg_url;
                $self->lmLog( "Redirect user to $slo_url", 'debug' );

                $self->{urldc} = $slo_url;

                return $self->_subProcess(qw(autoRedirect));
            }

            # HTTP-POST
            elsif ( $method == Lasso::Constants::HTTP_METHOD_POST ) {

                # Use autosubmit form
                my $slo_url  = $logout->msg_url;
                my $slo_body = $logout->msg_body;

                $self->{postUrl} = $slo_url;
                $self->{postFields} = { 'SAMLResponse' => $slo_body };

                # RelayState
                $self->{postFields}->{'RelayState'} = $relaystate
                  if ($relaystate);

                return $self->_subProcess(qw(autoPost));
            }

            # HTTP-SOAP
            elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {

                my $slo_body = $logout->msg_body;

                $self->lmLog( "SOAP response $slo_body", 'debug' );

                $self->{SOAPMessage} = $slo_body;

                $self->_subProcess(qw(returnSOAPMessage));

                # If we are here, there was a problem with SOAP response
                $self->lmLog( "Logout response was not sent trough SOAP",
                    'error' );
                return PE_SAML_SLO_ERROR;
            }

        }
        else {

            # This should not happen
            $self->lmLog( "SLO request or response was not found", 'error' );

            # Redirect user
            $self->{mustRedirect} = 1;
            return $self->_subProcess(qw(autoRedirect));
        }
    }

    # 1.3 Artifact
    elsif ( $url =~ /^(\Q$saml_ars_url\E)$/io ) {

        $self->lmLog( "URL $url detected as an artifact resolution service URL",
            'debug' );

        # Artifact request are sent with SOAP trough POST
        my $art_request = $self->param('POSTDATA');
        my $art_response;

        # Create Login object
        my $login = $self->createLogin($server);

        # Process request message
        unless ( $self->processArtRequestMsg( $login, $art_request ) ) {
            $self->lmLog( "Unable to process artifact request message",
                'error' );
            return PE_SAML_ART_ERROR;
        }

        # Check Destination
        return PE_SAML_DESTINATION_ERROR
          unless ( $self->checkDestination( $login->request, $url ) );

        # Create artifact response
        unless ( $art_response = $self->createArtifactResponse($login) ) {
            $self->lmLog( "Unable to create artifact response message",
                'error' );
            return PE_SAML_ART_ERROR;
        }

        $self->{SOAPMessage} = $art_response;

        $self->lmLog( "Send SOAP Message: " . $self->{SOAPMessage}, 'debug' );

        # Return SOAP message
        $self->returnSOAPMessage();

        # If we are here, there was a problem with SOAP request
        $self->lmLog( "Artifact response was not sent trough SOAP", 'error' );
        return PE_SAML_ART_ERROR;

    }

    # 2. IDP resolution

    # Search a selected IdP
    my ( $idp, $idp_cookie ) = $self->_sub('getIDP');

    # Get confirmation flag
    my $confirm_flag = $self->param("confirm");

    # If confirmation is -1 from resolved IDP screen,
    # or IDP was not resolve, let the user choose its IDP
    if ( $confirm_flag == -1 or !$idp ) {
        $self->lmLog( "Redirecting user to IDP list", 'debug' );

        # Control url parameter
        my $urlcheck = $self->controlUrlOrigin();
        return $urlcheck unless ( $urlcheck == PE_OK );

        # IDP list
        my @list = ();
        foreach ( keys %{ $self->{_idpList} } ) {
            push @list,
              {
                val  => $_,
                name => $self->{_idpList}->{$_}->{name}
              };
        }
        $self->{list}            = \@list;
        $self->{confirmRemember} = 1;

        # Delete existing IDP resolution cookie
        push @{ $self->{cookie} },
          $self->cookie(
            -name    => $self->{samlIdPResolveCookie},
            -value   => 0,
            -domain  => $self->{domain},
            -path    => "/",
            -secure  => 0,
            -expires => '-1d',
          );

        $self->{login} = 1;
        return PE_CONFIRM;
    }

    # If IDP is found but not confirmed, let the user confirm it
    elsif ( $confirm_flag != 1 ) {
        $self->lmLog( "IDP $idp selected, need user confirmation", 'debug' );

        # Control url parameter
        my $urlcheck = $self->controlUrlOrigin();
        return $urlcheck unless ( $urlcheck == PE_OK );

        # Choosen IDP
        my $html = '<h3>'
          . $self->msg(PM_SAML_IDPCHOOSEN)
          . "</h3>\n" . "<h4>"
          . $self->{_idpList}->{$idp}->{name}
          . "</h4>\n"
          . "<p><i>"
          . $idp
          . "</i></p>\n"
          . "<input type=\"hidden\" name=\"url\" value=\""
          . $self->param("url") . "\" />"
          . "<input type=\"hidden\" name=\"idp\" value=\"$idp\" />\n";

        $self->info($html);

        $self->{login} = 1;
        return PE_CONFIRM;
    }

    # Here confirmation is OK (confirm_flag == 1), store choosen IDP in cookie
    unless ( $idp_cookie and $idp eq $idp_cookie ) {
        $self->lmLog( "Build cookie to remember $idp as IDP choice", 'debug' );

        # Control url parameter
        my $urlcheck = $self->controlUrlOrigin();
        return $urlcheck unless ( $urlcheck == PE_OK );

        # User can choose temporary (0) or persistent cookie (1)
        my $cookie_type = $self->param("cookie_type") || "0";

        push @{ $self->{cookie} },
          $self->cookie(
            -name     => $self->{samlIdPResolveCookie},
            -value    => $idp,
            -domain   => $self->{domain},
            -path     => "/",
            -secure   => $self->{securedCookie},
            -httponly => $self->{httpOnly},
            -expires  => $cookie_type ? "+365d" : "",
          );
    }

    # 3. Build authentication request

    # IDP conf key
    my $idpConfKey = $self->{_idpList}->{$idp}->{confKey};

    unless ($idpConfKey) {
        $self->lmLog( "$idp do not match any IDP in configuration", 'error' );
        return PE_SAML_UNKNOWN_ENTITY;
    }

    $self->lmLog( "$idp match $idpConfKey IDP in configuration", 'debug' );

    # IDP ForceAuthn
    my $forceAuthn =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsForceAuthn};

    # IDP IsPassive
    my $isPassive =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsIsPassive};

    # IDP NameIDFormat
    my $nameIDFormat =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsNameIDFormat};
    $nameIDFormat = $self->getNameIDFormat($nameIDFormat) if $nameIDFormat;

    # IDP ProxyRestriction
    my $allowProxiedAuthn =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsAllowProxiedAuthn};

    # IDP HTTP method
    my $method =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsSSOBinding};
    $method = $self->getHttpMethod($method);

    # If no method defined, get first HTTP method
    unless ( defined $method ) {
        my $protocolType = Lasso::Constants::MD_PROTOCOL_TYPE_SINGLE_SIGN_ON;
        $method = $self->getFirstHttpMethod( $server, $idp, $protocolType );
    }

    # Failback to HTTP-REDIRECT
    unless ( defined $method and $method != -1 ) {
        $self->lmLog( "No method found with IDP $idpConfKey for SSO profile",
            'debug' );
        $method = $self->getHttpMethod("redirect");
    }

    $self->lmLog(
        "Use method "
          . $self->getHttpMethodString($method)
          . " with IDP $idpConfKey for SSO profile",
        'debug'
    );

    # Set signature
    my $signSSOMessage =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsSignSSOMessage};

    # Authentication Context
    my $requestedAuthnContext =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsRequestedAuthnContext};
    $requestedAuthnContext = $self->getAuthnContext($requestedAuthnContext)
      if $requestedAuthnContext;

    # Create SSO request
    my $login = $self->createAuthnRequest(
        $server,            $idp,            $method,
        $forceAuthn,        $isPassive,      $nameIDFormat,
        $allowProxiedAuthn, $signSSOMessage, $requestedAuthnContext
    );

    unless ($login) {
        $self->lmLog( "Could not create authentication request on $idpConfKey",
            'error' );
        return PE_SAML_SSO_ERROR;
    }

    $self->lmLog( "Authentication request created", 'debug' );

    # Keep assertion ID in memory to prevent replay
    my $samlID = $login->request()->ID;
    unless ( $self->storeReplayProtection($samlID) ) {
        $self->lmLog( "Unable to store assertion ID", 'error' );
        return PE_SAML_SSO_ERROR;
    }

    # Keep initial SAML request data in memory in case of proxing
    if ( $self->{_proxiedSamlRequest} ) {

        my $samlSessionInfo = $self->getSamlSession();

        return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

        my $infos;

        $infos->{type}       = 'proxy';
        $infos->{_utime}     = time;
        $infos->{Request}    = $self->{_proxiedRequest};
        $infos->{Method}     = $self->{_proxiedMethod};
        $infos->{RelayState} = $self->{_proxiedRelayState};
        $infos->{Artifact}   = $self->{_proxiedArtifact};
        $infos->{ProxyID}    = $samlID;

        $samlSessionInfo->update($infos);

        $self->lmLog( "Keep initial SAML request data in memory for ID $samlID",
            'debug' );
    }

    # Send SSO request depending on request method
    # HTTP-REDIRECT
    if (   $method == $self->getHttpMethod('redirect')
        or $method == $self->getHttpMethod('artifact-get') )
    {

        # Redirect user to response URL
        my $sso_url = $login->msg_url;
        $self->lmLog( "Redirect user to $sso_url", 'debug' );

        $self->{urldc} = $sso_url;

        return $self->_subProcess(qw(autoRedirect));
    }

    # HTTP-POST
    elsif ($method == $self->getHttpMethod('post')
        or $method == $self->getHttpMethod('artifact-post') )
    {

        # Use autosubmit form
        my $sso_url  = $login->msg_url;
        my $sso_body = $login->msg_body;

        $self->{postUrl} = $sso_url;

        if ( $method == $self->getHttpMethod("artifact-post") ) {
            $self->{postFields} = { 'SAMLart' => $sso_body };
        }
        else {
            $self->{postFields} = { 'SAMLRequest' => $sso_body };
        }

        # RelayState
        $self->{postFields}->{'RelayState'} = $login->msg_relayState
          if ( $login->msg_relayState );

        return $self->_subProcess(qw(autoPost));
    }

    # No SOAP transport for SSO request
}

## @apmethod int setAuthSessionInfo()
# Extract attributes sent in authentication statement
# @return Lemonldap::NG::Portal error code
sub setAuthSessionInfo {
    my $self       = shift;
    my $server     = $self->{_lassoServer};
    my $login      = $self->{_lassoLogin};
    my $idp        = $self->{_idp};
    my $idpConfKey = $self->{_idpConfKey};

    # Get SAML assertion
    my $assertion = $self->getAssertion($login);

    unless ($assertion) {
        $self->lmLog( "No assertion found", 'error' );
        return PE_SAML_SSO_ERROR;
    }

    # Force UTF-8
    my $force_utf8 =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsForceUTF8};

    # Try to get attributes if attribute statement is present in assertion
    my $attr_statement = $assertion->AttributeStatement();
    if ($attr_statement) {

        # Get attributes
        my @attributes = $attr_statement->Attribute();

        # Wanted attributes are defined in IDP configuration
        foreach (
            keys %{ $self->{samlIDPMetaDataExportedAttributes}->{$idpConfKey} }
          )
        {

            # Extract fields from exportedAttr value
            my ( $mandatory, $name, $format, $friendly_name ) =
              split( /;/,
                $self->{samlIDPMetaDataExportedAttributes}->{$idpConfKey}->{$_}
              );

            # Try to get value
            my $value =
              $self->getAttributeValue( $name, $format, $friendly_name,
                \@attributes, $force_utf8 );

            # Store value in sessionInfo
            $self->{sessionInfo}->{$_} = $value if defined $value;
        }
    }

    # Store other informations in session
    $self->{sessionInfo}->{_user}       = $self->{user};
    $self->{sessionInfo}->{_idp}        = $idp;
    $self->{sessionInfo}->{_idpConfKey} = $idpConfKey;

    # Adapt _utime with SessionNotOnOrAfter
    my $sessionNotOnOrAfter;
    eval {
        $sessionNotOnOrAfter =
          $assertion->AuthnStatement()->SessionNotOnOrAfter();
    };

    if ( $@ or !$sessionNotOnOrAfter ) {
        $self->lmLog( "No SessionNotOnOrAfter value found", 'debug' );
    }
    else {

        my $samltime = $self->samldate2timestamp($sessionNotOnOrAfter);
        my $utime    = time();
        my $timeout  = $self->{timeout};
        my $adaptSessionUtime =
          $self->{samlIDPMetaDataOptions}->{$idpConfKey}
          ->{samlIDPMetaDataOptionsAdaptSessionUtime};

        if ( ( $utime + $timeout > $samltime ) and $adaptSessionUtime ) {

            # Use SAML time to determine the start of the session
            my $new_utime = $samltime - $timeout;
            $self->{sessionInfo}->{_utime} = $new_utime;
            $self->lmLog(
"Adapt _utime with SessionNotOnOrAfter value, new _utime: $new_utime",
                'debug'
            );
        }

    }

    # Establish federation (required for attribute request in UserDBSAML)
    unless ( $self->acceptSSO($login) ) {
        $self->lmLog( "Error while accepting SSO from IDP $idpConfKey",
            'error' );
        return PE_SAML_SSO_ERROR;
    }

    # Get created Lasso::Session and Lasso::Identity
    my $session  = $login->get_session;
    my $identity = $login->get_identity;

    # Dump Lasso objects in session
    $self->{sessionInfo}->{_lassoSessionDump}  = $session->dump()  if $session;
    $self->{sessionInfo}->{_lassoIdentityDump} = $identity->dump() if $identity;

    # Keep SAML Token in session
    my $store_samlToken =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsStoreSAMLToken};
    if ($store_samlToken) {
        $self->lmLog( "Store SAML Token in session", 'debug' );
        $self->{sessionInfo}->{_samlToken} = $self->{_samlToken};
    }
    else {
        $self->lmLog( "SAML Token will not be stored in session", 'debug' );
    }

    $self->{_lassoLogin} = $login;

    PE_OK;
}

## @apmethod int authenticate()
# Do nothing
# @return PE_OK
sub authenticate {
    PE_OK;
}

## @method protected *string getIDP()
# Try to find an IdP using :
# * HTTP parameter
# * "samlIdPResolveCookie" cookie
# * Rules
# * Common Domain Cookie
#
# @return Array containing :
# * IdP found (or undef)
# * Cookie value if exists
sub getIDP {
    my $self = shift;
    my $idp;
    my $idpName;

    my %cookies    = fetch CGI::Cookie;
    my $idp_cookie = $cookies{ $self->{samlIdPResolveCookie} };
    $idp_cookie &&= $idp_cookie->value;

    # Case 1: Recover IDP from idp URL Parameter
    unless ( $idp = $self->param("idp") ) {

        # Case 2: Recover IDP from idpName URL Parameter
        if ( $idpName = $self->param("idpName") ) {
            foreach ( keys %{ $self->{_idpList} } ) {
                my $idpConfKey = $self->{_idpList}->{$_}->{confKey};
                if ( $idpName eq $idpConfKey ) {
                    $idp = $_;
                    $self->lmLog(
                        "IDP $idp found from idpName URL Parameter ($idpName)",
                        'debug'
                    );
                    last;
                }
            }
        }

        # Case 3: Recover IDP from cookie
        if ( !$idp and $idp = $idp_cookie ) {
            $self->lmLog( "IDP $idp found in IDP resolution cookie", 'debug' );
        }

        # Case 4: check all IDP resolution rules
        # The first match win
        else {
            foreach ( keys %{ $self->{_idpList} } ) {
                my $idpConfKey = $self->{_idpList}->{$_}->{confKey};
                my $cond =
                  $self->{samlIDPMetaDataOptions}->{$idpConfKey}
                  ->{samlIDPMetaDataOptionsResolutionRule};
                next unless defined $cond;
                if ( $self->safe->reval($cond) ) {
                    $self->lmLog( "IDP $idpConfKey resolution rule match",
                        'debug' );
                    $idp = $_;
                    last;
                }
            }
        }

        # Case 5: use Common Domain Cookie
        if (   !$idp
            and $self->{samlCommonDomainCookieActivation}
            and $self->{samlCommonDomainCookieReader} )
        {
            $self->lmLog(
                "Will try to use Common Domain Cookie for IDP resolution",
                'debug' );

            # Add current URL to CDC Reader URL
            my $return_url = encode_base64( $self->self_url(), '' );

            my $cdc_reader_url = $self->{samlCommonDomainCookieReader};

            $cdc_reader_url .= (
                $self->{samlCommonDomainCookieReader} =~ /\?/
                ? '&url=' . $return_url
                : '?url=' . $return_url
            );

            $self->lmLog( "Redirect user to $cdc_reader_url", 'debug' );

            $self->{urldc} = $cdc_reader_url;

            return $self->_subProcess('autoRedirect');
        }

        $self->lmLog( 'No IDP found', 'debug' ) unless ($idp);
    }

    # Alert when selected IDP is unknown
    if ( $idp and !exists $self->{_idpList}->{$idp} ) {
        $self->_sub( 'userError', "Required IDP $idp does not exists" );
        $idp = undef;
    }

    return ( $idp, $idp_cookie );
}

## @apmethod void authLogout()
# Logout SP
# @return Lemonldap::NG::Portal error code
sub authLogout {
    my $self       = shift;
    my $idp        = $self->{sessionInfo}->{_idp};
    my $idpConfKey = $self->{sessionInfo}->{_idpConfKey};
    my $session_id = $self->{sessionInfo}->{_session_id};
    my $method;

    # Real session was previously deleted,
    # remove corresponding SAML sessions
    $self->deleteSAMLSecondarySessions($session_id);

    # Get Lasso Server
    unless ( $self->{_lassoServer} ) {
        $self->_sub('Lemonldap::NG::Portal::AuthSAML::authInit');
    }

    my $server = $self->{_lassoServer};

    # Recover Lasso::Session dump
    my $session_dump = $self->{sessionInfo}->{_lassoSessionDump};

    unless ($session_dump) {
        $self->lmLog( "Could not get session dump from session", 'error' );
        return PE_SAML_SLO_ERROR;
    }

    # IDP HTTP method
    $method =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsSLOBinding};
    $method = $self->getHttpMethod($method);

    # If no method defined, get first HTTP method
    unless ( defined $method ) {
        my $protocolType = Lasso::Constants::MD_PROTOCOL_TYPE_SINGLE_LOGOUT;
        $method = $self->getFirstHttpMethod( $server, $idp, $protocolType );
    }

    # Skip SLO if no method found
    unless ( defined $method and $method != -1 ) {
        $self->lmLog( "No method found with IDP $idpConfKey for SLO profile",
            'debug' );
        return PE_OK;
    }

    $self->lmLog(
        "Use method "
          . $self->getHttpMethodString($method)
          . " with IDP $idpConfKey for SLO profile",
        'debug'
    );

    # Set signature
    my $signSLOMessage =
      $self->{samlIDPMetaDataOptions}->{$idpConfKey}
      ->{samlIDPMetaDataOptionsSignSLOMessage};

    # Build Logout Request
    my $logout =
      $self->createLogoutRequest( $server, $session_dump, $method,
        $signSLOMessage );
    unless ($logout) {
        $self->lmLog( "Could not create logout request", 'error' );
        return PE_SAML_SLO_ERROR;
    }

    $self->lmLog( "Logout request created", 'debug' );

    # Keep request ID in memory to prevent replay
    unless ( $self->storeReplayProtection( $logout->request()->ID ) ) {
        $self->lmLog( "Unable to store Logout request ID", 'error' );
        return PE_SAML_SLO_ERROR;
    }

    # Send request depending on request method
    # HTTP-REDIRECT
    if ( $method == Lasso::Constants::HTTP_METHOD_REDIRECT ) {

        # Redirect user to response URL
        my $slo_url = $logout->msg_url;
        $self->lmLog( "Redirect user to $slo_url", 'debug' );

        $self->{urldc} = $slo_url;

        # Redirect done in Portal/Simple.pm
        return PE_OK;
    }

    # HTTP-POST
    elsif ( $method == Lasso::Constants::HTTP_METHOD_POST ) {

        # Use autosubmit form
        my $slo_url  = $logout->msg_url;
        my $slo_body = $logout->msg_body;

        $self->{postUrl} = $slo_url;
        $self->{postFields} = { 'SAMLRequest' => $slo_body };

        # RelayState
        $self->{postFields}->{'RelayState'} = $logout->msg_relayState
          if ( $logout->msg_relayState );

        # Post done in Portal/Simple.pm
        return PE_OK;
    }

    # HTTP-SOAP
    elsif ( $method == Lasso::Constants::HTTP_METHOD_SOAP ) {

        my $slo_url  = $logout->msg_url;
        my $slo_body = $logout->msg_body;

        # Send SOAP request and manage response
        my $response = $self->sendSOAPMessage( $slo_url, $slo_body );

        unless ($response) {
            $self->lmLog( "No logout response to SOAP request", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        # Create Logout object
        $logout = $self->createLogout($server);

        # Process logout response
        my $result = $self->processLogoutResponseMsg( $logout, $response );

        unless ($result) {
            $self->lmLog( "Fail to process logout response", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        $self->lmLog( "Logout response is valid", 'debug' );

        # Replay protection
        my $samlID = $logout->response()->InResponseTo;

        unless ( $self->replayProtection($samlID) ) {

            # Logout request was already consumed or is expired
            $self->lmLog( "Message $samlID already used or expired", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        return PE_OK;
    }

}

## @apmethod boolean authForce()
# Check if authentication should be forced
# @return nothing
sub authForce {
    my $self = shift;

    my $url = $self->url( -absolute => 1 );

    my $saml_acs_art_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact");
    my $saml_acs_post_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPPost");
    my $saml_acs_get_url = $self->getMetaDataURL(
        "samlSPSSODescriptorAssertionConsumerServiceHTTPRedirect");
    my $saml_slo_soap_url =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_soap_url_ret =
      $self->getMetaDataURL( "samlSPSSODescriptorSingleLogoutServiceSOAP", 2 );
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
    my $saml_ars_url = $self->getMetaDataURL(
        "samlSPSSODescriptorArtifactResolutionServiceArtifact");

    return 1
      if ( $url =~
/^(\Q$saml_acs_art_url\E|\Q$saml_acs_post_url\E|\Q$saml_acs_get_url\E|\Q$saml_slo_soap_url\E|\Q$saml_slo_soap_url_ret\E|\Q$saml_slo_get_url\E|\Q$saml_slo_get_url_ret\E|\Q$saml_slo_post_url\E|\Q$saml_slo_post_url_ret\E|\Q$saml_ars_url\E)$/io
      );

    return 0;
}

## @apmethod boolean authFinish()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub authFinish {
    PE_OK;
}

## @apmethod boolean authPostStore()
# Associate NameID and SessionIndex to a local session
# @return Lemonldap::NG::Portal error code
sub authPostStore {
    my $self = shift;
    my %h;

    # Real session was stored, get id and utime
    my $id    = $self->{id};
    my $utime = $self->{sessionInfo}->{_utime};

    # Get saved Lasso objects
    my $nameid        = $self->{_nameID};
    my $session_index = $self->{_sessionIndex};

    $self->lmLog(
        "Store NameID "
          . $nameid->dump
          . " and SessionIndex $session_index for session $id",
        'debug'
    );

    # Save SAML session
    my $samlSessionInfo = $self->getSamlSession();

    return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

    my $infos;
    $infos->{type}          = 'saml';            # Session type
    $infos->{_utime}        = $utime;            # Creation time
    $infos->{_saml_id}      = $id;               # SSO session id
    $infos->{_nameID}       = $nameid->dump;     # SAML NameID
    $infos->{_sessionIndex} = $session_index;    # SAML SessionIndex

    $samlSessionInfo->update($infos);

    my $session_id = $samlSessionInfo->id;

    $self->lmLog( "Link session $id to SAML session $session_id", 'debug' );

    return PE_OK;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "logo";
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthSAML - SAML Authentication backend

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::AuthSAML;

=head1 DESCRIPTION

Use SAML to authenticate users

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::UserDBSAML>, L<Lemonldap::NG::Portal::_SAML>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2009-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010-2015 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2010 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

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
