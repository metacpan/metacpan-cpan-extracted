package Lemonldap::NG::Portal::Plugins::OIDCNativeSso;

use strict;
use Digest::SHA qw(sha256_hex);
use Mouse;
use Lemonldap::NG::Common::JWT qw(getJWTPayload);
use Lemonldap::NG::Portal::Issuer::OpenIDConnect;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_OK
  PE_SENDRESPONSE
);
use String::Random qw/random_string/;

our $VERSION = '2.21.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => {

# Step 1 verify that device_sso scope is authorized during authorization request
    oidcResolveScope => 'resolveScope',

    # Step 2: generate device_secret
    oidcGenerateAccessToken   => 'accessTokenHook',
    oidcGenerateIDToken       => 'addDsHash',
    oidcGenerateTokenResponse => 'tokenResponse',

    # Step 3: give new access_token when device_secret is valid
    oidcGotTokenExchange => 'tokenExchangeHook',
};

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};
    }
);

sub init {
    my ($self) = @_;
    unless ( $self->conf->{issuerDBOpenIDConnectActivation} ) {
        $self->logger->error(
            'This plugin can be used only if OIDC server is enabled');
        return 0;
    }
    1;
}

use constant sessionKind => 'OIDCI';

# STEP 1: verify that device_sso scope is authorized during authorization request

sub resolveScope {
    my ( $self, $req, $scopeList, $rp ) = @_;
    unless (
        $self->oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowNativeSso} )
    {
        my @scopes;

        # To keep $scopeList reference, empty related array then populate it
        while (@$scopeList) {
            my $tmp = shift(@$scopeList);
            if ( $tmp eq 'device_sso' ) {
                $self->userLogger->error(
                    "Request scope device_sso for an unauthorized RP: $rp");
            }
            else {
                push @scopes, $tmp unless $tmp eq 'device_sso';
            }
        }
        push @$scopeList, @scopes;
    }
    return PE_OK;
}

# STEP 2: generate device_secret
sub accessTokenHook {
    my ( $self, $req, $payload, $rp ) = @_;
    if ( $payload->{scope} =~ /\bdevice_sso\b/ ) {
        $req->data->{oidcNativeSso} = {
            scope   => $payload->{scope},
            ds_hash => random_string( 's' x 32 ),
        };
    }
    return PE_OK;
}

sub addDsHash {
    my ( $self, $req, $payload, $rp ) = @_;
    if ( $req->data->{oidcNativeSso} ) {
        $payload->{ds_hash} = $req->data->{oidcNativeSso}->{ds_hash};
    }
    return PE_OK;
}

sub tokenResponse {
    my ( $self, $req, $rp, $tokenResponse, $oidcSession, $sessionInfo ) = @_;
    if ( $req->data->{oidcNativeSso} ) {
        my %userInfo = ( ds_hash => $req->data->{oidcNativeSso}->{ds_hash} );
        for my $userKey ( grep !/^(_session|_utime$|_lastSeen$)/,
            keys %$sessionInfo )
        {
            $userInfo{$userKey} = $sessionInfo->{$userKey};
        }
        my $deviceSecret = $self->oidc->getOpenIDConnectSession(
            undef,
            'device_secret',

            # Fix device_secret timeout to the same value than offline token
            $self->oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowOffline}
            ? ( $self->oidc->rpOptions->{$rp}
                  ->{oidcRPMetaDataOptionsOfflineSessionExpiration}
                  || $self->conf->{oidcServiceOfflineSessionExpiration} )
            : $self->conf->{timeout},
            {
                %userInfo,
                redirect_uri => $oidcSession->{redirect_uri},
                scope        => $req->data->{oidcNativeSso}->{scope},
                client_id    => $self->conf->{oidcRPMetaDataOptions}->{$rp}
                  ->{oidcRPMetaDataOptionsClientID},
                _session_uid => $sessionInfo->{_user},
                auth_time    => $sessionInfo->{_lastAuthnUTime},
                grant_type   => "authorizationcode",
                id_token_h   => sha256_hex( $tokenResponse->{id_token} ),
            },
        );
        $tokenResponse->{device_secret} = $deviceSecret->id;
    }
    return PE_OK;
}

use constant T_LOG_PREFIX => 'Native SSO token exchange: ';

