package Lemonldap::NG::Portal::Auth::OpenIDConnect;

use strict;
use Mouse;
use MIME::Base64                           qw/encode_base64 decode_base64/;
use Scalar::Util                           qw/looks_like_number/;
use Lemonldap::NG::Common::JWT             qw(getJWTPayload);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_IDPCHOICE
  PE_OIDC_AUTH_ERROR
  PE_SENDRESPONSE
);

our $VERSION = '2.21.0';

extends qw(
  Lemonldap::NG::Portal::Main::Auth
  Lemonldap::NG::Portal::Lib::OpenIDConnect
);

# INTERFACE

has opList      => ( is => 'rw', isa     => 'ArrayRef', default => sub { [] } );
has path        => ( is => 'rw', default => 'oauth2' );
has endpointsRe => ( is => 'rw' );

use constant sessionKind => 'OIDC';

# INITIALIZATION

sub init {
    my $self = shift;

    return 0 unless ( $self->loadOPs and $self->refreshJWKSdata );
    my @tab = ( sort keys %{ $self->opMetadata } );
    unless (@tab) {
        $self->logger->error("No OP configured");
        return 0;
    }
    my @list = ();

    foreach (@tab) {
        my $name = $_;
        $name = $self->opOptions->{$_}->{oidcOPMetaDataOptionsDisplayName}
          if $self->opOptions->{$_}->{oidcOPMetaDataOptionsDisplayName};
        my $icon = $self->opOptions->{$_}->{oidcOPMetaDataOptionsIcon};
        my $tooltip =
          $self->opOptions->{$_}->{oidcOPMetaDataOptionsTooltip} || $name;
        my $order = $self->opOptions->{$_}->{oidcOPMetaDataOptionsSortNumber}
          // 999999;
        my $img_src;

        if ($icon) {
            $img_src =
              ( $icon =~ m#^https?://# )
              ? $icon
              : $self->p->staticPrefix . "/common/" . $icon;
        }

        push @list,
          {
            val   => $_,
            name  => $name,
            title => $tooltip,
            icon  => $img_src,
            order => $order
          };
    }

    my $re = '^/' . $self->path . '/(?:' . join(
        '|',
        map {
            my $s = $self->conf->{$_};
            $s =~ s/#PORTAL#\/*//;
            $s
        } ( qw(
              oidcServiceMetaDataFrontChannelURI
              oidcServiceMetaDataBackChannelURI
            )
        )
    ) . ')(?:[\?/].*)?$';

    $self->endpointsRe(qr/$re/);

    $self->addRouteFromConf(
        'Auth',
        oidcServiceMetaDataFrontChannelURI => 'frontLogout',
        oidcServiceMetaDataBackChannelURI  => 'backLogout',
        oidcServiceMetaDataJWKSURI         => 'jwks',
    );
    $self->addRouteFromConf( 'Unauth', oidcServiceMetaDataJWKSURI => 'jwks', );

    @list =
      sort {
             $a->{order} <=> $b->{order}
          or $a->{name} cmp $b->{name}
          or $a->{val} cmp $b->{val}
      } @list;
    $self->opList( [@list] );
    return 1;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    if ( $req->uri =~ $self->endpointsRe ) {
        my $path = $req->path;
        my $tmp  = $self->path;
        $path =~ s#^/*\Q$tmp\E/*##o;
        $path =~ s#/.*$##;
        if ( $path eq $self->conf->{oidcServiceMetaDataBackChannelURI} ) {
            $req->response( $self->backLogout($req) );
            return PE_SENDRESPONSE;
        }
        elsif ( $path eq $self->conf->{oidcServiceMetaDataFrontChannelURI} ) {
            $req->response( $self->searchAndLogout($req) );
            return PE_SENDRESPONSE;
        }
    }

    # Check callback
    if ( $self->isCallback($req)
        and not $req->param('oidc_callback_processed') )
    {
        # This makes sure we don't go through the callback code when re-posting
        # a login form
        $self->p->setHiddenFormValue( $req, "oidc_callback_processed", "1", "",
            0 );

        $self->logger->debug(
            'OpenIDConnect callback URI detected: ' . $req->uri );

        # AuthN Response
        my $state = $req->param('state');

        # Restore state
        if ($state) {
            if ( $self->extractState( $req, $state ) ) {
                $self->logger->debug("State $state extracted");
            }
            else {
                $self->userLogger->error("Unable to extract state $state");
                return PE_OIDC_AUTH_ERROR;
            }
        }

        # Get OpenID Provider
        my $op = $req->data->{_oidcOPCurrent};

        unless ($op) {
            $self->userLogger->error("OpenIDConnect Provider not found");
            return PE_OIDC_AUTH_ERROR;
        }

        $self->logger->debug("Using OpenIDConnect Provider $op");

        # Check error
        my $error = $req->param("error");
        if ($error) {
            my $error_description = $req->param("error_description");
            my $error_uri         = $req->param("error_uri");

            $self->logger->error("Error returned by $op Provider: $error");
            $self->logger->error("Error description: $error_description")
              if $error_description;
            $self->logger->error("Error URI: $error_uri") if $error_uri;

            return PE_OIDC_AUTH_ERROR;
        }

        # Get access_token and id_token
        my $code = $req->param("code");

        my $content =
          $self->getAuthorizationCodeAccessToken( $req, $op, $code );
        return PE_OIDC_AUTH_ERROR unless $content;

        my $token_response = $self->decodeTokenResponse($content);

        unless ($token_response) {
            $self->logger->error("Could not decode Token Response: $content");
            return PE_OIDC_AUTH_ERROR;
        }

        # Check validity of token response
        unless ( $self->checkTokenResponseValidity($token_response) ) {
            $self->logger->error("Token response is not valid");
            return PE_OIDC_AUTH_ERROR;
        }
        else {
            $self->logger->debug("Token response is valid");
        }

        my $access_token  = $token_response->{access_token};
        my $expires_in    = $token_response->{expires_in};
        my $id_token      = $self->decryptJwt( $token_response->{id_token} );
        my $refresh_token = $token_response->{refresh_token};

        undef $expires_in unless looks_like_number($expires_in);

        $self->logger->debug("Access token: $access_token");
        $self->logger->debug(
            "Access token expires in: " . ( $expires_in || "<unknown>" ) );
        $self->logger->debug("ID token: $id_token");
        $self->logger->debug(
            "Refresh token: " . ( $refresh_token || "<none>" ) );

        # Verify JWT signature
        my $id_token_payload_hash;
        if ( $self->opOptions->{$op}->{oidcOPMetaDataOptionsCheckJWTSignature} )
        {
            unless ( $id_token_payload_hash =
                $self->decodeJWT( $id_token, $op ) )
            {
                $self->logger->error("JWT signature verification failed");
                $self->logger->error("Failing JWT is: $id_token");
                return PE_OIDC_AUTH_ERROR;
            }
            $self->logger->debug("JWT signature verified");
        }
        else {
            $self->logger->debug("JWT signature check disabled");
            $id_token_payload_hash = getJWTPayload($id_token);
        }

        unless ( defined $id_token_payload_hash ) {
            $self->logger->error(
                "Could not decode incoming ID token: $id_token");
            return PE_OIDC_AUTH_ERROR;
        }

        # Call oidcGotIDToken hook
        my $h = $self->p->processHook( $req, 'oidcGotIDToken',
            $op, $id_token_payload_hash, );
        return PE_OIDC_AUTH_ERROR if ( $h != PE_OK );

        # Check validity of Access Token (optional)
        my $at_hash = $id_token_payload_hash->{at_hash};
        if ($at_hash) {
            unless ( $self->verifyHash( $access_token, $at_hash, $id_token ) ) {
                $self->userLogger->error(
                    "Access token hash verification failed");
                return PE_OIDC_AUTH_ERROR;
            }
            $self->logger->debug("Access token hash verified");
        }
        else {
            $self->logger->debug(
                "No at_hash in ID Token, access token will not be verified");
        }

        # Check validity of ID Token
        unless (
            $self->checkIDTokenValidity(
                $op, $id_token_payload_hash, $req->data->{_oidcNonce}
            )
          )
        {
            $self->userLogger->error('ID Token not valid');
            return PE_OIDC_AUTH_ERROR;
        }
        else {
            $self->logger->debug('ID Token is valid');
        }

        # Get sub from ID token
        my $id_token_sub = $id_token_payload_hash->{sub};
        if ( !$id_token_sub ) {
            $self->logger->error("Could not find sub claim in ID Token");
            return PE_OIDC_AUTH_ERROR;
        }
        my $user_id = $id_token_sub;

        # Get user identifier, if different from sub
        my $user_claim = $self->conf->{oidcOPMetaDataOptions}->{$op}
          ->{oidcOPMetaDataOptionsUserAttribute};
        if ($user_claim) {
            $user_id = $id_token_payload_hash->{$user_claim};
            if ( !$user_id ) {
                $self->logger->error(
                    "Could not find $user_claim claim in ID Token");
                return PE_OIDC_AUTH_ERROR;
            }
        }

        # Remember ID Token sub
        $req->data->{id_token_sub} = $id_token_sub;

        # Remember tokens
        $req->data->{access_token}  = $access_token;
        $req->data->{refresh_token} = $refresh_token if $refresh_token;
        $req->data->{id_token}      = $id_token;

        # Remember sid claim if given
        $req->data->{op_sid} = $id_token_payload_hash->{sid}
          if $id_token_payload_hash->{sid};

        # If access token TTL is given save expiration date
        # (with security margin)
        if ($expires_in) {
            $req->data->{access_token_eol} = time + ( $expires_in * 0.9 );
        }

        $self->logger->debug( "Found user_id: " . $user_id );
        $req->user($user_id);

        return PE_OK;
    }

    # No callback, choose Provider and send authn request
    my $op;

    unless ( $op = $req->param("idp") ) {
        $self->logger->debug("Redirecting user to OP list");

        # Auto select provider if there is only one
        if ( @{ $self->opList } == 1 ) {
            $op = $self->opList->[0]->{val};
            $self->logger->debug("Selecting the only defined OP: $op");
        }

        else {

            # Try to use OP resolution rules
            foreach ( keys %{ $self->opRules } ) {
                my $cond = $self->opRules->{$_} or next;
                if ( $cond->( $req, $req->sessionInfo ) ) {
                    $self->logger->debug("OP $_ selected from resolution rule");
                    $op = $_;
                    last;
                }
            }

            unless ($op) {

                # display OP list
                $req->data->{list}  = $self->opList;
                $req->data->{login} = 1;
                return PE_IDPCHOICE;
            }
        }
    }

    # Provider is choosen
    $self->logger->debug("OpenID Provider $op choosen");

    $req->data->{_oidcOPCurrent} = $op;

    # AuthN Request
    $self->logger->debug("Build OpenIDConnect AuthN Request");

    my $nonce;
    if ( $self->opOptions->{$op}->{oidcOPMetaDataOptionsUseNonce} ) {
        $nonce = $self->generateNonce();
        $req->data->{_oidcNonce} = $nonce;
    }

    # Save state
    my $state = $self->storeState( $req,
        qw/urldc checkLogins _oidcOPCurrent _oidcNonce/ );

    # Authorization Code Flow
    my $authorization_request_uri =
      $self->buildAuthorizationCodeAuthnRequest( $req, $op, $state, $nonce );
    unless ($authorization_request_uri) {
        return PE_OIDC_AUTH_ERROR;
    }

    $req->urldc($authorization_request_uri);

    $self->logger->debug( "Redirect user to " . $req->{urldc} );
    $req->continue(1);
    $req->steps( [] );

    return PE_OK;
}

sub isCallback {
    my ( $self, $req ) = @_;
    return $req->param( $self->conf->{oidcRPCallbackGetParam} );
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    my $op = $req->data->{_oidcOPCurrent};

    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{oidcAuthnLevel};

    $req->{sessionInfo}->{_oidc_OP} = $op;
    $req->{sessionInfo}->{_oidc_access_token} =
      $req->data->{access_token};

    if ( $req->data->{refresh_token} ) {
        $req->{sessionInfo}->{_oidc_refresh_token} =
          $req->data->{refresh_token};
    }

    if ( $req->data->{access_token_eol} ) {
        $req->{sessionInfo}->{_oidc_access_token_eol} =
          $req->data->{access_token_eol};
    }

    if ( $req->data->{op_sid} ) {
        $req->{sessionInfo}->{_oidc_sid} = $req->data->{op_sid};
    }

    if ( $req->data->{id_token_sub} ) {
        $req->{sessionInfo}->{_oidc_sub} = $req->data->{id_token_sub};
    }

    # Keep ID Token in session
    my $store_IDToken =
      $self->opOptions->{$op}->{oidcOPMetaDataOptionsStoreIDToken};
    if ($store_IDToken) {
        $self->logger->debug("Store ID Token in session");
        $req->{sessionInfo}->{_oidc_id_token} = $req->data->{id_token};
    }
    else {
        $self->logger->debug("ID Token will not be stored in session");
    }

    return PE_OK;
}

sub authLogout {
    my ( $self, $req ) = @_;

    return PE_OK if $req->data->{oidcSkipLogout};

    my $op = $req->{sessionInfo}->{_oidc_OP};

    # Find endession endpoint
    my $endsession_endpoint =
      $self->opMetadata->{$op}->{conf}->{end_session_endpoint};

    my $client_id = $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientID};

    if ($endsession_endpoint) {
        my $logout_url = $self->p->buildUrl( $req->portal, { logout => 1 } );
        $req->urldc(
            $self->buildLogoutRequest(
                $endsession_endpoint, $req->{sessionInfo}->{_oidc_id_token},
                $logout_url, undef, $client_id,
            )
        );

        $self->logger->debug(
            "OpenID Connect logout to $op will be done on " . $req->urldc );
    }
    else {
        $self->logger->debug("No end session endpoint found for $op");
    }
    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

sub searchAndLogout {
    my ( $self, $req ) = @_;
    $self->userLogger->info(
        'Front-channel logout request called without cookie');
    $req->data->{frontLogoutSearch} = 1;
    return $self->frontLogout($req);
}

sub frontLogout {
    my ( $self, $req ) = @_;

    # No double disconnect
    $req->data->{oidcSkipLogout} = 1;

    # Response should be displayed in an iframe
    $req->frame(1);

    # TODO check iss and sid
    my $iss        = $req->param('iss');
    my $sid        = $req->param('sid');
    my $badRequest = 0;
    my $logName    = 'OIDC FC Logout';

    my $img      = $self->conf->{staticPrefix} . '/common/icons/ok.png';
    my $frame    = qq'<html><body><img src="$img"></body></html>';
    my $response = [
        200,
        [
            'Content-Type'   => 'text/html',
            'Content-Length' => length($frame)
        ],
        [$frame]
    ];

    # LLNG requires sid and iss
    unless ( $iss and $sid ) {
        $self->userLogger->error(
            'OIDC Front-Channel-Logout called without sid and iss');
        $badRequest++;
    }
    elsif ( $req->data->{frontLogoutSearch} ) {
        my %store = %{ $self->conf->{globalStorageOptions} };
        $store{backend} = $self->conf->{globalStorage};
        my $oidcSessions =
          Lemonldap::NG::Common::Apache::Session->searchOn( \%store,
            '_oidc_sid', $sid );
        my @sessionToDelete = keys %$oidcSessions;
        foreach (@sessionToDelete) {

            # searchOn() returns sessions indexed by their storage ID, then
            # it is required to set hashStore to 0
            if ( my $as = $self->p->getApacheSession( $_, hashStore => 0, ) ) {
                if ( $self->p->_deleteSession( $req, $as, 1 ) ) {
                    $self->logger->debug(
                        "$logName: session $_ deleted from global storage");
                }
                else {
                    $self->logger->error(
                        "$logName: unable to delete session $_");
                    $self->logger->error( $as->error );
                }
            }
        }
        return $response;
    }
    else {
        unless ( $req->userData->{_oidc_sid} and $req->userData->{_oidc_OP} ) {
            $self->logger->error(
                "$logName: key _oidc_sid not stored in session");
            $badRequest++;
        }
        else {
            if ( $sid ne $req->userData->{_oidc_sid} ) {
                $self->userLogger->error(
                    'OIDC Front-Channel-Logout: sid mismatch');
                $badRequest++;
            }
        }
    }
    if ($badRequest) {
        return $self->p->sendError( $req, 'Bad OIDC Logout Request', 200 );
    }
    $req->steps( $self->p->beforeLogout );
    my $res = $self->p->process($req);
    return $self->p->do(
        $req,
        [
            'authLogout',
            'deleteSession',
            sub {
                $req->response($response);
                return $res ? $res : PE_SENDRESPONSE;
            }
        ]
    );
}

# Implements https://openid.net/specs/openid-connect-backchannel-1_0.html
sub backLogout {
    my ( $self, $req ) = @_;
    my $logName = 'OIDC BC Logout';

    # REQUIRED CHECKS

    # Back channel requires POST
    return $self->p->sendError( $req, 'Only POST allowed', 400 )
      if $req->method ne 'POST';

    # Back channel requires logout_token
    my $content = $req->body_parameters;
    return $self->p->sendError( $req, 'logout_token not found', 400 )
      unless $content and $content->{logout_token};

    # Decode token
    my $logoutToken = $self->decryptJwt( $content->{logout_token} );
    my $payload     = getJWTPayload($logoutToken)
      or
      return $self->p->sendError( $req, 'Could not decode logout token', 400 );

    # TODO: validate "alg" header => prohibit "none" value

    # Required fields
    foreach (qw(iss aud iat jti events)) {
        return $self->p->sendError( $req, "Missing $_", 400 )
          unless $payload->{$_};
    }
    return $self->p->sendError( $req, 'Missing sub/sid', 400 )
      unless $payload->{sub} or $payload->{sid};

    # Get iss and found related OP
    my $op;
    foreach ( keys %{ $self->opMetadata } ) {
        if ( $self->opMetadata->{$_}->{conf}->{issuer} eq $payload->{iss} ) {
            $op = $_;
            last;
        }
    }
    return $self->p->sendError( $req, 'Issuer not found', 400 ) unless $op;

    # Verify signature
    return $self->p->sendError( $req, 'Bad signature', 400 )
      unless $self->decodeJWT( $logoutToken, $op );

    # Verify audience
    return $self->p->error( $req, 'Bad aud', 400 )
      unless ref $payload->{aud} eq 'ARRAY';
    return $self->p->error( $req, 'Client ID not found in audience array', 400 )
      unless
      grep { $_ eq $self->opOptions->{$op}->{oidcOPMetaDataOptionsClientID} }
      @{ $payload->{aud} };

    # Verify iat
    return $self->p->error( $req, 'Token too old', 400 )
      unless $payload->{iat} +
      ( $self->opOptions->{$op}->{oidcOPMetaDataOptionsIDTokenMaxAge} // 30 ) >
      time;

    # Verify events
    return $self->p->error( $req, 'Bad events', 400 )
      unless ref $payload->{events} eq 'HASH'
      and $payload->{events}->{ $self->BACKCHANNEL_EVENTSKEY() }
      and ref $payload->{events}->{ $self->BACKCHANNEL_EVENTSKEY() } eq 'HASH';

    # Verify nonce
    return $self->p->error( $req, 'Bad request', 400 ) if $payload->{nonce};

    # Now request is valid, even if session isn't found, response will be 200

    # Find session
    my $uid   = $payload->{sub};
    my $sid   = $payload->{sid};
    my %store = %{ $self->conf->{globalStorageOptions} };
    $store{backend} = $self->conf->{globalStorage};
    my @userSessions;
    if ($sid) {
        my $oidcSessions =
          Lemonldap::NG::Common::Apache::Session->searchOn( \%store,
            '_oidc_sid', $sid );
        @userSessions = keys %$oidcSessions;
    }
    else {
        my $oidcSessions =
          Lemonldap::NG::Common::Apache::Session->searchOn( \%store,
            '_oidc_sub', $uid );
        @userSessions =
          grep {
                  $oidcSessions->{$_}->{_oidc_OP}
              and $oidcSessions->{$_}->{_oidc_OP} eq $op;
          } keys %$oidcSessions;
    }
    if (@userSessions) {
        if ($#userSessions) {
            $self->logger->warn(
"$logName: more than one link found between $uid and $op, cleanong all"
            );
        }
        foreach (@userSessions) {

            # searchOn() returns sessions indexed by their storage ID, then
            # it is required to set hashStore to 0
            if ( my $as = $self->p->getApacheSession( $_, hashStore => 0 ) ) {
                if ( $self->p->_deleteSession( $req, $as, 1 ) ) {
                    $self->logger->debug(
                        "$logName: session $_ deleted from global storage");
                }
                else {
                    $self->logger->error(
                        "$logName: unable to delete session $_");
                    $self->logger->error( $as->error );
                }
            }
            else {
                $self->logger->info(
                    "$logName: session $_ for user $uid already deleted");
            }
        }
    }
    else {
        $self->logger->warn("$logName: no session found for $uid");
    }

    return [ 200, [], [] ];
}

1;
