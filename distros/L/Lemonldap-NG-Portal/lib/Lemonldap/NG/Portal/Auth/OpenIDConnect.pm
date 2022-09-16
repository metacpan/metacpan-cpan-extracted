package Lemonldap::NG::Portal::Auth::OpenIDConnect;

use strict;
use Mouse;
use MIME::Base64 qw/encode_base64 decode_base64/;
use Scalar::Util qw/looks_like_number/;
use Lemonldap::NG::Common::JWT qw(getJWTPayload);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_IDPCHOICE
  PE_OIDC_AUTH_ERROR
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Portal::Main::Auth
  Lemonldap::NG::Portal::Lib::OpenIDConnect
);

# INTERFACE

has opList => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has path => ( is => 'rw', default => 'oauth2' );

use constant sessionKind => 'OIDC';

# INITIALIZATION

sub init {
    my $self = shift;

    return 0 unless ( $self->loadOPs and $self->refreshJWKSdata );
    my @tab = ( sort keys %{ $self->oidcOPList } );
    unless (@tab) {
        $self->logger->error("No OP configured");
        return 0;
    }
    my @list       = ();
    my $portalPath = $self->conf->{portal};

    foreach (@tab) {
        my $name = $_;
        $name =
          $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsDisplayName}
          if $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsDisplayName};
        my $icon = $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsIcon};
        my $order = $self->conf->{oidcOPMetaDataOptions}->{$_}
          ->{oidcOPMetaDataOptionsSortNumber} // 0;
        my $img_src;

        if ($icon) {
            $img_src =
              ( $icon =~ m#^https?://# )
              ? $icon
              : $portalPath . $self->p->staticPrefix . "/common/" . $icon;
        }

        push @list,
          {
            val   => $_,
            name  => $name,
            icon  => $img_src,
            class => "openidconnect",
            order => $order
          };
    }
    $self->addRouteFromConf(
        'Unauth',
        oidcServiceMetaDataFrontChannelURI => 'alreadyLoggedOut',
        oidcServiceMetaDataBackChannelURI  => 'backLogout',
    );
    $self->addRouteFromConf(
        'Auth',
        oidcServiceMetaDataFrontChannelURI => 'frontLogout',
        oidcServiceMetaDataBackChannelURI  => 'backLogout',
    );
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

    # Check callback
    if ( $req->param( $self->conf->{oidcRPCallbackGetParam} ) ) {

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
        my $id_token      = $token_response->{id_token};
        my $refresh_token = $token_response->{refresh_token};

        undef $expires_in unless looks_like_number($expires_in);

        $self->logger->debug("Access token: $access_token");
        $self->logger->debug(
            "Access token expires in: " . ( $expires_in || "<unknown>" ) );
        $self->logger->debug("ID token: $id_token");
        $self->logger->debug(
            "Refresh token: " . ( $refresh_token || "<none>" ) );

        # Verify JWT signature
        if ( $self->conf->{oidcOPMetaDataOptions}->{$op}
            ->{oidcOPMetaDataOptionsCheckJWTSignature} )
        {
            unless ( $self->verifyJWTSignature( $id_token, $op ) ) {
                $self->logger->error("JWT signature verification failed");
                return PE_OIDC_AUTH_ERROR;
            }
            $self->logger->debug("JWT signature verified");
        }
        else {
            $self->logger->debug("JWT signature check disabled");
        }

        my $id_token_payload_hash = getJWTPayload($id_token);
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
        unless ( $self->checkIDTokenValidity( $op, $id_token_payload_hash ) ) {
            $self->userLogger->error('ID Token not valid');
            return PE_OIDC_AUTH_ERROR;
        }
        else {
            $self->logger->debug('ID Token is valid');
        }

        # Get user id defined in 'sub' field
        my $user_id = $id_token_payload_hash->{sub};

        # Remember tokens
        $req->data->{access_token}  = $access_token;
        $req->data->{refresh_token} = $refresh_token if $refresh_token;
        $req->data->{id_token}      = $id_token;

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

    # Save state
    my $state = $self->storeState( $req, qw/urldc checkLogins _oidcOPCurrent/ );

    # Authorization Code Flow
    my $authorization_request_uri =
      $self->buildAuthorizationCodeAuthnRequest( $req, $op, $state );
    unless ($authorization_request_uri) {
        return PE_OIDC_AUTH_ERROR;
    }

    $req->urldc($authorization_request_uri);

    $self->logger->debug( "Redirect user to " . $req->{urldc} );
    $req->continue(1);
    $req->steps( [] );

    return PE_OK;
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

    # Keep ID Token in session
    my $store_IDToken = $self->conf->{oidcOPMetaDataOptions}->{$op}
      ->{oidcOPMetaDataOptionsStoreIDToken};
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

    my $op = $req->{sessionInfo}->{_oidc_OP};

    # Find endession endpoint
    my $endsession_endpoint =
      $self->oidcOPList->{$op}->{conf}->{end_session_endpoint};

    if ($endsession_endpoint) {
        my $logout_url = $self->conf->{portal} . '?logout=1';
        $req->urldc(
            $self->buildLogoutRequest(
                $endsession_endpoint, $req->{sessionInfo}->{_oidc_id_token},
                $logout_url
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

sub alreadyLoggedOut {
    my ( $self, $req ) = @_;
    $self->userLogger->info(
        'Front-channel logout request for an already logged out user');
    my $img = $self->conf->{staticPrefix} . '/common/icons/ok.png';

    # No need to protect this frame
    $req->frame(1);
    my $frame = qq'<html><body><img src="$img"></body></html>';
    return [
        200,
        [ 'Content-Type' => 'text/html', 'Content-Length' => length($frame) ],
        [$frame]
    ];
}

sub frontLogout {
    my ( $self, $req ) = @_;
}

sub backLogout {
    my ( $self, $req ) = @_;
}

1;
