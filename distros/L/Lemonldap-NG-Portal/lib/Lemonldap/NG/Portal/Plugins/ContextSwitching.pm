package Lemonldap::NG::Portal::Plugins::ContextSwitching;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_REDIRECT
  PE_TOKENEXPIRED
  PE_MALFORMEDUSER
  PE_BADCREDENTIALS
  PE_SESSIONEXPIRED
  PE_IMPERSONATION_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.15';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
  Lemonldap::NG::Portal::Lib::OtherSessions
);

# INITIALIZATION

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);
has rule                  => ( is => 'rw', default => sub { 0 } );
has idRule                => ( is => 'rw', default => sub { 1 } );
has unrestrictedUsersRule => ( is => 'rw', default => sub { 0 } );

sub init {
    my ($self) = @_;
    $self->addAuthRoute( switchcontext => 'run', ['POST'] )
      ->addAuthRoute( switchcontext => 'display', ['GET'] );

    # Parse ContextSwitching rules
    $self->rule(
        $self->p->buildRule(
            $self->conf->{contextSwitchingRule},
            'contextSwitching'
        )
    );
    return 0 unless $self->rule;

    $self->idRule(
        $self->p->buildRule(
            $self->conf->{contextSwitchingIdRule},
            'contextSwitchingId'
        )
    );
    return 0 unless $self->idRule;

    $self->unrestrictedUsersRule(
        $self->p->buildRule(
            $self->conf->{contextSwitchingUnrestrictedUsersRule},
            'contextSwitchingUnrestrictedUsers'
        )
    );
    return 0 unless $self->unrestrictedUsersRule;

    return 1;
}

# RUNNING METHOD

sub display {
    my ( $self, $req ) = @_;
    my ( $realSession, $realSessionId );
    if ( $realSessionId =
        $req->userData->{"$self->{conf}->{contextSwitchingPrefix}_session_id"} )
    {
        unless ( $realSession = $self->p->getApacheSession($realSessionId) ) {
            $self->userLogger->info(
                "ContextSwitching: session $realSessionId expired");
            return $self->p->do( $req, [ sub { PE_SESSIONEXPIRED } ] );
        }
    }

    # Check access rules
    unless ( $self->rule->( $req, $req->userData )
        || $req->userData->{
            "$self->{conf}->{contextSwitchingPrefix}_session_id"} )
    {
        $self->userLogger->warn('ContextSwitching service NOT authorized');
        return $self->p->do( $req,
            [ sub { PE_IMPERSONATION_SERVICE_NOT_ALLOWED } ] );
    }

    if (
        $req->userData->{"$self->{conf}->{contextSwitchingPrefix}_session_id"} )
    {
        $self->logger->debug('Request to stop ContextSwitching');
        if ( $self->conf->{contextSwitchingStopWithLogout} ) {
            $self->userLogger->notice("Stop ContextSwitching for $req->{user}");
            $self->userLogger->info("Remove real session $realSessionId");
            $realSession->remove;
            return $self->p->do( $req,
                [ @{ $self->p->beforeLogout }, 'authLogout', 'deleteSession' ]
            );

        }
        else {
            $req = $self->_abortImpersonation( $req, $req->{user},
                $realSession->data->{ $self->conf->{whatToTrace} }, 0 );
            $self->p->updateSession( $req, $req->userData );
            return $self->p->do( $req, [ sub { PE_REDIRECT } ] );
        }
    }

    # Display form
    my $params = {
        MSG           => 'contextSwitching_ON',
        ALERTE        => 'alert-danger',
        IMPERSONATION => $self->conf->{contextSwitchingRule},
        TOKEN         => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };

    return $self->p->sendHtml( $req, 'contextSwitching', params => $params, );
}

sub run {
    my ( $self, $req ) = @_;
    my $statut  = PE_OK;
    my $realId  = $req->userData->{ $self->conf->{whatToTrace} };
    my $spoofId = $req->param('spoofId') || '';    # ContextSwitching required ?
    my $unUser  = $self->unrestrictedUsersRule->( $req, $req->userData ) || 0;

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token = $req->param('token');
        unless ($token) {
            $self->userLogger->warn('ContextSwitching called without token');
            return $self->p->do( $req, [ sub { PE_NOTOKEN } ] );
        }
        unless ( $self->ott->getToken($token) ) {
            $self->userLogger->warn(
                'ContextSwitching called with an expired/bad token');
            return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
        }
    }

    # Check activation rule
    unless ( $self->rule->( $req, $req->userData ) ) {
        $self->userLogger->warn('ContextSwitching service NOT authorized');
        $spoofId = '';
        return $self->p->do( $req,
            [ sub { PE_IMPERSONATION_SERVICE_NOT_ALLOWED } ] );
    }

    # ContextSwitching required -> Check user Id
    if ( $spoofId && $spoofId ne $req->{user} ) {
        $self->logger->debug("Spoofed Id: $spoofId");
        unless ( $spoofId =~ /$self->{conf}->{userControl}/o ) {
            $self->userLogger->warn('Malformed spoofed Id');
            $self->logger->debug(
                "ContextSwitching tried with spoofed Id: $spoofId");
            return $self->p->do( $req, [ sub { PE_MALFORMEDUSER } ] );
        }
    }
    else {
        $self->logger->debug("contextSwitching NOT required");
        $req->urldc( $self->conf->{portal} );
        return $self->p->do( $req, [ sub { PE_OK } ] );
    }

    # Create spoofed session
    $req = $self->_switchContext( $req, $spoofId, $unUser );
    $statut =
      ( $req->error == PE_BADCREDENTIALS ? PE_MALFORMEDUSER : $req->error )
      if $req->error;

    # Main session
    $self->p->updateSession( $req, $req->sessionInfo );
    $self->userLogger->notice(
"ContextSwitching: Update \"$realId\" session with \"$spoofId\" session data"
    );

    $req->mustRedirect(1);
    return $self->p->do( $req, [ sub { $statut } ] );
}

