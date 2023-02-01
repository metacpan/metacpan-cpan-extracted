# Plugin to enable "stay connected on this device" feature

package Lemonldap::NG::Portal::Plugins::StayConnected;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.14';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
);

# INTERFACE

use constant endAuth      => 'newDevice';
use constant beforeAuth   => 'check';
use constant beforeLogout => 'logout';

# INITIALIZATION
has rule => ( is => 'rw', default => sub { 0 } );
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
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedCookieName} || 'llngconnection';
    }
);
has singleSession => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedSingleSession};
    }
);

# Default timeout: 1 month
has timeout => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{stayConnectedTimeout} || 2592000;
    }
);

sub init {
    my ($self) = @_;
    $self->addAuthRoute( registerbrowser => 'storeBrowser', ['POST'] );

    # Parse activation rule
    $self->rule(
        $self->p->buildRule( $self->conf->{stayConnected}, 'stayConnected' ) );
    return 0 unless $self->rule;

    return 1;
}

# RUNNING METHODS

# Registration: detect if user wants to stay connected.
# Then ask for browser fingerprint
sub newDevice {
    my ( $self, $req ) = @_;
    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("StayConnected: checkLogins set") if $checkLogins;

    if (   $req->param('stayconnected')
        && $self->rule->( $req, $req->sessionInfo ) )
    {
        my $token = $self->ott->createToken( {
                name => $req->sessionInfo->{ $self->conf->{whatToTrace} },
                (
                    $checkLogins
                    ? ( history => $req->sessionInfo->{_loginHistory} )
                    : ()
                )
            }
        );
        $req->response(
            $self->p->sendHtml(
                $req,
                '../common/registerBrowser',
                params => {
                    URL         => $req->urldc,
                    TOKEN       => $token,
                    ACTION      => '/registerbrowser',
                    CHECKLOGINS => $checkLogins
                }
            )
        );
        return PE_SENDRESPONSE;
    }
    return PE_OK;
}

# Store data in a long-time session
sub storeBrowser {
    my ( $self, $req ) = @_;
    $req->urldc( $req->param('url') );
    $req->mustRedirect(1);
    if ( $self->rule->( $req, $req->sessionInfo ) ) {
        if ( my $token = $req->param('token') ) {
            if ( my $tmp = $self->ott->getToken($token) ) {
                my $uid = $req->userData->{ $self->conf->{whatToTrace} };
                if ( $tmp->{name} eq $uid ) {
                    if ( my $fg = $req->param('fg') ) {
                        my $ps = $self->newConnectionSession( {
                                _utime          => time + $self->timeout,
                                _session_uid    => $uid,
                                _connectedSince => time,
                                dataKeep        => $req->data->{dataToKeep},
                                fingerprint     => $fg,
                            },
                        );

                        # Cookie available 30 days by default
                        $req->addCookie(
                            $self->p->cookie(
                                name    => $self->cookieName,
                                value   => $ps->id,
                                max_age => $self->timeout,
                                secure  => $self->conf->{securedCookie},
                            )
                        );
                        $req->sessionInfo->{_loginHistory} = $tmp->{history}
                          if exists $tmp->{history};

                        # Store connection ID in current session
                        $self->p->updateSession( $req,
                            { _stayConnectedSession => $ps->id } );
                    }
                    else {
                        $self->logger->warn(
                            "Browser did not return fingerprint");
                    }
                }
                else {
                    $self->userLogger->error(
                        "StayConnected: mismatch UID ($tmp->{name} / $uid)");
                }
            }
            else {
                $self->userLogger->error(
                    "StayConnected called with an expired token");
            }
        }
        else {
            $self->userLogger->error('StayConnected called without token');
        }
    }
    else {
        $self->userLogger->error('StayConnected not allowed');
    }

    # Return persistent connection cookie
    return $self->p->do( $req, [ @{ $self->p->endAuth }, sub { PE_OK } ] );
}

