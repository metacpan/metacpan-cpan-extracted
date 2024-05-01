# Trusted Browser service
# This package provides the ability to remember a browser across SSO logins
# It is meant to be used by multiple features
# - Auto-login (StayConnected)
# - 2FA bypass
#
# Browser registration is entirely handled by this plugin, and trigger by setting
# $req->param('stayconnected'), usually by the user clicking a checkbox.
# Request state is handled automatically during browser registration.
#
# This plugin sets a _trustedBrowser session variable that can be used in 2FA
# activation rules or other Portal features and plugins

package Lemonldap::NG::Portal::Plugins::TrustedBrowser;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_SENDRESPONSE
);

our $VERSION = '2.19.0';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
  Lemonldap::NG::Common::TOTP
);

# INTERFACE

use constant beforeLogout => 'logout';

# INITIALIZATION
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);
has cookieName => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedCookieName} || 'llngconnection';
    }
);
has singleSession => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedSingleSession};
    }
);

# Default timeout: 1 month
has timeout => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedTimeout} || 2592000;
    }
);

has rule => (
    is      => 'rw',
    default => sub {
        sub { 0 }
    }
);

sub init {
    my ($self) = @_;
    $self->addUnauthRoute( registerbrowser => 'storeBrowser', ['POST'] );
    $self->addAuthRoute( registerbrowser => 'storeBrowser', ['POST'] );
    $self->addUnauthRoute( checkbrowser => 'checkBrowserReturn', ['POST'] );
    $self->addAuthRoute( checkbrowser => 'checkBrowserReturn', ['POST'] );

    # Parse activation rule
    if ( $self->conf->{trustedBrowserRule} ) {
        $self->rule(
            $self->p->buildRule(
                $self->conf->{trustedBrowserRule},
                'trustedBrowserRule'
            )
        );
        return 0 unless $self->rule;
    }

    # Enable with an all-allowing rule if stayConnected is used,
    # for backward-compatibility
    elsif ( $self->conf->{stayConnected} ) {
        $self->rule( sub { 1 } );
    }

    return 1;
}

# RUNNING METHODS

# This method is called by the portal in standard auth flows

sub newDevice {
    my ( $self, $req ) = @_;

    if ( $req->param('stayconnected') ) {

        if ( $req->sessionInfo->{_trustedBrowser} ) {
            $self->logger->debug( "User "
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . "asked to trust his web browser but is already trusted" );
            return PE_OK;
        }

        if ( $self->rule->( $req, $req->sessionInfo ) ) {
            my $totpSecret = $self->newSecret;

            my $state = $self->_getRegisterStateTplParams( $req, $totpSecret );
            $req->response(
                $self->p->sendHtml(
                    $req,
                    '../common/registerBrowser',
                    params => {
                        TOTPSEC => $totpSecret,
                        ACTION  => '/registerbrowser',
                        %$state,
                    }
                )
            );
            return PE_SENDRESPONSE;
        }
        else {
            $self->userLogger->info( "User "
                  . $req->sessionInfo->{ $self->conf->{whatToTrace} }
                  . "asked to trust his web browser but was denied by rule" );
        }
    }
    return PE_OK;
}

# Store TOTP secret + request state into a temporary session
# and return relevant template parameters
sub _getRegisterStateTplParams {
    my ( $self, $req, $totpSecret ) = @_;

    my $checkLogins = $req->param('checkLogins') || 0;
    my $url         = $req->urldc;
    my $token       = $self->ott->createToken( {
            id          => $req->id,
            sessionInfo => $req->sessionInfo,
            totpSecret  => $totpSecret,
        }
    );
    my %state = (
        CHECKLOGINS => $checkLogins,
        URL         => $url,
        TOKEN       => $token,
    );
    return \%state;
}

