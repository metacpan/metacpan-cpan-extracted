package Lemonldap::NG::Portal::Plugins::OIDC::DynamicRegistration;

use strict;
use Mouse;
use String::Random                         qw/random_string/;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.23.0';

extends qw(
  Lemonldap::NG::Portal::Lib::OIDCPlugin
  Lemonldap::NG::Common::Conf::AccessLib
);

# random_string mask for auto-registration client-id/secret
use constant RS_MSK => 's' x 30;

has configStorage => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->{p}->HANDLER->localConfig->{configStorage};
    }
);

sub init {
    my ($self) = @_;
    return 0 unless $self->SUPER::init;
    my $uri = $self->conf->{oidcServiceMetaDataRegistrationURI} || 'register';

    # Avoid warning if loading modules twice
    return 1 if $self->p->unAuthRoutes->{GET}->{ $self->path }->{$uri};

    $self->addUnauthRoute(
        $self->path => { $uri => 'registration' },
        [ 'GET', 'POST' ]
    );
    $self->addAuthRoute(
        $self->path => { $uri => 'registration' },
        [ 'GET', 'POST' ]
    );
    return 1;
}

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

    # Get client metadata first (needed for hook)
    my $client_metadata_json = $req->content;
    return $self->p->sendError( $req, 'Missing POST data', 400 )
      unless ($client_metadata_json);

    $self->logger->debug("Client metadata received: $client_metadata_json");

    my $client_metadata = $self->oidc->decodeJSON($client_metadata_json)
      or return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    my $registration_response = {};

    # Check dynamic registration is allowed
    unless ( $self->conf->{oidcServiceAllowDynamicRegistration} ) {
        $self->logger->error("Dynamic registration is not allowed");
        return $self->p->sendError( $req, 'server_error' );
    }

    # Let hooks filter registration requests
    # PE_SENDRESPONSE means the hook took over the response
    my $h = $self->p->processHook( $req, 'oidcGotRegistrationRequest',
        $client_metadata );
    return $req->response if $h == PE_SENDRESPONSE;
    if ( $h != PE_OK ) {
        $self->logger->error("oidcGotRegistrationRequest hook failed");
        return $self->p->sendError( $req, 'invalid_request', 400 );
    }

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

    # Handle token_endpoint_auth_method
    my $token_endpoint_auth_method =
      $client_metadata->{token_endpoint_auth_method} || 'client_secret_basic';
    my $is_public = ( $token_endpoint_auth_method eq 'none' );
    my $needs_secret =
      $token_endpoint_auth_method =~ /^client_secret_(?:basic|post|jwt)$/;

    # Validate token_endpoint_auth_method value
    unless ( $is_public
        or $needs_secret
        or $token_endpoint_auth_method eq 'private_key_jwt' )
    {
        $self->logger->error(
"Unsupported token_endpoint_auth_method: $token_endpoint_auth_method"
        );
        return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    }

    # Reject public clients when only confidential clients are allowed
    if (   !$needs_secret
        and $self->conf->{oidcServiceAllowDynamicRegistration} < 2 )
    {
        $self->logger->error( "Public client registration is not allowed "
              . "(token_endpoint_auth_method=$token_endpoint_auth_method)" );
        return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    }

    # private_key_jwt requires jwks_uri
    if ( $token_endpoint_auth_method eq 'private_key_jwt'
        and not $client_metadata->{jwks_uri} )
    {
        $self->logger->error(
            "private_key_jwt requires jwks_uri in registration request");
        return $self->p->sendError( $req, 'invalid_client_metadata', 400 );
    }

    # Generate Client ID and secret
    my $client_id     = random_string(RS_MSK);
    my $client_secret = $needs_secret ? random_string(RS_MSK) : undef;

    my $default_signing_key_type = $self->oidc->_getKeyType(
        $self->oidc->get_public_key("default-oidc-sig") );

    # Register known parameters
    my $client_name =
      $client_metadata->{client_name} || "Self registered client";
    my $logo_uri = $client_metadata->{logo_uri};
    my $id_token_signed_response_alg =
      $client_metadata->{id_token_signed_response_alg}
      || ( $default_signing_key_type eq 'EC' ? 'ES256' : 'RS256' );
    my $userinfo_signed_response_alg =
      $client_metadata->{userinfo_signed_response_alg};
    my $request_uris           = $client_metadata->{request_uris};
    my $backchannel_logout_uri = $client_metadata->{backchannel_logout_uri};
    my $backchannel_logout_session_required =
      $client_metadata->{backchannel_logout_session_required};
    my $frontchannel_logout_uri = $client_metadata->{frontchannel_logout_uri};
    my $frontchannel_logout_session_required =
      $client_metadata->{frontchannel_logout_session_required};
    my $jwksUri = $client_metadata->{jwks_uri};
    my $encryptedResponseAlg =
      $client_metadata->{id_token_encrypted_response_alg};
    my $encryptedResponseEnc =
      $client_metadata->{id_token_encrypted_response_enc};
    my $userInfoEncAlg = $client_metadata->{userinfo_encrypted_response_alg};
    my $userInfoEncEnc = $client_metadata->{userinfo_encrypted_response_enc};
    my $introspectionSignAlg =
      $client_metadata->{introspection_signed_response_alg};
    my $introspectionEncAlg =
      $client_metadata->{introspection_encrypted_response_alg};
    my $introspectionEncEnc =
      $client_metadata->{introspection_encrypted_response_enc};

    # Register RP in global configuration
    my $conf = $self->confAcc->getConf( { raw => 1, noCache => 1 } );

    $conf->{cfgAuthor}   = "OpenID Connect Registration ($client_name)";
    $conf->{cfgAuthorIP} = $source_ip;
    $conf->{cfgVersion}  = $VERSION;

    # Build RP options from client metadata
    my $rp_options = {
        oidcRPMetaDataOptionsClientID       => $client_id,
        oidcRPMetaDataOptionsDisplayName    => $client_name,
        oidcRPMetaDataOptionsIcon           => $logo_uri,
        oidcRPMetaDataOptionsIDTokenSignAlg => $id_token_signed_response_alg,
        oidcRPMetaDataOptionsRedirectUris   => join( ' ', @$redirect_uris ),
    };
    $rp_options->{oidcRPMetaDataOptionsClientSecret} = $client_secret
      if defined $client_secret;
    $rp_options->{oidcRPMetaDataOptionsPublic}      = 1 if $is_public;
    $rp_options->{oidcRPMetaDataOptionsRequirePKCE} = 2;
    $rp_options->{oidcRPMetaDataOptionsRequestUris} =
      join( ' ', @$request_uris )
      if $request_uris and @$request_uris;
    $rp_options->{oidcRPMetaDataOptionsUserInfoSignAlg} =
      $userinfo_signed_response_alg
      if defined $userinfo_signed_response_alg;

    if ($backchannel_logout_uri) {
        $rp_options->{oidcRPMetaDataOptionsLogoutType} = 'back';
        $rp_options->{oidcRPMetaDataOptionsLogoutUrl} = $backchannel_logout_uri;
        $rp_options->{oidcRPMetaDataOptionsLogoutSessionRequired} =
          $backchannel_logout_session_required;
    }
    elsif ($frontchannel_logout_uri) {
        $rp_options->{oidcRPMetaDataOptionsLogoutType} = 'front';
        $rp_options->{oidcRPMetaDataOptionsLogoutUrl} =
          $frontchannel_logout_uri;
        $rp_options->{oidcRPMetaDataOptionsLogoutSessionRequired} =
          $frontchannel_logout_session_required;
    }
    $rp_options->{oidcRPMetaDataOptionsJwksUri} = $jwksUri
      if $jwksUri;
    $rp_options->{oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg} =
      $encryptedResponseAlg
      if $encryptedResponseAlg;
    $rp_options->{oidcRPMetaDataOptionsIdTokenEncContentEncAlg} =
      $encryptedResponseEnc
      if $encryptedResponseEnc;
    $rp_options->{oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg} = $userInfoEncAlg
      if $userInfoEncAlg;
    $rp_options->{oidcRPMetaDataOptionsUserInfoEncContentEncAlg} =
      $userInfoEncEnc
      if $userInfoEncEnc;
    $rp_options->{oidcRPMetaDataOptionsIntrospectionSignAlg} =
      $introspectionSignAlg
      if $introspectionSignAlg;
    $rp_options->{oidcRPMetaDataOptionsIntrospectionEncKeyMgtAlg} =
      $introspectionEncAlg
      if $introspectionEncAlg;
    $rp_options->{oidcRPMetaDataOptionsIntrospectionEncContentEncAlg} =
      $introspectionEncEnc
      if $introspectionEncEnc;

    # TODO "jwks" support (when jwks_uri isn't available

    # Exported Vars
    my $exported_vars = {};
    if (
        ref( $self->conf->{oidcServiceDynamicRegistrationExportedVars} ) eq
        'HASH' )
    {
        $exported_vars =
          $self->conf->{oidcServiceDynamicRegistrationExportedVars};
    }

    # Extra claims
    my $extra_claims = {};
    if (
        ref( $self->conf->{oidcServiceDynamicRegistrationExtraClaims} ) eq
        'HASH' )
    {
        $extra_claims =
          $self->conf->{oidcServiceDynamicRegistrationExtraClaims};
    }

    # Build newRp structure (same shape as getOidcRpConfig)
    # Hooks can modify this to adjust the RP config before save
    my $newRp = {
        confKey     => $rp,
        options     => $rp_options,
        attributes  => $exported_vars,
        macros      => {},
        scopeRules  => {},
        extraClaims => $extra_claims,
    };

    # Allow hooks to modify the new RP config before saving
    # $client_metadata is passed for read-only context
    $h = $self->p->processHook( $req, 'oidcRegisterClient',
        $newRp, $client_metadata );
    if ( $h != PE_OK ) {
        $self->logger->error("oidcRegisterClient hook failed");
        return $self->p->sendError( $req, 'server_error', 500 );
    }

    # Apply newRp to configuration
    $rp            = $newRp->{confKey};
    $client_id     = $newRp->{options}->{oidcRPMetaDataOptionsClientID};
    $client_secret = $newRp->{options}->{oidcRPMetaDataOptionsClientSecret};

    $conf->{oidcRPMetaDataOptions}->{$rp}      = $newRp->{options};
    $conf->{oidcRPMetaDataExportedVars}->{$rp} = $newRp->{attributes};
    $conf->{oidcRPMetaDataMacros}->{$rp}       = $newRp->{macros}
      if %{ $newRp->{macros} };
    $conf->{oidcRPMetaDataScopeRules}->{$rp} = $newRp->{scopeRules}
      if %{ $newRp->{scopeRules} };
    $conf->{oidcRPMetaDataOptionsExtraClaims}->{$rp} = $newRp->{extraClaims}
      if %{ $newRp->{extraClaims} };

    if ( $self->confAcc->saveConf($conf) > 0 ) {

        # Send registration response
        $registration_response->{'client_id'}     = $client_id;
        $registration_response->{'client_secret'} = $client_secret
          if defined $client_secret;
        $registration_response->{'token_endpoint_auth_method'} =
          $token_endpoint_auth_method;
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
        $registration_response->{'introspection_signed_response_alg'} =
          $introspectionSignAlg
          if defined $introspectionSignAlg;
        $registration_response->{'introspection_encrypted_response_alg'} =
          $introspectionEncAlg
          if defined $introspectionEncAlg;
        $registration_response->{'introspection_encrypted_response_enc'} =
          $introspectionEncEnc
          if defined $introspectionEncEnc;
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

1;
