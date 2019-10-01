package Lemonldap::NG::Portal::Plugins::ContextSwitching;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_REDIRECT
  PE_MALFORMEDUSER
  PE_BADCREDENTIALS
  PE_SESSIONEXPIRED
  PE_IMPERSONATION_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.6';

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
has rule   => ( is => 'rw', default => sub { 1 } );
has idRule => ( is => 'rw', default => sub { 1 } );

sub init {
    my ($self) = @_;
    my $hd = $self->p->HANDLER;
    $self->addAuthRoute( switchcontext => 'run', ['POST'] )
      ->addAuthRoute( switchcontext => 'display', ['GET'] );

    # Parse activation rule
    $self->logger->debug(
        'ContextSwitching rule -> ' . $self->conf->{contextSwitchingRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{contextSwitchingRule} ) );
    unless ($rule) {
        $self->error(
            'Bad contextSwitching rule -> ' . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->rule($rule);

    # Parse identity rule
    $self->logger->debug( "ContextSwitching identities rule -> "
          . $self->conf->{contextSwitchingIdRule} );
    $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{contextSwitchingIdRule} ) );
    unless ($rule) {
        $self->error( "Bad contextSwitching identities rule -> "
              . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->idRule($rule);

    return 1;
}

# RUNNING METHOD

sub display {
    my ( $self, $req ) = @_;
    my $realSessionId =
      $req->userData->{"$self->{conf}->{impersonationPrefix}_session_id"};
    my $realSession;
    unless ( $realSession = $self->p->getApacheSession($realSessionId) ) {
        $self->userLogger->info(
            "ContextSwitching: session $realSessionId expired");
        return $self->p->do( $req, [ sub { PE_SESSIONEXPIRED } ] );
    }

    # Check access rules
    unless ( $self->rule->( $req, $req->userData )
        || $req->userData->{"$self->{conf}->{impersonationPrefix}_session_id"} )
    {
        $self->userLogger->warn('ContextSwitching service NOT authorized');
        return $self->p->do( $req,
            [ sub { PE_IMPERSONATION_SERVICE_NOT_ALLOWED } ] );
    }

    if ( $req->userData->{"$self->{conf}->{impersonationPrefix}_session_id"} ) {
        $self->logger->debug('Request to stop ContextSwitching');
        if ( $self->conf->{contextSwitchingStopWithLogout} ) {
            $self->userLogger->notice("Stop ContextSwitching for $req->{user}");
            $self->userLogger->info("Remove real session $realSession");
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
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        SKIN      => $self->p->getSkin($req),
        LANGS     => $self->conf->{showLanguages},
        MSG       => 'contextSwitching_ON',
        ALERTE    => 'alert-danger',
        LOGIN     => '',
        SPOOFID   => $self->conf->{contextSwitchingRule},
        TOKEN     => (
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
    my $realId  = $req->{user};
    my $spoofId = $req->param('spoofId') || '';    # ContextSwitching required ?

    # Check activation rule
    unless ( $self->rule->( $req, $req->userData ) ) {
        $self->userLogger->warn('ContextSwitching service NOT authorized');
        $spoofId = '';
        return $self->p->do( $req,
            [ sub { PE_IMPERSONATION_SERVICE_NOT_ALLOWED } ] );
    }

    # ContextSwitching required -> Check user Id
    if ( $spoofId && $spoofId ne $req->{user} ) {
        $self->logger->debug("Spoof Id: $spoofId");
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
    $req = $self->_switchContext( $req, $spoofId );
    if ( $req->error ) {
        if ( $req->error == PE_BADCREDENTIALS ) {
            $statut = PE_MALFORMEDUSER;
        }
        else {
            $statut = $req->error;
        }
    }

    # Main session
    $self->p->updateSession( $req, $req->sessionInfo );
    $self->userLogger->notice(
        "ContextSwitching: Update $realId session with $spoofId session data");

    return $self->p->do( $req, [ sub { $statut } ] );
}

sub _switchContext {
    my ( $self, $req, $spoofId ) = @_;
    my $realSessionId = $req->userData->{_session_id};
    my $realId        = $req->{user};
    my $raz           = 0;
    $req->{user} = $spoofId;

    # Search user in database & create session
    $req->steps( [
            'getUser',        'setAuthSessionInfo',
            'setSessionInfo', 'setMacros',
            'setGroups',      'setPersistentSessionInfo',
            'setLocalGroups', 'store',
            'buildCookie'
        ]
    );
    if ( my $error = $self->p->process($req) ) {
        if ( $error == PE_BADCREDENTIALS ) {
            $self->userLogger->warn(
                    'ContextSwitching requested for an unvalid user ('
                  . $req->{user}
                  . ")" );
        }
        $self->logger->debug("Process returned error: $error");
        $req->error($error);
        $raz = 1;
    }

    # Check identity rule if ContextSwitching required
    unless ( $self->idRule->( $req, $req->sessionInfo ) ) {
        $self->userLogger->warn(
                'ContextSwitching requested for an unvalid user ('
              . $req->{user}
              . ")" );
        $self->logger->debug('Identity NOT authorized');
        $req->error(PE_MALFORMEDUSER);    # Catch error to preserve protected Id
        $raz = 1;
    }

    $req->sessionInfo->{"$self->{conf}->{impersonationPrefix}_session_id"} =
      $realSessionId;
    $self->userLogger->notice(
        "Start ContextSwitching: $realId becomes $spoofId ")
      unless $raz;

    return $raz
      ? $self->_abortImpersonation( $req, $spoofId, $realId, 1 )
      : $req;
}

sub _abortImpersonation {
    my ( $self, $req, $spoofId, $realId, $abort ) = @_;
    my $type = $abort ? 'sessionInfo' : 'userData';
    my $realSessionId =
      $req->{$type}->{"$self->{conf}->{impersonationPrefix}_session_id"};
    my $session;
    unless ( $session = $self->p->getApacheSession($realSessionId) ) {
        $self->userLogger->info("Session $session expired");
        return $req->error(PE_SESSIONEXPIRED);
    }

    if ($abort) {
        $self->userLogger->notice(
            "Abort ContextSwitching: $spoofId by $realId");
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
            "Stop ContextSwitching for $realId with uid $spoofId");
        $self->p->deleteSession($req);
    }

    # Restore real session
    $req->{$type} = { %{ $session->data } };
    $req->{user} = $session->data->{_user};
    $req->urldc( $self->conf->{portal} );
    $req->id($realSessionId);
    $self->p->buildCookie($req);
    delete $req->{$type}->{"$self->{conf}->{impersonationPrefix}_session_id"};

    return $req;
}

sub displaySwitchContext {
    my ( $self, $req ) = @_;
    return 'OFF'
      if $req->userData->{"$self->{conf}->{impersonationPrefix}_session_id"};
    return 'ON' if $self->rule->( $req, $req->userData );
}

1;