# This method handles the browser response to the registerBrowser JS code
# and persists the registration
sub storeBrowser {
    my ( $self, $req ) = @_;

    if ( my $totpSecret = $self->_restoreRegisterState($req) ) {
        my $name       = $req->sessionInfo->{ $self->conf->{whatToTrace} };
        my $authnLevel = $req->sessionInfo->{authenticationLevel};
        if ( my $fg = $req->param('fg') ) {
            my $isTotp = ( $fg =~ s/^TOTP_// ) ? 1 : 0;
            if ( $isTotp
                and !$self->verifyCode( 30, 1, 6, $totpSecret, $fg ) )
            {
                $self->logger->warn( "Failed to register device, bad TOTP, "
                      . "device will not be remembered" );
            }
            else {
                my $ps = $self->newConnectionSession( { (
                            _session_uid        => $name,
                            authenticationLevel => $authnLevel,
                            $isTotp
                            ? ( totpSecret => $totpSecret )
                            : ( fingerprint => $fg )
                        ),
                    },
                );

                # Cookie available 30 days by default
                $req->addCookie(
                    $self->p->genCookie(
                        $req,
                        name    => $self->cookieName,
                        value   => $ps->id,
                        max_age => $self->timeout,
                        secure  => $self->conf->{securedCookie},
                    )
                );

                # Store connection ID in current session
                $self->p->updateSession( $req,
                    { _stayConnectedSession => $ps->id } );
            }
        }
        else {
            $self->logger->warn( "Browser did not return fingerprint, "
                  . "browser will not be remembered" );
        }
    }
    else {
        $self->userLogger->error(
            "Cannot restore trusted browser registration state");
        return $self->p->do( $req, [ sub { PE_ERROR } ] );
    }

    # Resume normal login flow
    $req->mustRedirect(1);
    return $self->p->do( $req,
        [ 'buildCookie', @{ $self->p->endAuth }, sub { PE_OK } ] );
}

sub _restoreRegisterState {
    my ( $self, $req ) = @_;

    if ( my $token = $req->param('token') ) {
        if ( my $saved_state = $self->ott->getToken($token) ) {

            # checkLogins is restored automatically as a request parameter
            $req->urldc( $req->param('url') );
            $req->sessionInfo( $saved_state->{sessionInfo} );
            $req->id( $saved_state->{id} );
            return $saved_state->{totpSecret};
        }
        else {
            $self->userLogger->error("Invalid trusted browser state token");
        }
    }
    else {
        $self->userLogger->error('Missing trusted browser state token');
    }
    return;

}

sub getTrustedBrowserSessionFromReq {
    my ( $self, $req ) = @_;

    if ( my $cid = $req->cookies->{ $self->cookieName } ) {
        my $session = $self->getTrustedBrowserSession($cid);
        if ($session) {
            return $session;
        }
        else {
            $self->removeCookie($req);
            return;
        }
    }
    else {
        $self->logger->debug("No trusted browser cookie was sent");
    }
    return;
}

sub getTrustedBrowserSession {
    my ( $self, $cid, $raw ) = @_;
    my $ps = Lemonldap::NG::Common::Session->new(
        hashStore            => $raw ? 0 : $self->{conf}->{hashedSessionStore},
        storageModule        => $self->conf->{globalStorage},
        storageModuleOptions => $self->conf->{globalStorageOptions},
        kind                 => "SSO",
        id                   => $cid,
    );
    if ( $ps->data->{_session_uid} and ( time() < $ps->data->{_utime} ) ) {
        $self->logger->debug('Persistent connection found');
        return $ps;
    }
    else {
        $self->userLogger->notice('Persistent connection expired');
        unless ( $ps->{error} ) {
            $self->logger->debug(
                'Persistent connection session id = ' . $ps->{id} );
            $self->logger->debug( 'Persistent connection session _utime = '
                  . $ps->data->{_utime} );
            $ps->remove;
        }
    }
    return;
}

sub _hasFingerprintParams {
    my ( $self, $req ) = @_;
    return ( $req->param('fg') and $req->param('token') );
}

sub mustChallenge {
    my ( $self, $req, $expected_user ) = @_;

    my $ps = $self->getTrustedBrowserSessionFromReq($req);
    if ( $ps and not( $self->_hasFingerprintParams($req) ) ) {
        if ($expected_user) {
            return (  $ps->data->{_session_uid}
                  and $ps->data->{_session_uid} eq $expected_user );
        }
        else {
            return 1;
        }
    }
    return 0;
}

sub getKnownBrowserState {
    my ( $self, $req ) = @_;

    my $ps = $self->getTrustedBrowserSessionFromReq($req);
    if ( $ps and $self->_hasFingerprintParams($req) ) {
        my $fg         = $req->param('fg');
        my $token      = $req->param('token');
        my $uid        = $ps->data->{_session_uid};
        my $authnLevel = $ps->data->{authenticationLevel};

        my $token_data = $self->ott->getToken($token);
        return unless $token_data;

        if ( $self->checkFingerprint( $req, $ps, $uid, $fg ) ) {
            return {
                _trustedUser          => $uid,
                _trustedAuthnLevel    => $authnLevel,
                _stayConnectedSession => $ps->id,
                data                  => $token_data,
            };
        }
        else {
            $self->userLogger->warn("Fingerprint changed for $uid");
            $ps->remove;
            $self->logout($req);
        }
    }
    else {
        $self->logger->debug("No fingerprint or token parameter was sent");
    }
    return;
}

sub checkFingerprint {
    my ( $self, $req, $ps, $uid, $fg ) = @_;
    $self->logger->debug('Persistent connection found');
    if ( $self->conf->{stayConnectedBypassFG} ) {
        return 1;
    }
    else {
        if ( $fg =~ s/^TOTP_// ) {
            return 1
              if (
                $self->verifyCode( 30, 1, 6, $ps->data->{totpSecret}, $fg ) >
                0 );
        }
        elsif ( $fg eq $ps->data->{fingerprint} ) {
            return 1;
        }
    }
    return 0;
}

sub challenge {
    my ( $self, $req, $action, $info ) = @_;
    my $token = $self->ott->createToken($info);
    $req->response(
        $self->p->sendHtml(
            $req,
            '../common/registerBrowser',
            params => {
                TOKEN  => $token,
                ACTION => $action,
            }
        )
    );
    return PE_SENDRESPONSE;
}

sub logout {
    my ( $self, $req ) = @_;
    $self->removeCookie($req);

    # Try to clean stayconnected cookie
    my $cid = $req->sessionInfo->{_stayConnectedSession};
    if ($cid) {
        my $ps = $self->getTrustedBrowserSession($cid);
        if ($ps) {
            $self->logger->debug("Cleaning up StayConnected session $cid");
            $ps->remove;
        }
    }

    return PE_OK;
}

sub removeCookie {
    my ( $self, $req ) = @_;

    $req->addCookie(
        $self->p->genCookie(
            $req,
            name    => $self->cookieName,
            value   => 0,
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
            secure  => $self->conf->{securedCookie},
        )
    );
}

sub removeExistingSessions {
    my ( $self, $uid ) = @_;
    $self->logger->debug("StayConnected: removing all sessions for $uid");

    my $sessions =
      $self->module->searchOn( $self->moduleOpts, '_session_uid', $uid );

    # searchOn() returns sessions indexed by their storage ID, then
    # it is required to use hashed ID
    foreach ( keys %{ $sessions || {} } ) {
        if ( my $ps = $self->getTrustedBrowserSession($_, 1) ) {

            # If this is a StayConnected session, remove it
            $ps->remove if $ps->{data}->{_connectedSince};
            $self->logger->debug("StayConnected removed session $_");
        }
        else {
            $self->logger->debug("StayConnected session $_ expired");
        }
    }
}

sub newConnectionSession {
    my ( $self, $info ) = @_;

    $info ||= {};

    # Remove existing sessions
    if ( $self->singleSession ) {
        $self->removeExistingSessions( $info->{_session_uid} );
    }

    return Lemonldap::NG::Common::Session->new(
        hashStore            => $self->{conf}->{hashedSessionStore},
        storageModule        => $self->conf->{globalStorage},
        storageModuleOptions => $self->conf->{globalStorageOptions},
        kind                 => "SSO",
        info                 => {
            _utime          => time + $self->timeout,
            _connectedSince => time,
            %$info,
        }
    );
}

sub check {
    my ( $self, $req ) = @_;

    if (
        $self->mustChallenge(
            $req, $req->sessionInfo->{ $self->conf->{whatToTrace} }
        )
      )
    {
        return $self->challenge(
            $req,
            '/checkbrowser',
            {
                _challenge_session_info => $req->sessionInfo,
                _challenge_urldc        => $req->urldc
            }
        );
    }
    return PE_OK;
}

sub checkBrowserReturn {
    my ( $self, $req ) = @_;
    my $state = $self->getKnownBrowserState($req);

    if ($state) {

        # Restore state
        my $sessionInfo = $state->{data}->{_challenge_session_info};
        my $urldc       = $state->{data}->{_challenge_urldc};
        return $self->p->do( $req, [ sub { PE_ERROR } ] ) unless $sessionInfo;
        $req->urldc($urldc) if $urldc;
        $req->sessionInfo($sessionInfo);

        $req->sessionInfo->{_trustedBrowser} = 1;
        $req->sessionInfo->{_stayConnectedSession} =
          $state->{_stayConnectedSession};
        my $authn_level_from_trusted = $state->{_trustedAuthnLevel};
        my $authn_level_from_auth    = $sessionInfo->{authenticationLevel};
        my $new_authn_level =
          ( $authn_level_from_trusted > $authn_level_from_auth )
          ? $authn_level_from_trusted
          : undef;

        if ($new_authn_level) {
            $req->sessionInfo->{authenticationLevel} = $new_authn_level;
        }

        $req->mustRedirect(1);

        # Resume login
        return $self->p->do(
            $req,
            [
                'store',                  'secondFactor',
                @{ $self->p->afterData }, $self->p->validSession,
                @{ $self->p->endAuth },   sub { PE_OK }
            ]
        );

    }
    else {
        $self->logger->error("Trusted browser failed fingerprint challenge");
    }
    $req->noLoginDisplay(1);
    return $self->p->do( $req, [ sub { PE_ERROR } ] );
}

1;
