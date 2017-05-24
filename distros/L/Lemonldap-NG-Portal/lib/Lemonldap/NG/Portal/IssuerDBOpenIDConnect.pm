## @file
# OpenIDConnect Issuer file

## @class
# OpenIDConnect Issuer class
package Lemonldap::NG::Portal::IssuerDBOpenIDConnect;

use strict;
use Lemonldap::NG::Portal::Simple;
use String::Random qw(random_string);
use HTML::Template;
use base qw(Lemonldap::NG::Portal::_OpenIDConnect);

our $VERSION = '1.9.10';

## @method void issuerDBInit()
# Get configuration data
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;

    return PE_ERROR unless $self->loadRPs;

    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Get OIDC request
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {

    my $self = shift;

    my $issuerDBOpenIDConnectPath = $self->{issuerDBOpenIDConnectPath};
    my $authorize_uri             = $self->{oidcServiceMetaDataAuthorizeURI};
    my $token_uri                 = $self->{oidcServiceMetaDataTokenURI};
    my $userinfo_uri              = $self->{oidcServiceMetaDataUserInfoURI};
    my $jwks_uri                  = $self->{oidcServiceMetaDataJWKSURI};
    my $registration_uri          = $self->{oidcServiceMetaDataRegistrationURI};
    my $endsession_uri            = $self->{oidcServiceMetaDataEndSessionURI};
    my $checksession_uri          = $self->{oidcServiceMetaDataCheckSessionURI};
    my $issuer                    = $self->{oidcServiceMetaDataIssuer};

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # AUTHORIZE
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${authorize_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect AUTHORIZE URL",
            'debug' );

        # Get and save parameters
        my $oidc_request = {};
        foreach my $param (
            qw/response_type scope client_id state redirect_uri nonce response_mode display prompt max_age ui_locales id_token_hint login_hint acr_values request request_uri/
          )
        {
            $oidc_request->{$param} = $self->getHiddenFormValue($param)
              || $self->param($param);
            $self->lmLog(
                "OIDC request parameter $param: " . $oidc_request->{$param},
                'debug' );
            $self->setHiddenFormValue( $param, $oidc_request->{$param} );
            $ENV{ "llng_oidc_" . $param } = $oidc_request->{$param};
        }

        # Detect requested flow
        my $response_type = $oidc_request->{'response_type'};
        my $flow          = $self->getFlowType($response_type);

        unless ($flow) {
            $self->lmLog( "Unknown response type: $response_type", 'error' );
            return PE_ERROR;
        }
        $self->lmLog(
            "OIDC $flow flow requested (response type: $response_type)",
            'debug' );

        # Extract request_uri/request parameter
        if ( $oidc_request->{'request_uri'} ) {
            my $request =
              $self->getRequestJWT( $oidc_request->{'request_uri'} );

            if ($request) {
                $oidc_request->{'request'} = $request;
            }
            else {
                $self->lmLog( "Error with Request URI resolution", 'error' );
                return PE_ERROR;
            }
        }

        if ( $oidc_request->{'request'} ) {

            my $request = $self->getJWTJSONData( $oidc_request->{'request'} );

            # Override OIDC parameters by request content
            foreach ( keys %$request ) {
                $self->lmLog(
"Override $_ OIDC param by value present in request parameter",
                    'debug'
                );
                $oidc_request->{$_} = $request->{$_};
                $self->setHiddenFormValue( $_, $request->{$_} );
                $ENV{ "llng_oidc_" . $_ } = $oidc_request->{$_};
            }
        }

        # State
        my $state = $oidc_request->{'state'};

        # Check redirect_uri
        my $redirect_uri = $oidc_request->{'redirect_uri'};
        unless ($redirect_uri) {
            $self->lmLog( "Redirect URI is required", 'error' );
            return PE_ERROR;
        }

        # Check display
        my $display = $oidc_request->{'display'};
        if ( $display eq "page" ) {
            $self->lmLog( "Display type page will be used", 'debug' );
        }
        else {
            $self->lmLog(
"Display type $display not supported, display type page will be used",
                'debug'
            );
        }

        # Check prompt
        my $prompt = $oidc_request->{'prompt'};
        if ( $prompt =~ /\bnone\b/ ) {
            $self->lmLog(
                "Prompt type none requested, but user needs to authenticate",
                'error' );
            $self->returnRedirectError( $redirect_uri, "login_required",
                "Prompt type none requested",
                undef, $state, ( $flow ne "authorizationcode" ) );
        }

        # Check ui_locales
        my $ui_locales = $oidc_request->{'ui_locales'};
        if ( defined $ui_locales ) {
            my $lang = join( ',', split( /\s+/, $ui_locales ) );
            $self->{lang} = $self->extract_lang($lang);
        }

        # Check login_hint
        my $login_hint = $oidc_request->{'login_hint'};
        if ( defined $login_hint ) {
            $self->{user} ||= $login_hint;
        }

        # Get RP
        if ( my $client_id = $oidc_request->{'client_id'} ) {
            my $rp = $self->getRP($client_id);
            $ENV{"llng_oidc_rp"} = $rp if $rp;
        }
    }

    # TOKEN
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${token_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect TOKEN URL",
            'debug' );

        # Check authentication
        my ( $client_id, $client_secret ) =
          $self->getEndPointAuthenticationCredentials();

        unless ( $client_id && $client_secret ) {
            $self->lmLog(
"No authentication provided to get token, or authentication type not supported",
                "error"
            );
            $self->returnJSONError("unauthorized_client");
            $self->quit;
        }

        # Verify that client_id is registered in configuration
        my $rp = $self->getRP($client_id);

        unless ($rp) {
            $self->lmLog(
                "No registered Relying Party found with client_id $client_id",
                'error' );
            $self->returnJSONError("unauthorized_client");
            $self->quit;
        }
        else {
            $self->lmLog( "Client id $client_id match RP $rp", 'debug' );
        }

        # Check client_secret
        unless ( $client_secret eq $self->{oidcRPMetaDataOptions}->{$rp}
            ->{oidcRPMetaDataOptionsClientSecret} )
        {
            $self->lmLog( "Wrong credentials", "error" );
            $self->returnJSONError("unauthorized_client");
            $self->quit;
        }

        # Get code session
        my $code = $self->param('code');

        $self->lmLog( "OpenID Connect Code: $code", 'debug' );

        my $codeSession = $self->getOpenIDConnectSession($code);

        unless ($codeSession) {
            $self->lmLog( "Unable to find OIDC session $code", "error" );
            $self->returnJSONError("invalid_grant");
            $self->quit;
        }

        # Check we have the same redirect_uri value
        unless (
            $self->param("redirect_uri") eq $codeSession->data->{redirect_uri} )
        {
            $self->lmLog(
                "Provided redirect_uri is different from "
                  . $codeSession->{redirect_uri},
                "error"
            );
            $self->returnJSONError("invalid_request");
            $codeSession->remove();
            $self->quit;
        }

        # Get user identifier
        my $apacheSession =
          $self->getApacheSession( $codeSession->data->{user_session_id}, 1 );

        unless ($apacheSession) {
            $self->lmLog(
                "Unable to find user session linked to OIDC session $code",
                "error" );
            $self->returnJSONError("invalid_request");
            $codeSession->remove();
            $self->quit;
        }

        my $user_id_attribute = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsUserIDAttr} || $self->{whatToTrace};
        my $user_id = $apacheSession->data->{$user_id_attribute};

        $self->lmLog( "Found corresponding user: $user_id", 'debug' );

        # Generate access_token
        my $accessTokenSession = $self->getOpenIDConnectSession;

        unless ($accessTokenSession) {
            $self->lmLog( "Unable to create OIDC session for access_token",
                "error" );
            $self->returnJSONError("invalid_request");
            $codeSession->remove();
            $self->quit;
        }

        # Store data in access token
        $accessTokenSession->update(
            {
                scope           => $codeSession->data->{scope},
                rp              => $rp,
                user_session_id => $apacheSession->id,
                _utime          => time,
            }
        );

        my $access_token = $accessTokenSession->id;

        $self->lmLog( "Generated access token: $access_token", 'debug' );

        # Compute hash to store in at_hash
        my $alg = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsIDTokenSignAlg};
        my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
        my $at_hash = $self->createHash( $access_token, $hash_level );

        # ID token payload
        my $id_token_exp = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsIDTokenExpiration};
        $id_token_exp += time;

        my $id_token_acr = "loa-" . $apacheSession->data->{authenticationLevel};

        my $id_token_payload_hash = {
            iss => $issuer,          # Issuer Identifier
            sub => $user_id,         # Subject Identifier
            aud => [$client_id],     # Audience
            exp => $id_token_exp,    # expiration
            iat => time,             # Issued time
            auth_time =>
              $apacheSession->data->{_lastAuthnUTime},    # Authentication time
            acr => $id_token_acr,    # Authentication Context Class Reference
            azp => $client_id,       # Authorized party
                                     # TODO amr
        };

        my $nonce = $codeSession->data->{nonce};
        $id_token_payload_hash->{nonce} = $nonce if defined $nonce;
        $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;

        # Create ID Token
        my $id_token = $self->createIDToken( $id_token_payload_hash, $rp );

        $self->lmLog( "Generated id token: $id_token", 'debug' );

        # Send token response
        my $expires_in = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsAccessTokenExpiration};

        my $token_response = {
            access_token => $access_token,
            token_type   => 'Bearer',
            expires_in   => $expires_in,
            id_token     => $id_token,
        };

        $self->returnJSON($token_response);

        $self->lmLog( "Token response sent", 'debug' );

        $codeSession->remove();
        $self->quit;

    }

    # USERINFO
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${userinfo_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect USERINFO URL",
            'debug' );

        my $access_token = $self->getEndPointAccessToken();

        unless ($access_token) {
            $self->lmLog( "Unable to get access_token", "error" );
            $self->returnBearerError( "invalid_request",
                "Access token not found in request" );
            $self->quit;
        }

        $self->lmLog( "Received Access Token $access_token", 'debug' );

        my $accessTokenSession = $self->getOpenIDConnectSession($access_token);

        unless ($accessTokenSession) {
            $self->lmLog(
                "Unable to get access token session for id $access_token",
                "error" );
            $self->returnBearerError( "invalid_token",
                "Access Token not found or expired" );
            $self->quit;
        }

        # Get access token session data
        my $scope           = $accessTokenSession->data->{scope};
        my $rp              = $accessTokenSession->data->{rp};
        my $user_session_id = $accessTokenSession->data->{user_session_id};

        my $userinfo_response =
          $self->buildUserInfoResponse( $scope, $rp, $user_session_id );

        my $userinfo_sign_alg = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsUserInfoSignAlg};

        unless ($userinfo_sign_alg) {
            $self->returnJSON($userinfo_response);
        }
        else {
            my $userinfo_jwt =
              $self->createJWT( $userinfo_response, $userinfo_sign_alg, $rp );
            print $self->header('application/jwt');
            print $userinfo_jwt;
            $self->lmLog( "Return UserInfo as JWT: $userinfo_jwt", 'debug' );
        }

        $self->lmLog( "UserInfo response sent", 'debug' );

        $self->quit;

    }

    # JWKS
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${jwks_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect JWKS URL",
            'debug' );

        my $jwks = { keys => [] };

        my $public_key_sig = $self->{oidcServicePublicKeySig};
        my $key_id_sig     = $self->{oidcServiceKeyIdSig};
        if ($public_key_sig) {
            my $key = $self->key2jwks($public_key_sig);
            $key->{kty} = "RSA";
            $key->{use} = "sig";
            $key->{kid} = $key_id_sig if $key_id_sig;
            push @{ $jwks->{keys} }, $key;
        }

        $self->returnJSON($jwks);

        $self->lmLog( "JWKS response sent", 'debug' );

        $self->quit;

    }

    # REGISTRATION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${registration_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect REGISTRATION URL",
            'debug' );

        # TODO: check Initial Access Token

        # Specific message to allow DOS detection
        my $source_ip = $self->ipAddr;
        $self->lmLog( "OpenID Connect Registration request from $source_ip",
            'warn' );

        # Check dynamic registration is allowed
        unless ( $self->{oidcServiceAllowDynamicRegistration} ) {
            $self->lmLog( "Dynamic registration is not allowed", 'error' );
            $self->returnJSONError( 'server_error',
                'Dynamic registration is not allowed' );
            $self->quit;
        }

        # Get client metadata
        my $client_metadata_json = $self->param('POSTDATA');

        $self->lmLog( "Client metadata received: $client_metadata_json",
            'debug' );

        my $client_metadata       = $self->decodeJSON($client_metadata_json);
        my $registration_response = {};

        # Check redirect_uris
        unless ( $client_metadata->{redirect_uris} ) {
            $self->lmLog( "Field redirect_uris is mandatory", 'error' );
            $self->returnJSONError( 'invalid_client_metadata',
                'Field redirect_uris is mandatory' );
            $self->quit;
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
        my $conf = $self->__lmConf->getConf();

        $conf->{cfgAuthor}   = "OpenID Connect Registration ($client_name)";
        $conf->{cfgAuthorIP} = $source_ip;

        $conf->{oidcRPMetaDataExportedVars}->{$rp} = {};
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsClientID}
          = $client_id;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsClientSecret} = $client_secret;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsDisplayName} = $client_name;
        $conf->{oidcRPMetaDataOptions}->{$rp}->{oidcRPMetaDataOptionsIcon} =
          $logo_uri;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsIDTokenSignAlg} =
          $id_token_signed_response_alg;
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsRedirectUris} = join( ' ', @$redirect_uris );
        $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsUserInfoSignAlg} =
          $userinfo_signed_response_alg
          if defined $userinfo_signed_response_alg;

        if ( $self->__lmConf->saveConf($conf) ) {

            # Reload RP list
            $self->loadRPs(1);

            # Send registration response
            $registration_response->{'client_id'}     = $client_id;
            $registration_response->{'client_secret'} = $client_secret;
            $registration_response->{'client_id_issued_at'} =
              $registration_time;
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
            $self->lmLog(
                "Configuration not saved: $Lemonldap::NG::Common::Conf::msg",
                'error' );
            $self->returnJSONError( 'server_error', 'Configuration not saved' );
            $self->quit;
        }

        # TODO: return 201 HTTP code
        $self->returnJSON($registration_response);

        $self->lmLog( "Registration response sent", 'debug' );

        $self->quit;
    }

    # END SESSION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${endsession_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect END SESSION URL",
            'debug' );

        $self->lmLog( "User is already logged out", 'debug' );

        my $post_logout_redirect_uri = $self->param('post_logout_redirect_uri');
        my $state                    = $self->param('state');

        if ($post_logout_redirect_uri) {

            # Check redirect URI is allowed
            my $redirect_uri_allowed = 0;
            foreach ( keys %{ $self->{oidcRPMetaDataOptions} } ) {
                my $logout_rp     = $_;
                my $redirect_uris = $self->{oidcRPMetaDataOptions}->{$logout_rp}
                  ->{oidcRPMetaDataOptionsPostLogoutRedirectUris};

                foreach ( split( /\s+/, $redirect_uris ) ) {
                    if ( $post_logout_redirect_uri eq $_ ) {
                        $self->lmLog(
"$post_logout_redirect_uri is an allowed logout redirect URI for RP $logout_rp",
                            'debug'
                        );
                        $redirect_uri_allowed = 1;
                    }
                }
            }

            unless ($redirect_uri_allowed) {
                $self->lmLog( "$post_logout_redirect_uri is not allowed",
                    'error' );
                return PE_BADURL;
            }

            # Build Response
            my $response_url =
              $self->buildLogoutResponse( $post_logout_redirect_uri, $state );

            $self->lmLog( "Redirect user to $response_url", 'debug' );
            $self->{'urldc'} = $response_url;

            $self->_sub('autoRedirect');
        }

        return PE_LOGOUT_OK;
    }

    # CHECK SESSION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${checksession_uri}# ) {

        $self->lmLog(
            "URL $url detected as an OpenID Connect CHECK SESSION URL",
            'debug' );

        print $self->header(
            -type                        => 'text/html',
            -access_control_allow_origin => '*'
        );

        my $checksession_tpl =
          $self->getApacheHtdocsPath . "/skins/common/oidc_checksession.tpl";

        my $portalPath = $self->{portal};
        $portalPath =~ s#^https?://[^/]+/?#/#;
        $portalPath =~ s#[^/]+\.pl$##;

        my $template = HTML::Template->new( filename => $checksession_tpl );
        $template->param( "JS_CODE" => $self->getSessionManagementOPIFrameJS );
        $template->param( "SKIN_PATH" => $portalPath . "skins" );
        print $template->output;
        $self->quit();
    }

    PE_OK;
}