# STEP 3: give new access_token when device_secret is valid
sub tokenExchangeHook {
    my ( $self, $req, $rp ) = @_;

    # Ignore request if token exchange isn't for this plugin
    return PE_OK
      unless $req->param('actor_token_type') eq
      'urn:x-oath:params:oauth:token-type:device-secret';

    if ( $self->conf->{oidcRPMetaDataOptions}->{$rp}
        ->{oidcRPMetaDataOptionsAllowNativeSso} )
    {
        # STEP 3.1: Check parameters

        # Required parameter list
        foreach (
            qw(audience subject_token subject_token_type actor_token actor_token_type)
          )
        {
            unless ( $req->param($_) ) {
                $self->userLogger->error( T_LOG_PREFIX . "missing $_" );
                return PE_ERROR;
            }
        }

        # Check for static parameters
        unless ( $req->param('subject_token_type') eq
            'urn:ietf:params:oauth:token-type:id_token' )
        {
            $self->userLogger->error(
                T_LOG_PREFIX . 'Bad subject_token_type or actor_token_type' );
            return PE_ERROR;
        }

        # Check for audience that should be the issuer
        # (given by "iss" field of id_token)

        unless ( $req->param('audience') eq $self->oidc->iss ) {
            $self->userLogger->error( T_LOG_PREFIX
                  . 'missing or bad audience '
                  . $req->param('audience') );
            return PE_ERROR;
        }

        # Check for device_secret
        my $deviceSecret = $req->param('actor_token');
        my $session =
          $self->oidc->getOpenIDConnectSession( $deviceSecret,
            "device_secret" );
        unless ($session) {
            $self->userLogger->error(
                T_LOG_PREFIX . "bad device_secret $deviceSecret" );
            return PE_ERROR;
        }

        # Check for id_token
        my $idTokenHint = $req->param('subject_token');
        unless ( sha256_hex($idTokenHint) eq $session->data->{id_token_h} ) {
            $self->userLogger->error(
                T_LOG_PREFIX . 'subject_token does not match actor_token' );
            return PE_ERROR;
        }

        # Check also for ds_hash
        my $dsHash = getJWTPayload($idTokenHint)->{ds_hash};
        unless ( $dsHash eq $session->data->{ds_hash} ) {
            $self->userLogger->error( T_LOG_PREFIX . 'ds_hash mismatch' );
            return PE_ERROR;
        }

        # STEP 3.2: generate new refresh_token and access_token
        my ( $access_token, $refresh_token );

        $self->oidc->getAttributesForUser( $req, $session ) or return PE_ERROR;

        if (
            $self->oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsAllowOffline} )
        {
            my %refreshInfo = (
                map {
/^(?:_session_.*|_utime$|ds_hash|id_token_h|client_id|redirect_uri|_type)$/
                      ? ()
                      : ( $_ => $session->data->{$_} )
                } keys %{ $session->data }
            );
            my $refreshTokenSession = $self->oidc->newRefreshToken(
                $rp,
                {
                    %refreshInfo,

                    # TODO: adapt scope if asked
                    #scope =>
                    client_id => $self->oidc->rpOptions->{$rp}
                      ->{oidcRPMetaDataOptionsClientID},
                    _session_uid => $session->data->{_session_uid},
                    auth_time    => $session->data->{_lastAuthnUTime},
                }
            );
            $refresh_token = $refreshTokenSession->id;
        }

        $access_token = $self->oidc->newAccessToken(
            $req, $rp,
            $session->data->{scope},
            $session->data,
            {
                # TODO: offline_session_id must point to refresh_token
                offline_session_id => $refresh_token,
                grant_type         => $session->data->{grant_type},
            }
        );

        unless ($access_token) {
            $self->userLogger->error("Unable to create Access Token");
            return PE_ERROR;
        }

        # Send response

        my $response = {
            issued_token_type =>
              'urn:ietf:params:oauth:token-type:access_token',
            token_type   => 'Bearer',
            access_token => $access_token,
            expires_in   => 'TODO',
            ( $refresh_token ? ( refresh_token => $refresh_token ) : () ),
        };

        $req->response( $self->p->sendJSONresponse( $req, $response ) );
        return PE_SENDRESPONSE;
    }
    else {
        $self->userLogger->error(
            "$rp isn't allowed to request for a device_secret");
        return PE_ERROR;
    }

    # Else ignore this request
    return PE_OK;
}

1;
