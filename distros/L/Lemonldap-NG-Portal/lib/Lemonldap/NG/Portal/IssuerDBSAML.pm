## @file
# SAML Issuer file

## @class
# SAML Issuer class
package Lemonldap::NG::Portal::IssuerDBSAML;

use strict;
use Lemonldap::NG::Common::Conf::SAML::Metadata;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_SAML;
our @ISA = qw(Lemonldap::NG::Portal::_SAML);

our $VERSION = '1.9.9';

## @method void issuerDBInit()
# Load and check SAML configuration
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;

    # Load SAML service
    return PE_SAML_LOAD_SERVICE_ERROR unless $self->loadService();

    # Load SAML service providers
    return PE_SAML_LOAD_SP_ERROR unless $self->loadSPs();

    # Load SAML identity providers
    # Required to manage SLO in Proxy mode
    return PE_SAML_LOAD_IDP_ERROR unless $self->loadIDPs();

    PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Check if there is an SAML authentication request
# Called only for unauthenticated users, check isPassive flag
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    my $self   = shift;
    my $server = $self->{_lassoServer};

    # Get configuration parameter
    my $saml_sso_soap_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceSOAP", 1 );
    my $saml_sso_soap_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceSOAP", 2 );
    my $saml_sso_get_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect", 1 );
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
    my $saml_slo_soap_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_soap_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceSOAP", 2 );
    my $saml_slo_get_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect", 1 );
    my $saml_slo_get_url_ret = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect", 2 );
    my $saml_slo_post_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        1 );
    my $saml_slo_post_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        2 );
    my $saml_ars_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorArtifactResolutionServiceArtifact");
    my $saml_slo_url_relay_soap = '/saml/relaySingleLogoutSOAP';
    my $saml_slo_url_relay_post = '/saml/relaySingleLogoutPOST';
    my $saml_slo_url_relay_term = '/saml/relaySingleLogoutTermination';
    my $saml_att_soap_url       = $self->getMetaDataURL(
        "samlAttributeAuthorityDescriptorAttributeServiceSOAP", 1 );

    # Get HTTP request informations to know
    # if we are receving SAML request or response
    my $url                     = $self->url( -absolute => 1 );
    my $request_method          = $self->request_method();
    my $content_type            = $self->content_type();
    my $idp_initiated           = $self->param('IDPInitiated');
    my $idp_initiated_sp        = $self->param('sp');
    my $idp_initiated_spConfKey = $self->param('spConfKey');

    # 1.1. SSO
    if ( $url =~
/^(\Q$saml_sso_soap_url\E|\Q$saml_sso_soap_url_ret\E|\Q$saml_sso_get_url\E|\Q$saml_sso_get_url_ret\E|\Q$saml_sso_post_url\E|\Q$saml_sso_post_url_ret\E|\Q$saml_sso_art_url\E|\Q$saml_sso_art_url_ret\E)$/io
      )
    {

        $self->lmLog( "URL $url detected as an SSO request URL", 'debug' );

        # Get hidden params for IDP initiated if needed
        $idp_initiated = $self->getHiddenFormValue('IDPInitiated')
          unless defined $idp_initiated;
        $idp_initiated_sp = $self->getHiddenFormValue('sp')
          unless defined $idp_initiated_sp;
        $idp_initiated_spConfKey = $self->getHiddenFormValue('spConfKey')
          unless defined $idp_initiated_spConfKey;

        # Check message
        my ( $request, $response, $method, $relaystate, $artifact ) =
          $self->checkMessage( $url, $request_method, $content_type );

        # Create Login object
        my $login = $self->createLogin($server);

        # Ignore signature verification
        $self->disableSignatureVerification($login);

        # Process the request
        if ($request) {

            # Process authentication request
            my $result;
            if ($artifact) {
                $result = $self->processArtResponseMsg( $login, $request );
            }
            else {
                $result = $self->processAuthnRequestMsg( $login, $request );
            }

            unless ($result) {
                $self->lmLog( "SSO: Fail to process authentication request",
                    'error' );
                return PE_SAML_SSO_ERROR;
            }

            $self->lmLog( "SSO: authentication request is valid", 'debug' );

            # Get SP entityID
            my $sp = $login->remote_providerID();

            $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

            # SP conf key
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->lmLog( "$sp do not match any SP in configuration",
                    'error' );
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

            # Store values in %ENV
            $ENV{"llng_saml_sp"}        = $sp;
            $ENV{"llng_saml_spconfkey"} = $spConfKey;

            # Do we check signature?
            my $checkSSOMessageSignature =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
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

            # Get SAML request
            my $saml_request = $login->request();
            unless ($saml_request) {
                $self->lmLog( "No SAML request found", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            # Check Destination
            return PE_SAML_DESTINATION_ERROR
              unless ( $self->checkDestination( $saml_request, $url ) );

            # Check isPassive flag
            my $isPassive = $saml_request->IsPassive();

            if ($isPassive) {
                $self->lmLog(
"Found isPassive flag in SAML request, not compatible with unauthenticated user",
                    'error'
                );
                return PE_SAML_SSO_ERROR;
            }

            # Store SAML elements in memory in case of proxying
            $self->{_proxiedSamlRequest} = $saml_request;
            $self->{_proxiedRequest}     = $request;
            $self->{_proxiedMethod}      = $method;
            $self->{_proxiedRelayState}  = $relaystate;
            $self->{_proxiedArtifact}    = $artifact;

            return PE_OK;
        }

        elsif ($response) {
            $self->lmLog(
                "Authentication responses are not managed by this module",
                'debug' );
            return PE_OK;
        }

        else {

            if ($idp_initiated) {

                # Keep IDP initiated parameters
                $self->setHiddenFormValue( 'IDPInitiated', $idp_initiated )
                  if defined $idp_initiated;
                $self->setHiddenFormValue( 'sp', $idp_initiated_sp )
                  if defined $idp_initiated_sp;
                $self->setHiddenFormValue( 'spConfKey',
                    $idp_initiated_spConfKey )
                  if defined $idp_initiated_spConfKey;

                $self->lmLog( "Store URL parameters for IDP initiated request",
                    'debug' );

            }
            else {

                # No request or response
                # This should not happen
                $self->lmLog( "No request or response found", 'debug' );
            }
            return PE_OK;

        }

    }

    # 1.2. SLO
    if ( $url =~
/^(\Q$saml_slo_soap_url\E|\Q$saml_slo_soap_url_ret\E|\Q$saml_slo_get_url\E|\Q$saml_slo_get_url_ret\E|\Q$saml_slo_post_url\E|\Q$saml_slo_post_url_ret\E)$/io
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

        if ($request) {

            # Process logout request
            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                $self->lmLog( "SLO: Fail to process logout request", 'error' );

                # Cannot send SLO error response if request not processed
                return PE_SAML_SLO_ERROR;
            }

            $self->lmLog( "SLO: Logout request is valid", 'debug' );

            # We accept only SOAP here
            unless ( $method eq $self->getHttpMethod('soap') ) {
                $self->lmLog( "Only SOAP requests allowed here", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Get SP entityID
            my $sp = $logout->remote_providerID();

            $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

            # SP conf key
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->lmLog( "$sp do not match any SP in configuration",
                    'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

            # Store values in %ENV
            $ENV{"llng_saml_sp"}        = $sp;
            $ENV{"llng_saml_spconfkey"} = $spConfKey;

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {

                $self->forceSignatureVerification($logout);

                unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                    $self->lmLog( "Signature is not valid", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Get SAML request
            my $saml_request = $logout->request();
            unless ($saml_request) {
                $self->lmLog( "No SAML request found", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Check Destination
            return $self->sendSLOErrorResponse( $logout, $method )
              unless ( $self->checkDestination( $saml_request, $url ) );

            # Get session index
            my $session_index;
            eval { $session_index = $logout->request()->SessionIndex; };

            # SLO requests without session index are not accepted
            unless ( defined $session_index ) {
                $self->lmLog(
                    "No session index in SLO request from $spConfKey SP",
                    'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Decrypt session index
            my $local_session_id = $self->{cipher}->decrypt($session_index);

            $self->lmLog(
"Get session id $local_session_id (decrypted from $session_index)",
                'debug'
            );

            # Open local session
            my $local_session = $self->getApacheSession( $local_session_id, 1 );

            unless ($local_session) {
                $self->lmLog( "No local session found", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Load Session and Identity if they exist
            my $session  = $local_session->data->{_lassoSessionDump};
            my $identity = $local_session->data->{_lassoIdentityDump};

            if ($session) {
                unless ( $self->setSessionFromDump( $logout, $session ) ) {
                    $self->lmLog( "Unable to load Lasso Session", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                $self->lmLog( "Lasso Session loaded", 'debug' );
            }

            if ($identity) {
                unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
                    $self->lmLog( "Unable to load Lasso Identity", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                $self->lmLog( "Lasso Identity loaded", 'debug' );
            }

            # Close SAML sessions
            unless ( $self->deleteSAMLSecondarySessions($local_session_id) ) {
                $self->lmLog( "Fail to delete SAML sessions", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Close local session
            unless ( $self->_deleteSession($local_session) ) {
                $self->lmLog( "Fail to delete session $local_session_id",
                    'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Validate request if no previous error
            unless ( $self->validateLogoutRequest($logout) ) {
                $self->lmLog( "SLO request is not valid", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Try to send SLO request trough SOAP
            $self->resetProviderIdIndex($logout);
            while ( my $providerID = $self->getNextProviderId($logout) ) {

                # Send logout request
                my ( $rstatus, $rmethod, $rinfo ) =
                  $self->sendLogoutRequestToProvider( $logout, $providerID,
                    $self->getHttpMethod('soap'), 0 );

                if ($rstatus) {
                    $self->lmLog( "SOAP SLO successful on $providerID",
                        'debug' );
                }
                else {
                    $self->lmLog( "SOAP SLO error on $providerID", 'debug' );
                }
            }

            # Set RelayState
            if ($relaystate) {
                $logout->msg_relayState($relaystate);
                $self->lmLog( "Set $relaystate in RelayState", 'debug' );
            }

            # Signature
            my $signSLOMessage =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSignSLOMessage};

            if ( $signSLOMessage == 0 ) {
                $self->lmLog( "SLO response will not be signed", 'debug' );
                $self->disableSignature($logout);
            }
            elsif ( $signSLOMessage == 1 ) {
                $self->lmLog( "SLO response will be signed", 'debug' );
                $self->forceSignature($logout);
            }
            else {
                $self->lmLog( "SLO response signature according to metadata",
                    'debug' );
            }

            # Send logout response
            if ( my $tmp =
                $self->sendLogoutResponseToServiceProvider( $logout, $method ) )
            {
                return $tmp;
            }
            else {
                return $self->sendSLOErrorResponse( $logout, $method );
            }
        }

        elsif ($response) {

            # Process logout response
            my $result = $self->processLogoutResponseMsg( $logout, $response );

            unless ($result) {
                $self->lmLog( "Fail to process logout response", 'error' );
                return PE_IMG_NOK;
            }

            $self->lmLog( "Logout response is valid", 'debug' );

            # Check Destination
            return PE_IMG_NOK
              unless ( $self->checkDestination( $logout->response, $url ) );

            # Get SP entityID
            my $sp = $logout->remote_providerID();

            $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

            # SP conf key
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->lmLog( "$sp do not match any SP in configuration",
                    'error' );
                return PE_IMG_NOK;
            }

            $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

            # Store values in %ENV
            $ENV{"llng_saml_sp"}        = $sp;
            $ENV{"llng_saml_spconfkey"} = $spConfKey;

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {
                unless ( $self->checkSignatureStatus($logout) ) {
                    $self->lmLog( "Signature is not valid", 'error' );
                    return PE_IMG_NOK;
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Store success status for this SLO request
            my $sloStatusSessionInfos = $self->getSamlSession($relaystate);

            if ($sloStatusSessionInfos) {
                $sloStatusSessionInfos->update( { $spConfKey => 1 } );
                $self->lmLog(
                    "Store SLO status for $spConfKey in session $relaystate",
                    'debug' );
            }
            else {
                $self->lmLog(
"Unable to store SLO status for $spConfKey in session $relaystate",
                    'warn'
                );
            }

            # SLO response is OK
            $self->lmLog( "Display OK status for SLO on $spConfKey", 'debug' );
            return PE_IMG_OK;
        }

        else {

            # No request or response
            # This should not happen
            $self->lmLog( "No request or response found", 'debug' );
            return PE_OK;
        }

    }

    # 1.3. SLO relay

    # 1.3.1 SOAP
    #      This URL is used by IMG html tag, and should returned PE_IMG_*
    if ( $url =~ /^(\Q$saml_slo_url_relay_soap\E)/io ) {

        $self->lmLog( "URL $url detected as a SOAP relay service URL",
            'debug' );

        # Check if relay parameter is present (mandatory)
        my $relayID;
        unless ( $relayID = $self->param('relay') ) {
            $self->lmLog( "No relayID detected", 'error' );
            return PE_IMG_NOK;
        }

        # Retrieve the corresponding data from samlStorage
        my $relayInfos = $self->getSamlSession($relayID);
        unless ($relayInfos) {
            $self->lmLog( "Could not get relay session $relayID", 'error' );
            return PE_IMG_NOK;
        }

        $self->lmLog( "Found relay session $relayID", 'debug' );

        # Rebuild the logout object
        my $logout;
        unless ( $logout = $self->createLogout($server) ) {
            $self->lmLog( "Could not rebuild logout object", 'error' );
            return PE_IMG_NOK;
        }

        # Load Session and Identity if they exist
        my $session    = $relayInfos->data->{_lassoSessionDump};
        my $identity   = $relayInfos->data->{_lassoIdentityDump};
        my $providerID = $relayInfos->data->{_providerID};
        my $relayState = $relayInfos->data->{_relayState};
        my $spConfKey  = $self->{_spList}->{$providerID}->{confKey};

        if ($session) {
            unless ( $self->setSessionFromDump( $logout, $session ) ) {
                $self->lmLog( "Unable to load Lasso Session", 'error' );
                return PE_IMG_NOK;
            }
            $self->lmLog( "Lasso Session loaded", 'debug' );
        }

        if ($identity) {
            unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
                $self->lmLog( "Unable to load Lasso Identity", 'error' );
                return PE_IMG_NOK;
            }
            $self->lmLog( "Lasso Identity loaded", 'debug' );
        }

        # Send the logout request
        my ( $rstatus, $rmethod, $rinfo ) =
          $self->sendLogoutRequestToProvider( $logout, $providerID,
            Lasso::Constants::HTTP_METHOD_SOAP );
        unless ($rstatus) {
            $self->lmLog( "Fail to process SOAP logout request to $providerID",
                'error' );
            return PE_IMG_NOK;
        }

        # Store success status for this SLO request
        my $sloStatusSessionInfos = $self->getSamlSession($relayState);

        if ($sloStatusSessionInfos) {
            $sloStatusSessionInfos->update( { $spConfKey => 1 } );
            $self->lmLog(
                "Store SLO status for $spConfKey in session $relayState",
                'debug' );
        }
        else {
            $self->lmLog(
"Unable to store SLO status for $spConfKey in session $relayState",
                'warn'
            );
        }

        # Delete relay session
        $relayInfos->remove();

        # SLO response is OK
        $self->lmLog( "Display OK status for SLO on $spConfKey", 'debug' );
        return PE_IMG_OK;
    }

    # 1.3.2 POST
    #      This URL is used as iframe source, and autoPost a form
    #      Can return an error img
    if ( $url =~ /^(\Q$saml_slo_url_relay_post\E)/io ) {

        $self->lmLog( "URL $url detected as a POST relay service URL",
            'debug' );

        # Check if relay parameter is present (mandatory)
        my $relayID;
        unless ( $relayID = $self->param('relay') ) {
            $self->lmLog( "No relayID detected", 'error' );
            return PE_IMG_NOK;
        }

        # Retrieve the corresponding data from samlStorage
        my $relayInfos = $self->getSamlSession($relayID);
        unless ($relayInfos) {
            $self->lmLog( "Could not get relay session $relayID", 'error' );
            return PE_IMG_NOK;
        }

        $self->lmLog( "Found relay session $relayID", 'debug' );

        # Get data to build POST form
        $self->{postUrl}                     = $relayInfos->data->{url};
        $self->{postFields}->{'SAMLRequest'} = $relayInfos->data->{body};
        $self->{postFields}->{'RelayState'}  = $relayInfos->data->{relayState};

        # Delete relay session
        $relayInfos->remove();

        return $self->_subProcess(qw(autoPost));
    }

    # 1.3.3 Termination
    #      Used to send SLO response to SP issuing SLO request
    if ( $url =~ /^(\Q$saml_slo_url_relay_term\E)/io ) {

        $self->lmLog(
            "URL $url detected as a SLO Termination relay service URL",
            'debug' );

        # Check if relay parameter is present (mandatory)
        my $relayID;
        unless ( $relayID = $self->getHiddenFormValue('relay') ) {
            $self->lmLog( "No relayID detected", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        # Retrieve the corresponding data from samlStorage
        my $relayInfos = $self->getSamlSession($relayID);
        unless ($relayInfos) {
            $self->lmLog( "Could not get relay session $relayID", 'error' );
            return PE_SAML_SESSION_ERROR;
        }

        $self->lmLog( "Found relay session $relayID", 'debug' );

        # Get data from relay session
        my $logout_dump  = $relayInfos->data->{_logout};
        my $session_dump = $relayInfos->data->{_session};
        my $method       = $relayInfos->data->{_method};

        unless ($logout_dump) {
            $self->lmLog( "Could not get logout dump", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        # Rebuild Lasso::Logout object
        my $logout = $self->createLogout( $server, $logout_dump );

        unless ($logout) {
            $self->lmLog( "Could not build Lasso::Logout", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        # Inject session
        unless ($session_dump) {
            $self->lmLog( "Could not get session dump", 'error' );
            return PE_SAML_SLO_ERROR;
        }

        unless ( $self->setSessionFromDump( $logout, $session_dump ) ) {
            $self->lmLog( "Could not set session from dump", 'error' );
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
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};
            my $status    = $relayInfos->data->{$spConfKey};

            # Remove assertion if status is OK
            if ($status) {
                eval { $session->remove_assertion($sp); };

                if ($@) {
                    $self->lmLog( "Unable to remove assertion for $sp",
                        'warn' );
                }
                else {
                    $self->lmLog( "Assertion removed for $sp", 'debug' );
                }
            }
            else {
                $self->lmLog(
                    "SLO status was not ok for $sp, assertion not removed",
                    'debug' );
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
            $self->sendLogoutResponseToServiceProvider( $logout, $method ) )
        {
            return $tmp;
        }
        else {
            $self->lmLog( "Fail to send SLO response", 'error' );
            return PE_SAML_SLO_ERROR;
        }
    }

    # 1.4. Artifacts
    if ( $url =~ /^(\Q$saml_ars_url\E)$/io ) {

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
            $self->returnSOAPMessage();
        }

        # Check Destination
        $self->returnSOAPMessage()
          unless ( $self->checkDestination( $login->request, $url ) );

        # Create artifact response
        unless ( $art_response = $self->createArtifactResponse($login) ) {
            $self->lmLog( "Unable to create artifact response message",
                'error' );
            $self->returnSOAPMessage();
        }

        $self->{SOAPMessage} = $art_response;

        $self->lmLog( "Send SOAP Message: " . $self->{SOAPMessage}, 'debug' );

        # Return SOAP message
        $self->returnSOAPMessage();

        # If we are here, there was a problem with SOAP request
        $self->lmLog( "Artifact response was not sent trough SOAP", 'error' );
        $self->quit();

    }

    # 1.5 Attribute query
    if ( $url =~ /^(\Q$saml_att_soap_url\E)$/io ) {

        $self->lmLog( "URL $url detected as an attribute service URL",
            'debug' );

        # Attribute request are sent with SOAP trough POST
        my $att_request = $self->param('POSTDATA');
        my $att_response;

        # Process request
        my $query = $self->processAttributeRequest( $server, $att_request );
        unless ($query) {
            $self->lmLog( "Unable to process attribute request", 'error' );
            $self->returnSOAPMessage();
        }

        # Get SP entityID
        my $sp = $query->remote_providerID();

        $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

        # SP conf key
        my $spConfKey = $self->{_spList}->{$sp}->{confKey};

        unless ($spConfKey) {
            $self->lmLog( "$sp do not match any SP in configuration", 'error' );
            return PE_SAML_UNKNOWN_ENTITY;
        }

        $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

        # Check Destination
        $self->returnSOAPMessage()
          unless ( $self->checkDestination( $query->request, $url ) );

        # Validate request
        unless ( $self->validateAttributeRequest($query) ) {
            $self->lmLog( "Attribute request not valid", 'error' );
            $self->returnSOAPMessage();
        }

        # Get NameID
        my $name_id = $query->nameIdentifier();

        unless ($name_id) {
            $self->lmLog( "Fail to get NameID from attribute request",
                'error' );
            $self->returnSOAPMessage();
        }

        my $user = $name_id->content();

        # Get sessionInfo for the given NameID
        my $sessionInfo;
        my $moduleOptions = $self->{samlStorageOptions} || {};
        $moduleOptions->{backend} = $self->{samlStorage};
        my $module = "Lemonldap::NG::Common::Apache::Session";

        my $saml_sessions =
          $module->searchOn( $moduleOptions, "_nameID", $name_id->dump );

        if ( my @saml_sessions_keys = keys %$saml_sessions ) {

            # Warning if more than one session found
            if ( $#saml_sessions_keys > 0 ) {
                $self->lmLog( "More than one SAML session found for user $user",
                    'warn' );
            }

            # Take the first session
            my $saml_session = shift @saml_sessions_keys;

            # Get session
            $self->lmLog( "Retrieve SAML session $saml_session for user $user",
                'debug' );

            my $samlSessionInfo = $self->getSamlSession($saml_session);

            # Get real session
            my $real_session = $samlSessionInfo->data->{_saml_id};

            $self->lmLog( "Retrieve real session $real_session for user $user",
                'debug' );

            $sessionInfo = $self->getApacheSession( $real_session, 1 );

            unless ($sessionInfo) {
                $self->lmLog( "Cannot get session $real_session", 'error' );
                $self->returnSOAPMessage();
            }

        }
        else {
            $self->lmLog( "No SAML session found for user $user", 'error' );
            $self->returnSOAPMessage();
        }

        # Get requested attributes
        my @requested_attributes;
        eval { @requested_attributes = $query->request()->Attribute(); };
        if ($@) {
            $self->checkLassoError($@);
            $self->returnSOAPMessage();
        }

        # Returned attributes
        my @returned_attributes;

        # Browse SP authorized attributes
        foreach (
            keys %{ $self->{samlSPMetaDataExportedAttributes}->{$spConfKey} } )
        {
            my $sp_attr = $_;

            # Extract fields from exportedAttr value
            my ( $mandatory, $name, $format, $friendly_name ) =
              split( /;/,
                $self->{samlSPMetaDataExportedAttributes}->{$spConfKey}
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

                $self->lmLog(
                    "SP $spConfKey is authorized to access attribute $rname",
                    'debug' );

                $self->lmLog(
                    "Attribute $rname is linked to $sp_attr session key",
                    'debug' );

                # Check if values are given
                my $rvalue =
                  $self->getAttributeValue( $rname, $rformat, $rfriendly_name,
                    [$req_attr] );

                $self->lmLog( "Some values are explicitely requested: $rvalue",
                    'debug' )
                  if defined $rvalue;

                # Get session value
                if ( $sessionInfo->data->{$sp_attr} ) {

                    my @values = split $self->{multiValuesSeparator},
                      $sessionInfo->data->{$sp_attr};
                    my @saml2values;

                    # SAML2 attribute
                    my $ret_attr =
                      $self->createAttribute( $rname, $rformat,
                        $rfriendly_name );

                    unless ($ret_attr) {
                        $self->lmLog( "Unable to create a new SAML attribute",
                            'error' );
                        $self->returnSOAPMessage();
                    }

                    foreach (@values) {

                        my $local_value = $_;

                        # Check if values were set in requested attribute
                        # In this case, only requested values can be returned
                        if (
                            $rvalue
                            and !map( /^$local_value$/,
                                split( $self->{multiValuesSeparator}, $rvalue )
                            )
                          )
                        {
                            $self->lmLog(
"$local_value value is not in requested values, it will not be sent",
                                'warn'
                            );
                            next;
                        }

                        # SAML2 attribute value
                        my $saml2value = $self->createAttributeValue(
                            $local_value,
                            $self->{samlSPMetaDataOptions}->{$spConfKey}
                              ->{samlSPMetaDataOptionsForceUTF8}
                        );

                        unless ($saml2value) {
                            $self->lmLog(
                                "Unable to create a new SAML attribute value",
                                'error' );
                            $self->returnSOAPMessage();
                        }

                        push @saml2values, $saml2value;

                        $self->lmLog(
                            "Push $local_value in SAML attribute $name",
                            'debug' );

                    }

                    $ret_attr->AttributeValue(@saml2values);

                    # Push attribute in attribute list
                    push @returned_attributes, $ret_attr;

                }
                else {
                    $self->lmLog( "No session value for $sp_attr", 'debug' );
                }

            }

        }

        # Create attribute statement
        if ( scalar @returned_attributes ) {
            my $attribute_statement;

            eval {
                $attribute_statement = Lasso::Saml2AttributeStatement->new();
            };
            if ($@) {
                $self->checkLassoError($@);
                $self->returnSOAPMessage();
            }

            # Register attributes in attribute statement
            $attribute_statement->Attribute(@returned_attributes);

            # Create assetion
            my $assertion;

            eval { $assertion = Lasso::Saml2Assertion->new(); };
            if ($@) {
                $self->checkLassoError($@);
                $self->returnSOAPMessage();
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
            $self->lmLog( "Unable to build attribute response", 'error' );
            $self->returnSOAPMessage();
        }

        $self->{SOAPMessage} = $att_response;

        # Return SOAP message
        $self->returnSOAPMessage();

        # If we are here, there was a problem with SOAP request
        $self->lmLog( "Attribute response was not sent trough SOAP", 'error' );
        $self->quit();

    }

    PE_OK;
}

## @apmethod int issuerForAuthUser()
# Check if there is an SAML authentication request for an authenticated user
# Build assertions and redirect user
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    my $self   = shift;
    my $server = $self->{_lassoServer};
    my $login;
    my $protocolProfile;
    my $artifact_method;
    my $authn_context;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Session creation timestamp
    my $time = $self->{sessionInfo}->{_utime} || time();

    # Get configuration parameter
    my $saml_sso_soap_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceSOAP", 1 );
    my $saml_sso_soap_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleSignOnServiceSOAP", 2 );
    my $saml_sso_get_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect", 1 );
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
    my $saml_slo_soap_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceSOAP", 1 );
    my $saml_slo_soap_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceSOAP", 2 );
    my $saml_slo_get_url = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect", 1 );
    my $saml_slo_get_url_ret = $self->getMetaDataURL(
        "samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect", 2 );
    my $saml_slo_post_url =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        1 );
    my $saml_slo_post_url_ret =
      $self->getMetaDataURL( "samlIDPSSODescriptorSingleLogoutServiceHTTPPost",
        2 );

    # Get HTTP request informations to know
    # if we are receving SAML request or response
    my $url                     = $self->url( -absolute => 1 );
    my $request_method          = $self->request_method();
    my $content_type            = $self->content_type();
    my $idp_initiated           = $self->param('IDPInitiated');
    my $idp_initiated_sp        = $self->param('sp');
    my $idp_initiated_spConfKey = $self->param('spConfKey');

    # 1.1. SSO (SSO URL or Proxy Mode)
    if ( $url =~
/^(\Q$saml_sso_soap_url\E|\Q$saml_sso_soap_url_ret\E|\Q$saml_sso_get_url\E|\Q$saml_sso_get_url_ret\E|\Q$saml_sso_post_url\E|\Q$saml_sso_post_url_ret\E|\Q$saml_sso_art_url\E|\Q$saml_sso_art_url_ret\E)$/io
        or $self->{_proxiedRequest} )
    {

        $self->lmLog( "URL $url detected as an SSO request URL", 'debug' );

        # Get hidden params for IDP initiated if needed
        $idp_initiated = $self->getHiddenFormValue('IDPInitiated')
          unless defined $idp_initiated;
        $idp_initiated_sp = $self->getHiddenFormValue('sp')
          unless defined $idp_initiated_sp;
        $idp_initiated_spConfKey = $self->getHiddenFormValue('spConfKey')
          unless defined $idp_initiated_spConfKey;

        # Check message
        my ( $request, $response, $method, $relaystate, $artifact );

        if ( $self->{_proxiedRequest} ) {
            $request    = $self->{_proxiedRequest};
            $method     = $self->{_proxiedMethod};
            $relaystate = $self->{_proxiedRelayState};
            $artifact   = $self->{_proxiedArtifact};
        }
        else {
            ( $request, $response, $method, $relaystate, $artifact ) =
              $self->checkMessage( $url, $request_method, $content_type );
        }

        # Create Login object
        my $login = $self->createLogin($server);

        # Ignore signature verification
        $self->disableSignatureVerification($login);

        # Process the request or use IDP initiated mode
        if ( $request or $idp_initiated ) {

            # Load Session and Identity if they exist
            my $session  = $self->{sessionInfo}->{_lassoSessionDump};
            my $identity = $self->{sessionInfo}->{_lassoIdentityDump};

            if ($session) {
                unless ( $self->setSessionFromDump( $login, $session ) ) {
                    $self->lmLog( "Unable to load Lasso Session", 'error' );
                    return PE_SAML_SSO_ERROR;
                }
                $self->lmLog( "Lasso Session loaded", 'debug' );
            }

            if ($identity) {
                unless ( $self->setIdentityFromDump( $login, $identity ) ) {
                    $self->lmLog( "Unable to load Lasso Identity", 'error' );
                    return PE_SAML_SSO_ERROR;
                }
                $self->lmLog( "Lasso Identity loaded", 'debug' );
            }

            my $result;

            # Create fake request if IDP initiated mode
            if ($idp_initiated) {

                # Need sp or spConfKey parameter
                unless ( $idp_initiated_sp or $idp_initiated_spConfKey ) {
                    $self->lmLog(
"sp or spConfKey parameter needed to make IDP initiated SSO",
                        'error'
                    );
                    return PE_SAML_SSO_ERROR;
                }

                unless ($idp_initiated_sp) {

                    # Get SP from spConfKey
                    foreach ( keys %{ $self->{_spList} } ) {
                        if ( $self->{_spList}->{$_}->{confKey} eq
                            $idp_initiated_spConfKey )
                        {
                            $idp_initiated_sp = $_;
                            last;
                        }
                    }
                }
                else {
                    unless ( defined $self->{_spList}->{$idp_initiated_sp} ) {
                        $self->lmLog( "SP $idp_initiated_sp not known",
                            'error' );
                        return PE_SAML_UNKNOWN_ENTITY;
                    }
                    $idp_initiated_spConfKey =
                      $self->{_spList}->{$idp_initiated_sp}->{confKey};
                }

                # Check if IDP Initiated SSO is allowed
                unless (
                    $self->{samlSPMetaDataOptions}->{$idp_initiated_spConfKey}
                    ->{samlSPMetaDataOptionsEnableIDPInitiatedURL} )
                {
                    $self->lmLog(
"IDP Initiated SSO not allowed for SP $idp_initiated_spConfKey",
                        'error'
                    );
                    return PE_SAML_SSO_ERROR;
                }

                $result =
                  $self->initIdpInitiatedAuthnRequest( $login,
                    $idp_initiated_sp );
                unless ($result) {
                    $self->lmLog(
"SSO: Fail to init IDP Initiated authentication request",
                        'error'
                    );
                    return PE_SAML_SSO_ERROR;
                }

                # Force NameID Format
                my $nameIDFormatKey =
                  $self->{samlSPMetaDataOptions}->{$idp_initiated_spConfKey}
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
                $self->lmLog( "SSO: Fail to process authentication request",
                    'error' );
                return PE_SAML_SSO_ERROR;
            }

            # Get SP entityID
            my $sp = $request ? $login->remote_providerID() : $idp_initiated_sp;

            $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

            # SP conf key
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->lmLog( "$sp do not match any SP in configuration",
                    'error' );
                return PE_SAML_UNKNOWN_ENTITY;
            }

            $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

            # Do we check signature?
            my $checkSSOMessageSignature =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
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

            # Force AllowCreate to TRUE for transient/persistent NameIDPolicy
            if ( $login->request()->NameIDPolicy ) {
                my $nif = $login->request()->NameIDPolicy->Format();
                if (   $nif eq $self->getNameIDFormat("transient")
                    or $nif eq $self->getNameIDFormat("persistent") )
                {
                    $self->lmLog( "Force AllowCreate flag in NameIDPolicy",
                        'debug' );
                    eval { $login->request()->NameIDPolicy()->AllowCreate(1); };
                }
            }

            # Validate request
            unless ( $self->validateRequestMsg( $login, 1, 1 ) ) {
                $self->lmLog( "Unable to validate SSO request message",
                    'error' );
                return PE_SAML_SSO_ERROR;
            }

            $self->lmLog( "SSO: authentication request is valid", 'debug' );

            # Get ForceAuthn flag
            my $force_authn;

            eval { $force_authn = $login->request()->ForceAuthn(); };
            if ($@) {
                $self->lmLog( "Unable to get ForceAuthn flag, set it to false",
                    'warn' );
                $force_authn = 0;
            }

            $self->lmLog( "Found ForceAuthn flag with value $force_authn",
                'debug' );

            # Get ForceAuthn sessions for this session_id
            my $moduleOptions = $self->{samlStorageOptions} || {};
            $moduleOptions->{backend} = $self->{samlStorage};
            my $module = "Lemonldap::NG::Common::Apache::Session";

            my $forceAuthn_sessions =
              $module->searchOn( $moduleOptions, "_saml_id", $session_id );

            my $forceAuthn_session;
            my $forceAuthnSessionInfo;

            if (
                my @forceAuthn_sessions_keys =
                keys %$forceAuthn_sessions
              )
            {

                # Warning if more than one session found
                if ( $#forceAuthn_sessions_keys > 0 ) {
                    $self->lmLog(
"More than one ForceAuthn session found for session $session_id",
                        'warn'
                    );
                }

                # Take the first session
                $forceAuthn_session = shift @forceAuthn_sessions_keys;

                # Get session
                $self->lmLog(
"Retrieve ForceAuthn session $forceAuthn_session for session $session_id",
                    'debug'
                );

                $forceAuthnSessionInfo =
                  $self->getSamlSession($forceAuthn_session);

                # Check forceAuthn flag for current SP
                if ( $forceAuthnSessionInfo->data->{$spConfKey} ) {

                    $self->lmLog(
"User was already forced to reauthenticate for SP $spConfKey",
                        'debug'
                    );
                    $force_authn = 1;
                }
            }
            else {
                $self->lmLog(
                    "No ForceAuthn session found for session $session_id",
                    'debug' );
            }

            # Force authentication if flag is on, or previous flag still active
            if ($force_authn) {

                # Store flag for further requests
                $forceAuthnSessionInfo =
                  $self->getSamlSession($forceAuthn_session);
                $forceAuthnSessionInfo->update( { $spConfKey => 1 } );

                unless ($forceAuthn_session) {
                    my $forceInfos;
                    $forceInfos->{'_type'}    = "forceAuthn";
                    $forceInfos->{'_saml_id'} = $session_id;
                    $forceInfos->{'_utime'}   = $time;
                    $forceAuthnSessionInfo->update($forceInfos);
                    $forceAuthn_session = $forceAuthnSessionInfo->id;
                    $self->lmLog(
                        "Create ForceAuthn session $forceAuthn_session",
                        'debug' );
                }

                $self->lmLog(
"Set ForceAuthn flag for SP $spConfKey in ForceAuthn session $forceAuthn_session",
                    'debug'
                );

                # Replay authentication process
                $self->{updateSession} = 1;
                $self->{error}         = $self->_subProcess(
                    qw(issuerDBInit authInit issuerForUnAuthUser extractFormInfo
                      userDBInit getUser setAuthSessionInfo setSessionInfo
                      setMacros setGroups setPersistentSessionInfo
                      setLocalGroups authenticate store authFinish)
                );

                # Return error if any
                return $self->{error} if $self->{error} > 0;

                # Else remove flag
                $forceAuthnSessionInfo =
                  $self->getSamlSession($forceAuthn_session);
                $forceAuthnSessionInfo->update( { $spConfKey => 0 } );

                $self->lmLog(
"Unset ForceAuthn flag for SP $spConfKey in ForceAuthn session $forceAuthn_session",
                    'debug'
                );
            }

            # Check Destination (only in non proxy mode)
            unless ( $self->{_proxiedRequest} ) {
                return PE_SAML_DESTINATION_ERROR
                  unless ( $self->checkDestination( $login->request, $url ) );
            }

            # Map authenticationLevel with SAML2 authentication context
            my $authenticationLevel =
              $self->{sessionInfo}->{authenticationLevel};

            $authn_context =
              $self->authnLevel2authnContext($authenticationLevel);

            $self->lmLog( "Authentication context is $authn_context", 'debug' );

            # Get SP options notOnOrAfterTimeout
            my $notOnOrAfterTimeout =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsNotOnOrAfterTimeout};

            # Build Assertion
            unless (
                $self->buildAssertion(
                    $login, $authn_context, $notOnOrAfterTimeout
                )
              )
            {
                $self->lmLog( "Unable to build assertion", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            $self->lmLog( "SSO: assertion is built", 'debug' );

            # Get default NameID Format from configuration
            # Set to "email" if no value in configuration
            my $nameIDFormatKey =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsNameIDFormat} || "email";
            my $nameIDFormat;

            # Check NameID Policy in request
            if ( $login->request()->NameIDPolicy ) {
                $nameIDFormat = $login->request()->NameIDPolicy->Format();
                $self->lmLog( "Get NameID format $nameIDFormat from request",
                    'debug' );
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
              $self->{ $nameIDFormatConfiguration->{$nameIDFormat} };

            # Override default NameID Mapping
            if ( $self->{samlSPMetaDataOptions}->{$spConfKey}
                ->{samlSPMetaDataOptionsNameIDSessionKey} )
            {
                $nameIDSessionKey =
                  $self->{samlSPMetaDataOptions}->{$spConfKey}
                  ->{samlSPMetaDataOptionsNameIDSessionKey};
            }

            my $nameIDContent;
            if ( defined $self->{sessionInfo}->{$nameIDSessionKey} ) {
                $nameIDContent =
                  $self->getFirstValue(
                    $self->{sessionInfo}->{$nameIDSessionKey} );
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

            $self->lmLog( "NameID Format is " . $login->nameIdentifier->Format,
                'debug' );
            $self->lmLog(
                "NameID Content is " . $login->nameIdentifier->content,
                'debug' );

            # Push mandatory attributes
            my @attributes;

            foreach (
                keys %{ $self->{samlSPMetaDataExportedAttributes}->{$spConfKey}
                } )
            {

                # Extract fields from exportedAttr value
                my ( $mandatory, $name, $format, $friendly_name ) =
                  split( /;/,
                    $self->{samlSPMetaDataExportedAttributes}->{$spConfKey}
                      ->{$_} );

                # Name is required
                next unless $name;

                # Do not send attribute if not mandatory
                unless ($mandatory) {
                    $self->lmLog( "SAML2 attribute $name is not mandatory",
                        'debug' );
                    next;
                }

                # Error if corresponding attribute is not in user session
                my $value = $self->{sessionInfo}->{$_};
                unless ( defined $value ) {
                    $self->lmLog(
"Session key $_ is required to set SAML $name attribute",
                        'error'
                    );
                    return PE_SAML_SSO_ERROR;
                }

                $self->lmLog(
                    "SAML2 attribute $name will be set with $_ session key",
                    'debug' );

                # SAML2 attribute
                my $attribute =
                  $self->createAttribute( $name, $format, $friendly_name );

                unless ($attribute) {
                    $self->lmLog( "Unable to create a new SAML attribute",
                        'error' );
                    return PE_SAML_SSO_ERROR;
                }

                # Set attribute value(s)
                my @values = split $self->{multiValuesSeparator}, $value;
                my @saml2values;

                foreach (@values) {

                    # SAML2 attribute value
                    my $saml2value = $self->createAttributeValue( $_,
                        $self->{samlSPMetaDataOptions}->{$spConfKey}
                          ->{samlSPMetaDataOptionsForceUTF8} );

                    unless ($saml2value) {
                        $self->lmLog(
                            "Unable to create a new SAML attribute value",
                            'error' );
                        $self->checkLassoError($@);
                        return PE_SAML_SSO_ERROR;
                    }

                    push @saml2values, $saml2value;

                    $self->lmLog( "Push $_ in SAML attribute $name", 'debug' );

                }

                $attribute->AttributeValue(@saml2values);

                # Push attribute in attribute list
                push @attributes, $attribute;

            }

            # Get response assertion
            my @response_assertions = $login->response->Assertion;

            unless ( $response_assertions[0] ) {
                $self->lmLog( "Unable to get response assertion", 'error' );
                return PE_SAML_SSO_ERROR;
            }

            # Set subject NameID
            $response_assertions[0]
              ->set_subject_name_id( $login->nameIdentifier );

            # Set basic conditions
            my $oneTimeUse =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsOneTimeUse};

            my $conditionNotOnOrAfter = $notOnOrAfterTimeout || "86400";
            eval {
                $response_assertions[0]
                  ->set_basic_conditions( 60, $conditionNotOnOrAfter,
                    $oneTimeUse );
            };
            if ($@) {
                $self->lmLog( "Basic conditions not set: $@", 'debug' );
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
            # sessionIndex is the encrypted session_id
            my $sessionIndex = $self->{cipher}->encrypt($session_id);
            $authn_statements[0]->SessionIndex($sessionIndex);

            $self->lmLog(
                "Set sessionIndex $sessionIndex (encrypted from $session_id)",
                'debug' );

            # Set SessionNotOnOrAfter
            my $sessionNotOnOrAfterTimeout =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSessionNotOnOrAfterTimeout};
            $sessionNotOnOrAfterTimeout ||= $self->{timeout};
            my $timeout             = $time + $sessionNotOnOrAfterTimeout;
            my $sessionNotOnOrAfter = $self->timestamp2samldate($timeout);
            $authn_statements[0]->SessionNotOnOrAfter($sessionNotOnOrAfter);

            $self->lmLog( "Set sessionNotOnOrAfter $sessionNotOnOrAfter",
                'debug' );

            # Register AuthnStatement in assertion
            $response_assertions[0]->AuthnStatement(@authn_statements);

            # Set response assertion
            $login->response->Assertion(@response_assertions);

            # Signature
            my $signSSOMessage =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSignSSOMessage};

            if ( $signSSOMessage == 0 ) {
                $self->lmLog( "SSO response will not be signed", 'debug' );
                $self->disableSignature($login);
            }
            elsif ( $signSSOMessage == 1 ) {
                $self->lmLog( "SSO response will be signed", 'debug' );
                $self->forceSignature($login);
            }
            else {
                $self->lmLog( "SSO response signature according to metadata",
                    'debug' );
            }

            # log that a SAML authn response is build
            my $user = $self->{sessionInfo}->{ $self->{whatToTrace} };
            my $nameIDLog;
            foreach my $format (qw(persistent transient)) {
                if ( $login->nameIdentifier->Format eq
                    $self->getNameIDFormat($format) )
                {
                    $nameIDLog =
                      " with $format NameID " . $login->nameIdentifier->content;
                    last;
                }
            }
            $self->_sub( 'userNotice',
"SAML authentication response sent to SAML SP $spConfKey for $user$nameIDLog"
            );

            # Build SAML response
            $protocolProfile = $login->protocolProfile();

            # Artifact
            if ( $protocolProfile ==
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_BRWS_ART )
            {

                # Choose method
                $artifact_method = $self->getHttpMethod("artifact-get")
                  if ( $method == $self->getHttpMethod("redirect")
                    || $method == $self->getHttpMethod("artifact-get") );
                $artifact_method = $self->getHttpMethod("artifact-post")
                  if ( $method == $self->getHttpMethod("post")
                    || $method == $self->getHttpMethod("artifact-post") );

                # Build artifact message
                unless ( $self->buildArtifactMsg( $login, $artifact_method ) ) {
                    $self->lmLog(
                        "Unable to build SSO artifact response message",
                        'error' );
                    return PE_SAML_ART_ERROR;
                }

                $self->lmLog( "SSO: artifact response is built", 'debug' );

                # Get artifact ID and Content, and store them
                my $artifact_id      = $login->get_artifact;
                my $artifact_message = $login->get_artifact_message;

                $self->storeArtifact( $artifact_id, $artifact_message,
                    $session_id );
            }

            # No artifact
            else {

                unless ( $self->buildAuthnResponseMsg($login) ) {
                    $self->lmLog( "Unable to build SSO response message",
                        'error' );
                    return PE_SAML_SSO_ERROR;
                }

                $self->lmLog( "SSO: authentication response is built",
                    'debug' );

            }

            # Save Identity and Session
            if ( $login->is_identity_dirty ) {

                # Update session
                $self->lmLog( "Save Lasso identity in session", 'debug' );
                $self->updatePersistentSession(
                    { _lassoIdentityDump => $login->get_identity->dump },
                    undef, $session_id );
            }

            if ( $login->is_session_dirty ) {
                $self->lmLog( "Save Lasso session in session", 'debug' );
                $self->updateSession(
                    { _lassoSessionDump => $login->get_session->dump },
                    $session_id );
            }

            # Keep SAML elements for later queries
            my $nameid = $login->nameIdentifier;

            $self->lmLog(
                "Store NameID "
                  . $nameid->dump
                  . " and SessionIndex $sessionIndex for session $session_id",
                'debug'
            );

            my $samlSessionInfo = $self->getSamlSession();

            return PE_SAML_SESSION_ERROR unless $samlSessionInfo;

            my $infos;

            $infos->{type}          = 'saml';           # Session type
            $infos->{_utime}        = $time;            # Creation time
            $infos->{_saml_id}      = $session_id;      # SSO session id
            $infos->{_nameID}       = $nameid->dump;    # SAML NameID
            $infos->{_sessionIndex} = $sessionIndex;    # SAML SessionIndex

            $samlSessionInfo->update($infos);

            my $saml_session_id = $samlSessionInfo->id;

            $self->lmLog(
                "Link session $session_id to SAML session $saml_session_id",
                'debug' );

            # Send SSO Response

            # Register IDP in Common Domain Cookie if needed
            if (    $self->{samlCommonDomainCookieActivation}
                and $self->{samlCommonDomainCookieWriter} )
            {
                my $cdc_idp = $self->getMetaDataURL( "samlEntityID", 0, 1 );

                $self->lmLog(
                    "Will register IDP $cdc_idp in Common Domain Cookie",
                    'debug' );

                # Redirection to CDC Writer page in a hidden iframe
                my $cdc_writer_url = $self->{samlCommonDomainCookieWriter};
                $cdc_writer_url .= (
                    $self->{samlCommonDomainCookieWriter} =~ /\?/
                    ? '&idp=' . $cdc_idp
                    : '?url=' . $cdc_idp
                );

                my $cdc_iframe =
                    "<iframe src=\"$cdc_writer_url\""
                  . " alt=\"Common Dommain Cookie\" marginwidth=\"0\""
                  . " marginheight=\"0\" scrolling=\"no\" style=\"border: none;display: hidden;margin: 0\""
                  . " width=\"0\" height=\"0\" frameborder=\"0\">"
                  . "</iframe>";

                $self->info( "<h3>" . $self->msg(PM_CDC_WRITER) . "</h3>" );

                $self->info($cdc_iframe);
            }

            # HTTP-REDIRECT
            if ( $protocolProfile eq
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_REDIRECT
                or $artifact_method == $self->getHttpMethod("artifact-get") )
            {

                # Redirect user to response URL
                my $sso_url = $login->msg_url;
                $self->lmLog( "Redirect user to $sso_url", 'debug' );

                $self->{urldc} = $sso_url;

                return $self->_subProcess(qw(autoRedirect));
            }

            # HTTP-POST
            if ( $protocolProfile eq
                Lasso::Constants::LOGIN_PROTOCOL_PROFILE_BRWS_POST
                or $artifact_method == $self->getHttpMethod("artifact-post") )
            {

                # Use autosubmit form
                my $sso_url  = $login->msg_url;
                my $sso_body = $login->msg_body;

                $self->{postUrl} = $sso_url;

                if ( $artifact_method == $self->getHttpMethod("artifact-post") )
                {
                    $self->{postFields} = { 'SAMLart' => $sso_body };
                }
                else {
                    $self->{postFields} = { 'SAMLResponse' => $sso_body };
                }

                # RelayState
                $self->{postFields}->{'RelayState'} = $relaystate
                  if ($relaystate);

                return $self->_subProcess(qw(autoPost));
            }

        }

        elsif ($response) {
            $self->lmLog(
                "Authentication responses are not managed by this module",
                'debug' );
            return PE_OK;
        }

        else {

            # No request or response
            # This should not happen
            $self->lmLog( "No request or response found", 'debug' );
            return PE_OK;
        }

    }

    # 1.2. SLO
    if ( $url =~
/^(\Q$saml_slo_soap_url\E|\Q$saml_slo_soap_url_ret\E|\Q$saml_slo_get_url\E|\Q$saml_slo_get_url_ret\E|\Q$saml_slo_post_url\E|\Q$saml_slo_post_url_ret\E)$/io
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

        if ($request) {

            # Process logout request
            unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                $self->lmLog( "SLO: Fail to process logout request", 'error' );
                return PE_SAML_SLO_ERROR;
            }

            $self->lmLog( "SLO: Logout request is valid", 'debug' );

            # Load Session and Identity if they exist
            my $session  = $self->{sessionInfo}->{_lassoSessionDump};
            my $identity = $self->{sessionInfo}->{_lassoIdentityDump};

            if ($session) {
                unless ( $self->setSessionFromDump( $logout, $session ) ) {
                    $self->lmLog( "Unable to load Lasso Session", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                $self->lmLog( "Lasso Session loaded", 'debug' );
            }

            if ($identity) {
                unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
                    $self->lmLog( "Unable to load Lasso Identity", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                $self->lmLog( "Lasso Identity loaded", 'debug' );
            }

            # Get SP entityID
            my $sp = $logout->remote_providerID();

            $self->lmLog( "Found entityID $sp in SAML message", 'debug' );

            # SP conf key
            my $spConfKey = $self->{_spList}->{$sp}->{confKey};

            unless ($spConfKey) {
                $self->lmLog( "$sp do not match any SP in configuration",
                    'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            $self->lmLog( "$sp match $spConfKey SP in configuration", 'debug' );

            # Do we check signature?
            my $checkSLOMessageSignature =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsCheckSLOMessageSignature};

            if ($checkSLOMessageSignature) {

                $self->forceSignatureVerification($logout);

                unless ( $self->processLogoutRequestMsg( $logout, $request ) ) {
                    $self->lmLog( "Signature is not valid", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
                else {
                    $self->lmLog( "Signature is valid", 'debug' );
                }
            }
            else {
                $self->lmLog( "Message signature will not be checked",
                    'debug' );
            }

            # Check Destination
            return $self->sendSLOErrorResponse( $logout, $method )
              unless ( $self->checkDestination( $logout->request, $url ) );

            # Get session index
            my $session_index;
            eval { $session_index = $logout->request()->SessionIndex; };

            # SLO requests without session index are not accepted
            if ( $@ or !defined $session_index ) {
                $self->lmLog(
                    "No session index in SLO request from $spConfKey SP",
                    'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Validate request if no previous error
            unless ( $self->validateLogoutRequest($logout) ) {
                $self->lmLog( "SLO request is not valid", 'error' );
                return $self->sendSLOErrorResponse( $logout, $method );
            }

            # Set RelayState
            if ($relaystate) {
                $logout->msg_relayState($relaystate);
                $self->lmLog( "Set $relaystate in RelayState", 'debug' );
            }

            # Create SLO status session and get ID
            my $sloStatusSessionInfo = $self->getSamlSession();

            my $sloInfos;
            $sloInfos->{type}    = 'sloStatus';
            $sloInfos->{_utime}  = time;
            $sloInfos->{_logout} = $logout->dump;
            $sloInfos->{_session} =
              $logout->get_session() ? $logout->get_session()->dump : "";
            $sloInfos->{_method} = $method;
            $sloStatusSessionInfo->update($sloInfos);
            my $relayID = $sloStatusSessionInfo->id;

            # Prepare logout on all others SP
            my $provider_nb =
              $self->sendLogoutRequestToProviders( $logout, $relayID );

            # Decrypt session index
            my $local_session_id = $self->{cipher}->decrypt($session_index);

            $self->lmLog(
"Get session id $local_session_id (decrypted from $session_index)",
                'debug'
            );

            my $user = $self->{sessionInfo}->{user};
            my $local_session = $self->getApacheSession( $local_session_id, 1 );

            # Close SAML sessions
            unless ( $self->deleteSAMLSecondarySessions($local_session_id) ) {
                $self->lmLog( "Fail to delete SAML sessions", 'error' );
            }

            # Close local session
            unless ( $self->_deleteSession($local_session) ) {
                $self->lmLog(
                    "Fail to delete session $local_session_id for user $user",
                    'error' );
            }

            # Signature
            my $signSLOMessage =
              $self->{samlSPMetaDataOptions}->{$spConfKey}
              ->{samlSPMetaDataOptionsSignSLOMessage};

            unless ($signSLOMessage) {
                $self->lmLog( "Do not sign this SLO response", 'debug' );
                return $self->sendSLOErrorResponse( $logout, $method )
                  unless ( $self->disableSignature($logout) );
            }

            # If no waiting SP, return directly SLO response
            unless ($provider_nb) {
                if (
                    my $tmp = $self->sendLogoutResponseToServiceProvider(
                        $logout, $method
                    )
                  )
                {
                    return $tmp;
                }
                else {
                    $self->lmLog( "Fail to send SLO response", 'error' );
                    return $self->sendSLOErrorResponse( $logout, $method );
                }
            }

            # Else build SLO status relay URL and display info
            else {
                $self->{urldc} =
                  $self->{portal} . '/saml/relaySingleLogoutTermination';
                $self->setHiddenFormValue( 'relay', $relayID );
                return PE_INFO;
            }

        }

        elsif ($response) {

            # No SLO response should be here
            # else it means SSO session was not closed
            $self->lmLog(
                "SLO response found on an active SSO session, ignoring it",
                'debug' );
            return PE_OK;
        }

        else {

            # No request or response
            # This should not happen
            $self->lmLog( "No request or response found", 'debug' );
            return PE_OK;
        }

    }

    return PE_OK;
}

## @apmethod int issuerLogout()
# Send logout to SP when logout is initiated by IDP
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    my $self = shift;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Close SAML sessions
    unless ( $self->deleteSAMLSecondarySessions($session_id) ) {
        $self->lmLog( "Fail to delete SAML sessions", 'error' );
    }

    # Create Logout object
    my $logout = $self->createLogout( $self->{_lassoServer} );

    # Load Session and Identity if they exist
    my $session  = $self->{sessionInfo}->{_lassoSessionDump};
    my $identity = $self->{sessionInfo}->{_lassoIdentityDump};

    if ($session) {
        unless ( $self->setSessionFromDump( $logout, $session ) ) {
            $self->lmLog( "Unable to load Lasso Session", 'error' );
            return PE_SAML_SLO_ERROR;
        }
        $self->lmLog( "Lasso Session loaded", 'debug' );
    }

    # No need to initiate logout requests on SP, if no SAML session is
    # available into the session.
    else {
        return PE_OK;
    }

    if ($identity) {
        unless ( $self->setIdentityFromDump( $logout, $identity ) ) {
            $self->lmLog( "Unable to load Lasso Identity", 'error' );
            return PE_SAML_SLO_ERROR;
        }
        $self->lmLog( "Lasso Identity loaded", 'debug' );
    }

    # Proceed to logout on all others SP.
    # Verify that logout response is correctly sent. If we have to wait for
    # providers during HTTP-REDIRECT process, return PE_INFO to notify to wait
    # for them.
    # Redirect on logout page when all is done.
    if ( $self->sendLogoutRequestToProviders($logout) ) {
        $self->{urldc} = $ENV{SCRIPT_NAME} . "?logout=1";
        return PE_INFO;
    }

    return PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBSAML - SAML IssuerDB for LemonLDAP::NG

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;

  my $portal = Lemonldap::NG::Portal::SharedConf->new({
      issuerDB => SAML,
  });

=head1 DESCRIPTION

SAML IssuerDB for LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

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

=item Copyright (C) 2009-2012 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2009-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