## @apmethod int issuerForAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {

    my $self = shift;

    my $issuerDBOpenIDConnectPath = $self->{issuerDBOpenIDConnectPath};
    my $authorize_uri             = $self->{oidcServiceMetaDataAuthorizeURI};
    my $token_uri                 = $self->{oidcServiceMetaDataTokenURI};
    my $userinfo_uri              = $self->{oidcServiceMetaDataUserInfoURI};
    my $jwks_uri                  = $self->{oidcServiceMetaDataJWKSURI};
    my $registration_uri          = $self->{oidcServiceMetaDataRegistrationURI};
    my $endsession_uri            = $self->{oidcServiceMetaDataEndSessionURI};
    my $checksession_uri          = $self->{oidcServiceMetaDataCheckSessionURI};
    my $issuer                    = $self->{oidcServiceMetaDataIssuer};

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # AUTHORIZE
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${authorize_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect AUTHORIZE URL",
            'debug' );

        # Get and save parameters
        my $oidc_request = {};
        foreach my $param (
            qw/response_type scope client_id state redirect_uri nonce response_mode display prompt max_age ui_locales id_token_hint login_hint acr_values request request_uri/
          )
        {
            $oidc_request->{$param} = $self->getHiddenFormValue($param)
              || $self->param($param);
            $self->lmLog(
                "OIDC request parameter $param: " . $oidc_request->{$param},
                'debug' );
            $self->setHiddenFormValue( $param, $oidc_request->{$param} );
        }

        # Detect requested flow
        my $response_type = $oidc_request->{'response_type'};
        my $flow          = $self->getFlowType($response_type);

        unless ($flow) {
            $self->lmLog( "Unknown response type: $response_type", 'error' );
            return PE_ERROR;
        }
        $self->lmLog(
            "OIDC $flow flow requested (response type: $response_type)",
            'debug' );

        # Extract request_uri/request parameter
        if ( $oidc_request->{'request_uri'} ) {
            my $request =
              $self->getRequestJWT( $oidc_request->{'request_uri'} );

            if ($request) {
                $oidc_request->{'request'} = $request;
            }
            else {
                $self->lmLog( "Error with Request URI resolution", 'error' );
                return PE_ERROR;
            }
        }

        if ( $oidc_request->{'request'} ) {
            my $request = $self->getJWTJSONData( $oidc_request->{'request'} );

            # Override OIDC parameters by request content
            foreach ( keys %$request ) {
                $self->lmLog(
"Override $_ OIDC param by value present in request parameter",
                    'debug'
                );
                $oidc_request->{$_} = $request->{$_};
                $self->setHiddenFormValue( $_, $request->{$_} );
            }
        }

        # Check all required parameters
        unless ( $oidc_request->{'redirect_uri'} ) {
            $self->lmLog( "Redirect URI is required", 'error' );
            return PE_ERROR;
        }
        unless ( $oidc_request->{'scope'} ) {
            $self->lmLog( "Scope is required", 'error' );
            return PE_ERROR;
        }
        unless ( $oidc_request->{'client_id'} ) {
            $self->lmLog( "Client ID is required", 'error' );
            return PE_ERROR;
        }
        if ( $flow eq "implicit" and not defined $oidc_request->{'nonce'} ) {
            $self->lmLog( "Nonce is required for implicit flow", 'error' );
            return PE_ERROR;
        }

        # Check client_id
        my $client_id = $oidc_request->{'client_id'};
        $self->lmLog( "Request from client id $client_id", 'debug' );

        # Verify that client_id is registered in configuration
        my $rp = $self->getRP($client_id);

        unless ($rp) {
            $self->lmLog(
                "No registered Relying Party found with client_id $client_id",
                'error' );
            return PE_ERROR;
        }
        else {
            $self->lmLog( "Client id $client_id match RP $rp", 'debug' );
        }

        # Check redirect_uri
        my $redirect_uri  = $oidc_request->{'redirect_uri'};
        my $redirect_uris = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsRedirectUris};

        if ($redirect_uris) {
            my $redirect_uri_allowed = 0;
            foreach ( split( /\s+/, $redirect_uris ) ) {
                $redirect_uri_allowed = 1 if $redirect_uri eq $_;
            }
            unless ($redirect_uri_allowed) {
                $self->lmLog( "Redirect URI $redirect_uri not allowed",
                    'error' );
                return PE_BADURL;
            }
        }

        # Check if flow is allowed
        if ( $flow eq "authorizationcode"
            and not $self->{oidcServiceAllowAuthorizationCodeFlow} )
        {
            $self->lmLog( "Authorization code flow is not allowed", 'error' );
            $self->returnRedirectError(
                $oidc_request->{'redirect_uri'},
                "server_error", "Authorization code flow not allowed",
                undef, $oidc_request->{'state'}, 0
            );
        }
        if ( $flow eq "implicit" and not $self->{oidcServiceAllowImplicitFlow} )
        {
            $self->lmLog( "Implicit flow is not allowed", 'error' );
            $self->returnRedirectError(
                $oidc_request->{'redirect_uri'},
                "server_error", "Implicit flow not allowed",
                undef, $oidc_request->{'state'}, 1
            );
        }
        if ( $flow eq "hybrid" and not $self->{oidcServiceAllowHybridFlow} ) {
            $self->lmLog( "Hybrid flow is not allowed", 'error' );
            $self->returnRedirectError(
                $oidc_request->{'redirect_uri'},
                "server_error", "Hybrid flow not allowed",
                undef, $oidc_request->{'state'}, 1
            );
        }

        # Check if user needs to be reauthenticated
        my $reauthentication = 0;
        my $prompt           = $oidc_request->{'prompt'};
        if ( $prompt =~ /\blogin\b/ ) {
            $self->lmLog(
"Reauthentication requested by Relying Party in prompt parameter",
                'debug'
            );
            $reauthentication = 1;
        }

        my $max_age         = $oidc_request->{'max_age'};
        my $_lastAuthnUTime = $self->{sessionInfo}->{_lastAuthnUTime};
        if ( $max_age && time > $_lastAuthnUTime + $max_age ) {
            $self->lmLog(
"Reauthentication forced cause authentication time ($_lastAuthnUTime) is too old (>$max_age s)",
                'debug'
            );
            $reauthentication = 1;
        }

        if ($reauthentication) {

            # Replay authentication process
            $self->{updateSession} = 1;
            $self->{error}         = $self->_subProcess(
                qw(issuerDBInit authInit issuerForUnAuthUser extractFormInfo
                  userDBInit getUser setAuthSessionInfo setSessionInfo
                  setMacros setGroups setPersistentSessionInfo
                  setLocalGroups authenticate store authFinish)
            );

            # Return error if any
            return $self->{error} if ( $self->{error} > 0 );

            # Disable further reauthentication
            $prompt =~ s/\blogin\b//;
            $self->setHiddenFormValue( 'prompt', $prompt );

            # Update session_id
            $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};
        }

        # Check openid scope
        unless ( $oidc_request->{'scope'} =~ /\bopenid\b/ ) {
            $self->lmLog( "No openid scope found", 'debug' );

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
                $self->lmLog( "Request JWT signature could not be verified",
                    'error' );
                return PE_ERROR;
            }
            else {
                $self->lmLog( "Request JWT signature verified", 'debug' );
            }
        }

        # Check id_token_hint
        my $id_token_hint = $oidc_request->{'id_token_hint'};
        if ($id_token_hint) {

            $self->lmLog( "Check sub of ID Token $id_token_hint", 'debug' );

            # Check that id_token_hint sub match current user
            my $sub               = $self->getIDTokenSub($id_token_hint);
            my $user_id_attribute = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsUserIDAttr} || $self->{whatToTrace};
            my $user_id = $self->{sessionInfo}->{$user_id_attribute};
            unless ( $sub eq $user_id ) {
                $self->lmLog(
                    "ID Token hint sub $sub do not match user $user_id",
                    'error' );
                $self->returnRedirectError(
                    $oidc_request->{'redirect_uri'},
                    "invalid_request",
                    "current user do not match id_token_hint sub",
                    undef,
                    $oidc_request->{'state'},
                    ( $flow ne "authorizationcode" )
                );
            }
            else {
                $self->lmLog( "ID Token hint sub $sub match current user",
                    'debug' );
            }
        }

        # Obtain consent
        my $bypassConsent = $self->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsBypassConsent};
        if ($bypassConsent) {
            $self->lmLog(
                "Consent is disabled for RP $rp, user will not be prompted",
                'debug' );
        }
        else {
            my $ask_for_consent = 1;
            if (    $self->{sessionInfo}->{"_oidc_consent_time_$rp"}
                and $self->{sessionInfo}->{"_oidc_consent_scope_$rp"} )
            {
                $ask_for_consent = 0;
                my $consent_time =
                  $self->{sessionInfo}->{"_oidc_consent_time_$rp"};
                my $consent_scope =
                  $self->{sessionInfo}->{"_oidc_consent_scope_$rp"};

                $self->lmLog(
"Consent already given for Relying Party $rp (time: $consent_time, scope: $consent_scope)",
                    'debug'
                );

                # Check accepted scope
                foreach my $requested_scope (
                    split( /\s+/, $oidc_request->{'scope'} ) )
                {
                    if ( $consent_scope =~ /\b$requested_scope\b/ ) {
                        $self->lmLog( "Scope $requested_scope already accepted",
                            'debug' );
                    }
                    else {
                        $self->lmLog(
"Scope $requested_scope was not previously accepted",
                            'debug'
                        );
                        $ask_for_consent = 1;
                        last;
                    }
                }

                # Check prompt parameter
                $ask_for_consent = 1 if ( $prompt =~ /\bconsent\b/ );
            }
            if ($ask_for_consent) {
                if ( $self->param('confirm') == 1 ) {
                    $self->updatePersistentSession(
                        { "_oidc_consent_time_$rp" => time } );
                    $self->updatePersistentSession(
                        {
                            "_oidc_consent_scope_$rp" =>
                              $oidc_request->{'scope'}
                        }
                    );
                    $self->lmLog( "Consent given for Relying Party $rp",
                        'debug' );
                }
                elsif ( $self->param('confirm') == -1 ) {
                    $self->lmLog( "User refused consent for Relying party $rp",
                        'debug' );
                    $self->returnRedirectError(
                        $oidc_request->{'redirect_uri'},
                        "consent_required",
                        "consent not given",
                        undef,
                        $oidc_request->{'state'},
                        ( $flow ne "authorizationcode" )
                    );
                }
                else {
                    $self->lmLog( "Obtain user consent for Relying Party $rp",
                        'debug' );

                    # Return error if prompt is none
                    if ( $prompt =~ /\bnone\b/ ) {
                        $self->lmLog( "Consent is needed but prompt is none",
                            'debug' );
                        $self->returnRedirectError(
                            $oidc_request->{'redirect_uri'},
                            "consent_required",
                            "consent required",
                            undef,
                            $oidc_request->{'state'},
                            ( $flow ne "authorizationcode" )
                        );
                    }

                    my $display_name = $self->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsDisplayName};
                    my $icon = $self->{oidcRPMetaDataOptions}->{$rp}
                      ->{oidcRPMetaDataOptionsIcon};
                    my $img_src;
                    my $portalPath = $self->{portal};
                    $portalPath =~ s#^https?://[^/]+/?#/#;
                    $portalPath =~ s#[^/]+\.pl$##;

                    if ($icon) {
                        $img_src =
                          ( $icon =~ m#^https?://# )
                          ? $icon
                          : $portalPath . "skins/common/" . $icon;
                    }

                    $self->info('<div class="oidc_consent_message">');
                    $self->info( '<img src="' . $img_src . '" />' ) if $img_src;
                    $self->info( '<h3>'
                          . sprintf( $self->msg(PM_OIDC_CONSENT),
                            $display_name )
                          . '</h3>' );
                    $self->info('<ul>');

                    foreach my $requested_scope (
                        split( /\s/, $oidc_request->{'scope'} ) )
                    {
                        my $message;
                        my $scope_messages = {
                            openid  => PM_OIDC_SCOPE_OPENID,
                            profile => PM_OIDC_SCOPE_PROFILE,
                            email   => PM_OIDC_SCOPE_EMAIL,
                            address => PM_OIDC_SCOPE_ADDRESS,
                            phone   => PM_OIDC_SCOPE_PHONE,
                        };
                        if ( $scope_messages->{$requested_scope} ) {
                            $message =
                              $self->msg( $scope_messages->{$requested_scope} );
                        }
                        else {
                            $message = $self->msg(PM_OIDC_SCOPE_OTHER) . " "
                              . $requested_scope;
                        }
                        $self->info("<li>$message</li>");
                    }
                    $self->info('</ul>');
                    $self->info('</div>');
                    $self->{activeTimer} = 0;
                    return PE_CONFIRM;
                }
            }
        }

        # Create session_state
        my $session_state =
          $self->createSessionState( $session_id, $client_id );

        # Authorization Code Flow
        if ( $flow eq "authorizationcode" ) {

            # Generate code
            my $codeSession = $self->getOpenIDConnectSession();
            my $code        = $codeSession->id();

            $self->lmLog( "Generated code: $code", 'debug' );

            # Store data in session
            $codeSession->update(
                {
                    redirect_uri    => $oidc_request->{'redirect_uri'},
                    scope           => $oidc_request->{'scope'},
                    user_session_id => $session_id,
                    _utime          => time,
                    nonce           => $oidc_request->{'nonce'},
                }
            );

            # Build Response
            my $response_url = $self->buildAuthorizationCodeAuthnResponse(
                $oidc_request->{'redirect_uri'},
                $code, $oidc_request->{'state'},
                $session_state
            );

            $self->lmLog( "Redirect user to $response_url", 'debug' );
            $self->{'urldc'} = $response_url;

            $self->_sub('autoRedirect');
        }

        # Implicit Flow
        if ( $flow eq "implicit" ) {

            my $access_token;
            my $at_hash;

            if ( $response_type =~ /\btoken\b/ ) {

                # Generate access_token
                my $accessTokenSession = $self->getOpenIDConnectSession;

                unless ($accessTokenSession) {
                    $self->lmLog(
                        "Unable to create OIDC session for access_token",
                        "error" );
                    $self->returnRedirectError( $oidc_request->{'redirect_uri'},
                        "server_error", undef,
                        undef, $oidc_request->{'state'}, 1 );
                }

                # Store data in access token
                $accessTokenSession->update(
                    {
                        scope           => $oidc_request->{'scope'},
                        rp              => $rp,
                        user_session_id => $session_id,
                        _utime          => time,
                    }
                );

                $access_token = $accessTokenSession->id;

                $self->lmLog( "Generated access token: $access_token",
                    'debug' );

                # Compute hash to store in at_hash
                my $alg = $self->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsIDTokenSignAlg};
                my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );
                $at_hash = $self->createHash( $access_token, $hash_level );
            }

            # ID token payload
            my $id_token_exp = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsIDTokenExpiration};
            $id_token_exp += time;

            my $authenticationLevel =
              $self->{sessionInfo}->{authenticationLevel};
            my $id_token_acr;
            foreach ( keys %{ $self->{oidcServiceMetaDataAuthnContext} } ) {
                if ( $self->{oidcServiceMetaDataAuthnContext}->{$_} eq
                    $authenticationLevel )
                {
                    $id_token_acr = $_;
                    last;
                }
            }

            my $user_id_attribute = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsUserIDAttr} || $self->{whatToTrace};
            my $user_id = $self->{sessionInfo}->{$user_id_attribute};

            my $id_token_payload_hash = {
                iss => $issuer,          # Issuer Identifier
                sub => $user_id,         # Subject Identifier
                aud => [$client_id],     # Audience
                exp => $id_token_exp,    # expiration
                iat => time,             # Issued time
                auth_time => $self->{sessionInfo}->{_lastAuthnUTime}
                ,                        # Authentication time
                azp   => $client_id,                 # Authorized party
                                                     # TODO amr
                nonce => $oidc_request->{'nonce'}    # Nonce
            };

            $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;
            $id_token_payload_hash->{'acr'} = $id_token_acr
              if $id_token_acr;

            # Create ID Token
            my $id_token = $self->createIDToken( $id_token_payload_hash, $rp );

            $self->lmLog( "Generated id token: $id_token", 'debug' );

            # Send token response
            my $expires_in = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsAccessTokenExpiration};

            # Build Response
            my $response_url = $self->buildImplicitAuthnResponse(
                $oidc_request->{'redirect_uri'},
                $access_token, $id_token, $expires_in, $oidc_request->{'state'},
                $session_state
            );

            $self->lmLog( "Redirect user to $response_url", 'debug' );
            $self->{'urldc'} = $response_url;

            $self->_sub('autoRedirect');
        }

        # Hybrid Flow
        if ( $flow eq "hybrid" ) {

            my $access_token;
            my $id_token;
            my $at_hash;
            my $c_hash;

            # Hash level
            my $alg = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsIDTokenSignAlg};
            my ($hash_level) = ( $alg =~ /(?:\w{2})(\d{3})/ );

            # Generate code
            my $codeSession = $self->getOpenIDConnectSession();
            my $code        = $codeSession->id();

            $self->lmLog( "Generated code: $code", 'debug' );

            # Store data in session
            $codeSession->update(
                {
                    redirect_uri    => $oidc_request->{'redirect_uri'},
                    scope           => $oidc_request->{'scope'},
                    user_session_id => $session_id,
                    _utime          => time,
                    nonce           => $oidc_request->{'nonce'},
                }
            );

            # Compute hash to store in c_hash
            $c_hash = $self->createHash( $code, $hash_level );

            if ( $response_type =~ /\btoken\b/ ) {

                # Generate access_token
                my $accessTokenSession = $self->getOpenIDConnectSession;

                unless ($accessTokenSession) {
                    $self->lmLog(
                        "Unable to create OIDC session for access_token",
                        "error" );
                    $self->returnRedirectError( $oidc_request->{'redirect_uri'},
                        "server_error", undef,
                        undef, $oidc_request->{'state'}, 1 );
                }

                # Store data in access token
                $accessTokenSession->update(
                    {
                        scope           => $oidc_request->{'scope'},
                        rp              => $rp,
                        user_session_id => $session_id,
                        _utime          => time,
                    }
                );

                $access_token = $accessTokenSession->id;

                $self->lmLog( "Generated access token: $access_token",
                    'debug' );

                # Compute hash to store in at_hash
                $at_hash = $self->createHash( $access_token, $hash_level );
            }

            if ( $response_type =~ /\bid_token\b/ ) {

                # ID token payload
                my $id_token_exp = $self->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsIDTokenExpiration};
                $id_token_exp += time;

                my $id_token_acr =
                  "loa-" . $self->{sessionInfo}->{authenticationLevel};

                my $user_id_attribute =
                  $self->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsUserIDAttr}
                  || $self->{whatToTrace};
                my $user_id = $self->{sessionInfo}->{$user_id_attribute};

                my $id_token_payload_hash = {
                    iss => $issuer,          # Issuer Identifier
                    sub => $user_id,         # Subject Identifier
                    aud => [$client_id],     # Audience
                    exp => $id_token_exp,    # expiration
                    iat => time,             # Issued time
                    auth_time => $self->{sessionInfo}->{_lastAuthnUTime}
                    ,                        # Authentication time
                    acr =>
                      $id_token_acr,    # Authentication Context Class Reference
                    azp   => $client_id,                 # Authorized party
                                                         # TODO amr
                    nonce => $oidc_request->{'nonce'}    # Nonce
                };

                $id_token_payload_hash->{'at_hash'} = $at_hash if $at_hash;
                $id_token_payload_hash->{'c_hash'}  = $c_hash  if $c_hash;

                # Create ID Token
                $id_token = $self->createIDToken( $id_token_payload_hash, $rp );

                $self->lmLog( "Generated id token: $id_token", 'debug' );
            }

            my $expires_in = $self->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsAccessTokenExpiration};

            # Build Response
            my $response_url = $self->buildHybridAuthnResponse(
                $oidc_request->{'redirect_uri'},
                $code, $access_token, $id_token, $expires_in,
                $oidc_request->{'state'},
                $session_state
            );

            $self->lmLog( "Redirect user to $response_url", 'debug' );
            $self->{'urldc'} = $response_url;

            $self->_sub('autoRedirect');
        }

        $self->lmLog( "No flow has been selected", 'debug' );
        return PE_OK;
    }

    # TOKEN
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${token_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect TOKEN URL",
            'debug' );

        # This should not happen
        $self->lmLog(
            "Token request found on an active SSO session, ignoring it",
            'error' );
        $self->returnJSONError("invalid_request");

        $self->quit;
    }

    # USERINFO
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${userinfo_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect USERINFO URL",
            'debug' );

        # This should not happen
        $self->lmLog(
            "UserInfo request found on an active SSO session, ignoring it",
            'error' );
        $self->returnJSONError("invalid_request");

        $self->quit;
    }

    # JWKS
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${jwks_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect JWKS URL",
            'debug' );

        # This should not happen
        $self->lmLog(
            "JWKS request found on an active SSO session, ignoring it",
            'error' );
        $self->returnJSONError("invalid_request");

        $self->quit;
    }

    # REGISTRATION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${registration_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect REGISTRATION URL",
            'debug' );

        # This should not happen
        $self->lmLog(
            "Registration request found on an active SSO session, ignoring it",
            'error'
        );
        $self->returnJSONError("invalid_request");

        $self->quit;
    }

    # END SESSION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${endsession_uri}# ) {

        $self->lmLog( "URL $url detected as an OpenID Connect END SESSION URL",
            'debug' );

        # Set hidden fields
        my $oidc_request = {};
        foreach my $param (qw/id_token_hint post_logout_redirect_uri state/) {
            $oidc_request->{$param} = $self->getHiddenFormValue($param)
              || $self->param($param);
            $self->lmLog(
                "OIDC request parameter $param: " . $oidc_request->{$param},
                'debug' );
            $self->setHiddenFormValue( $param, $oidc_request->{$param} );
        }

        my $post_logout_redirect_uri =
          $oidc_request->{'post_logout_redirect_uri'};
        my $state = $oidc_request->{'state'};

        # Ask consent for logout
        if ( $self->param('confirm') == 1 or $self->param('confirm') == -1 ) {
            if ( $self->param('confirm') == 1 ) {
                my $apacheSession = $self->getApacheSession($session_id);
                $self->_deleteSession($apacheSession);
            }

            if ($post_logout_redirect_uri) {

                # Check redirect URI is allowed
                my $redirect_uri_allowed = 0;
                foreach ( keys %{ $self->{oidcRPMetaDataOptions} } ) {
                    my $logout_rp = $_;
                    my $redirect_uris =
                      $self->{oidcRPMetaDataOptions}->{$logout_rp}
                      ->{oidcRPMetaDataOptionsPostLogoutRedirectUris};

                    foreach ( split( /\s+/, $redirect_uris ) ) {
                        if ( $post_logout_redirect_uri eq $_ ) {
                            $self->lmLog(
"$post_logout_redirect_uri is an allowed logout redirect URI for RP $logout_rp",
                                'debug'
                            );
                            $redirect_uri_allowed = 1;
                        }
                    }
                }

                unless ($redirect_uri_allowed) {
                    $self->lmLog( "$post_logout_redirect_uri is not allowed",
                        'error' );
                    return PE_BADURL;
                }

                # Build Response
                my $response_url =
                  $self->buildLogoutResponse( $post_logout_redirect_uri,
                    $state );

                $self->lmLog( "Redirect user to $response_url", 'debug' );
                $self->{'urldc'} = $response_url;

                $self->_sub('autoRedirect');
            }

            return PE_LOGOUT_OK if $self->param('confirm') == 1;
            return PE_OK;
        }

        $self->info('<div class="oidc_logout_message">');
        $self->info( '<h3>' . $self->msg(PM_OIDC_CONFIRM_LOGOUT) . '</h3>' );
        $self->info('</div>');
        $self->{activeTimer} = 0;
        return PE_CONFIRM;
    }

    # CHECK SESSION
    if ( $url_path =~ m#${issuerDBOpenIDConnectPath}${checksession_uri}# ) {

        $self->lmLog(
            "URL $url detected as an OpenID Connect CHECK SESSION URL",
            'debug' );

        print $self->header(
            -type                        => 'text/html',
            -access_control_allow_origin => '*'
        );

        my $checksession_tpl =
          $self->getApacheHtdocsPath . "/skins/common/oidc_checksession.tpl";

        my $portalPath = $self->{portal};
        $portalPath =~ s#^https?://[^/]+/?#/#;
        $portalPath =~ s#[^/]+\.pl$##;

        my $template = HTML::Template->new( filename => $checksession_tpl );
        $template->param( "JS_CODE" => $self->getSessionManagementOPIFrameJS );
        $template->param( "SKIN_PATH" => $portalPath . "skins" );
        print $template->output;
        $self->quit();
    }

    PE_OK;
}

## @apmethod int issuerLogout()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBOpenIDConnect - OpenIDConnect Provider for Lemonldap::NG

=head1 DESCRIPTION

This is an OpenID Connect provider implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2014-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
