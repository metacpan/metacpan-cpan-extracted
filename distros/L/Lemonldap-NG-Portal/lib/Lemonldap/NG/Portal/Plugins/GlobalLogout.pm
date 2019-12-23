package Lemonldap::NG::Portal::Plugins::GlobalLogout;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_SENDRESPONSE
);

our $VERSION = '2.0.7';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
);

# INTERFACE
use constant beforeLogout => 'run';

# INITIALIZATION
has rule => ( is => 'rw', default => sub { 0 } );
has ott  => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    $self->addAuthRoute( globallogout => 'globalLogout', [ 'POST', 'GET' ] );

    # Parse activation rule
    my $hd = $self->p->HANDLER;
    $self->logger->debug(
        "GlobalLogout rule -> " . $self->conf->{globalLogoutRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{globalLogoutRule} ) );
    unless ($rule) {
        $self->error( "Bad globalLogout rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->rule($rule);

    return 1;
}

# RUNNING METHODS
# Look for user active SSO sessions and propose to close them
sub run {
    my ( $self, $req ) = @_;
    my $user = $req->{userData}->{ $self->conf->{whatToTrace} };

    # Check activation rules
    unless ( $self->rule->( $req, $req->userData ) ) {
        $self->userLogger->info("Global logout not required for $user");
        return PE_OK;
    }

    # Looking for active sessions
    my $sessions = $self->activeSessions($req);
    my $nbr      = @{$sessions};
    $self->logger->debug("GlobalLogout: $nbr session(s) found") if $nbr;
    return PE_OK unless ( $nbr > 1 );

    # Force GlobalLogout if timer is disabled
    unless ( $self->conf->{globalLogoutTimer} ) {
        $self->logger->debug("GlobalLogout: timer disabled");
        $self->userLogger->info("GlobalLogout: force global logout for $user");
        $nbr = $self->removeOtherActiveSessions( $req, $sessions );
        $self->userLogger->info("$nbr remaining session(s) removed");

        return PE_OK;
    }

    # Prepare token
    my $token = $self->ott->createToken( {
            user     => $user,
            sessions => to_json($sessions)
        }
    );

    # Prepare form
    $self->logger->debug("Prepare global logout confirmation");
    my $tmp = $self->p->sendHtml(
        $req,
        'globallogout',
        params => {
            PORTAL    => $self->conf->{portal},
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->p->getSkin($req),
            LANGS     => $self->conf->{showLanguages},
            SESSIONS  => $sessions,
            TOKEN     => $token,
            LOGIN     => $user,
        }
    );
    $req->response($tmp);

    return PE_SENDRESPONSE;
}

sub globalLogout {
    my ( $self, $req ) = @_;
    my $count = 0;

    if ( $req->param('all') ) {
        if ( my $token = $req->param('token') ) {
            if ( $token = $self->ott->getToken($token) ) {

                # Read active sessions from token
                my $sessions = eval { from_json( $token->{sessions} ) };
                if ($@) {
                    $self->logger->error("Bad encoding in OTT: $@");
                    return PE_ERROR;
                }
                my $as;
                foreach (@$sessions) {
                    unless ( $as = $self->p->getApacheSession( $_->{id} ) ) {
                        $self->userLogger->info(
                            "GlobalLogout: session $_->{id} expired");
                        next;
                    }
                    my $user = $token->{user};
                    if ( $req->{userData}->{ $self->{conf}->{whatToTrace} } eq
                        $user )
                    {
                        unless ( $req->{userData}->{_session_id} eq $_->{id} ) {
                            $self->userLogger->info(
                                "Remove \"$user\" session: $_->{id}");
                            $as->remove;
                            $count++;
                        }
                    }
                    else {
                        $self->userLogger->warn(
                            "GlobalLogout called with an unvalid token");
                        return PE_TOKENEXPIRED;
                    }
                }
            }
            else {
                $self->userLogger->error(
                    "GlobalLogout called with an expired token");
                return PE_TOKENEXPIRED;
            }
        }
        else {
            $self->userLogger->error('GlobalLogout called without token');
            return PE_NOTOKEN;
        }
    }
    $self->userLogger->info("$count remaining session(s) removed");

    return $self->p->do( $req, [ 'authLogout', 'deleteSession' ] );
}

sub activeSessions {
    my ( $self, $req ) = @_;
    my $activeSessions = [];
    my $sessions       = {};
    my $user           = $req->{userData}->{ $self->conf->{whatToTrace} };

    # Try to retrieve session from sessions DB
    $self->logger->debug('Try to retrieve session from DB');
    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};
    $self->logger->debug("Looking for \"$user\" sessions...");
    $sessions =
      $self->module->searchOn( $moduleOptions, $self->conf->{whatToTrace},
        $user );

    $self->logger->debug("Building array ref with sessions info...");
    @$activeSessions = map { {
            id         => $_,
            UA         => $sessions->{$_}->{'UA'},
            ipAddr     => $sessions->{$_}->{'ipAddr'},
            authLevel  => $sessions->{$_}->{'authenticationLevel'},
            startTime  => $sessions->{$_}->{'_startTime'},
            updateTime => $sessions->{$_}->{'_updateTime'},
        };
    } keys %$sessions;

    return $activeSessions;
}

sub removeOtherActiveSessions {
    my ( $self, $req, $sessions ) = @_;
    my $count = 0;
    my $as;

    foreach (@$sessions) {
        unless ( $as = $self->p->getApacheSession( $_->{id} ) ) {
            $self->userLogger->info("GlobalLogout: session $_->{id} expired");
            next;
        }
        unless ( $req->{userData}->{_session_id} eq $_->{id} ) {
            $self->userLogger->info(
"Remove \"$req->{userData}->{ $self->conf->{whatToTrace} }\" session: $_->{id}"
            );
            $as->remove;
            $count++;
        }
    }

    return $count;
}

1;