# Check for:
#  - persistent connection cookie
#  - valid session
#  - uniq id is kept
# Then delete authentication methods from "steps" array.
sub check {
    my ( $self, $req ) = @_;
    if ( $self->rule->( $req, $req->sessionInfo ) ) {
        if ( my $cid = $req->cookies->{ $self->cookieName } ) {
            my $ps = Lemonldap::NG::Common::Session->new(
                storageModule        => $self->conf->{globalStorage},
                storageModuleOptions => $self->conf->{globalStorageOptions},
                kind                 => "SSO",
                id                   => $cid,
            );
            if (    $ps
                and my $uid = $ps->data->{_session_uid}
                and time() < $ps->data->{_utime} )
            {
                $self->logger->debug('Persistent connection found');
                if (    my $fg = $req->param('fg')
                    and my $token = $req->param('token') )
                {
                    if ( my $prm = $self->ott->getToken($token) ) {
                        $req->data->{dataKeep} = $ps->data->{dataKeep};
                        $self->logger->debug('Persistent connection found');
                        if ( $self->conf->{stayConnectedBypassFG} ) {
                            return $self->skipAuthentication( $req, $uid, $cid,
                                0 );
                        }
                        else {
                            if ( $fg eq $ps->data->{fingerprint} ) {
                                return $self->skipAuthentication( $req, $uid,
                                    $cid, 1 );
                            }
                            else {
                                $self->userLogger->warn(
                                    "Fingerprint changed for $uid");
                                $ps->remove;
                                $self->logout($req);
                            }
                        }
                    }
                    else {
                        $self->userLogger->notice(
                            "StayConnected: expired token for $uid");
                    }
                }
                else {
                    my $token = $self->ott->createToken( $req->parameters );
                    $req->response(
                        $self->p->sendHtml(
                            $req,
                            '../common/registerBrowser',
                            params => {
                                TOKEN  => $token,
                                ACTION => '#',
                            }
                        )
                    );
                    return PE_SENDRESPONSE;
                }
            }
            else {
                $self->userLogger->notice('Persistent connection expired');
                unless ( $ps->{error} ) {
                    $self->logger->debug(
                        'Persistent connection session id = ' . $ps->{id} );
                    $self->logger->debug(
                        'Persistent connection session _utime = '
                          . $ps->data->{_utime} );
                    $ps->remove;
                }
            }
        }
    }
    else {
        $self->userLogger->error('StayConnected not allowed');
    }
    return PE_OK;
}

sub logout {
    my ( $self, $req ) = @_;
    $req->addCookie(
        $self->p->cookie(
            name    => $self->cookieName,
            value   => 0,
            expires => 'Wed, 21 Oct 2015 00:00:00 GMT',
            secure  => $self->conf->{securedCookie},
        )
    );

    # Try to clean stayconnected cookie
    my $cid = $req->sessionInfo->{_stayConnectedSession};
    if ($cid) {
        my $ps = Lemonldap::NG::Common::Session->new(
            storageModule        => $self->conf->{globalStorage},
            storageModuleOptions => $self->conf->{globalStorageOptions},
            kind                 => "SSO",
            id                   => $cid,
        );
        if ($ps) {
            $self->logger->debug("Cleaning up StayConnected session $cid");
            $ps->remove;
        }
    }

    return PE_OK;
}

# Remove authentication steps from the login flow
sub skipAuthentication {
    my ( $self, $req, $uid, $cid, $fp ) = @_;
    $req->user($uid);
    $req->sessionInfo->{_stayConnectedSession} = $cid;
    my @steps =
      grep { ref $_ or $_ !~ /^(?:extractFormInfo|authenticate)$/ }
      @{ $req->steps };
    $req->steps( \@steps );
    $self->userLogger->notice( "$uid connected by StayConnected cookie"
          . ( $fp ? "" : " without fingerprint checking" ) );
    return PE_OK;
}

sub removeExistingSessions {
    my ( $self, $uid ) = @_;
    $self->logger->debug("StayConnected: removing all sessions for $uid");

    my $sessions =
      $self->module->searchOn( $self->moduleOpts, '_session_uid', $uid );

    foreach ( keys %{ $sessions || {} } ) {
        if (
            my $ps = Lemonldap::NG::Common::Session->new(
                storageModule        => $self->conf->{globalStorage},
                storageModuleOptions => $self->conf->{globalStorageOptions},
                kind                 => "SSO",
                id                   => $_,
            )
          )
        {
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

    # Remove existing sessions
    if ( $self->singleSession ) {
        $self->removeExistingSessions( $info->{_session_uid} );
    }

    return Lemonldap::NG::Common::Session->new(
        storageModule        => $self->conf->{globalStorage},
        storageModuleOptions => $self->conf->{globalStorageOptions},
        kind                 => "SSO",
        info                 => $info,
    );
}

1;