sub _switchContext {
    my ( $self, $req, $spoofId, $unUser ) = @_;
    my $realSessionId = $req->userData->{_session_id};
    my $realAuthLevel = $req->userData->{authenticationLevel};
    my $realId        = $req->userData->{ $self->conf->{whatToTrace} };
    my $raz           = 0;
    $req->{user} = $spoofId;

    # Search user in database & create session
    $req->steps( [
            'getUser',                  'setAuthSessionInfo',
            'setSessionInfo',           $self->p->groupsAndMacros,
            'setPersistentSessionInfo', 'setLocalGroups',
            'store',                    'buildCookie'
        ]
    );
    if ( my $error = $self->p->process($req) ) {
        $self->userLogger->warn(
                'ContextSwitching requested for an invalid user ('
              . $req->{user}
              . ")" )
          if ( $error == PE_BADCREDENTIALS );
        $self->logger->debug("Process returned error: $error");
        $req->error($error);
        $raz = 1;
    }

    # Check identities rule if ContextSwitching required
    $self->logger->info("\"$realId\" is an unrestricted user!") if $unUser;
    unless ( $unUser || $self->idRule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->warn(
                'ContextSwitching requested for an invalid user ('
              . $req->{user}
              . ")" );
        $self->logger->debug('Identity NOT authorized');
        $req->error(PE_MALFORMEDUSER);    # Catch error to preserve protected Id
        $raz = 1;
    }

    $req->sessionInfo->{"$self->{conf}->{contextSwitchingPrefix}_session_id"} =
      $realSessionId;

    return $self->_abortImpersonation( $req, $spoofId, $realId, 1 ) if $raz;

    $self->logger->debug(
        "Update sessionInfo with real authenticationLevel: $realAuthLevel");
    $req->sessionInfo->{authenticationLevel} = $realAuthLevel;
    delete $req->sessionInfo->{groups};

    # Compute groups & macros again with real authenticationLevel
    $req->steps(
        [ 'setSessionInfo', $self->p->groupsAndMacros, 'setLocalGroups' ] );
    if ( my $error = $self->p->process($req) ) {
        $self->logger->debug(
            "ContextSwitching: Process returned error: $error");
        $req->error($error);
    }

    $self->userLogger->notice(
        "Start ContextSwitching: \"$realId\" becomes \"$spoofId\"");
    return $req;
}

sub _abortImpersonation {
    my ( $self, $req, $spoofId, $realId, $abort ) = @_;
    my $type = $abort ? 'sessionInfo' : 'userData';
    my $realSessionId =
      $req->{$type}->{"$self->{conf}->{contextSwitchingPrefix}_session_id"};
    my $session;
    unless ( $session = $self->p->getApacheSession($realSessionId) ) {
        $self->userLogger->info("Session $session expired");
        return $req->error(PE_SESSIONEXPIRED);
    }

    if ($abort) {
        $self->userLogger->notice(
            "Abort ContextSwitching: \"$spoofId\" by \"$realId\"");
        if ( my $abortSession = $self->p->getApacheSession( $req->id ) ) {
            $abortSession->remove;
        }
        else {
            $self->userLogger->info(
                "ContextSwitching: session " . $req->id . " expired" );
        }
    }
    else {
        $self->userLogger->notice(
            "Stop ContextSwitching for \"$realId\" with uid \"$spoofId\"");
        $self->p->deleteSession($req);
    }

    # Restore real session
    $req->{$type} = { %{ $session->data } };
    $req->{user} = $session->data->{_user};
    $req->urldc( $self->conf->{portal} );
    $req->id($realSessionId);
    $self->p->buildCookie($req);
    delete $req->{$type}
      ->{"$self->{conf}->{contextSwitchingPrefix}_session_id"};

    return $req;
}

sub displayLink {
    my ( $self, $req ) = @_;
    return 'OFF'
      if $req->userData->{"$self->{conf}->{contextSwitchingPrefix}_session_id"};
    return 'ON' if $self->rule->( $req, $req->userData );
}

1;
