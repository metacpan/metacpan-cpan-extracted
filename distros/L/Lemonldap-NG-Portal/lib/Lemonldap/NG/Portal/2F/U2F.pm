# U2F second factor authentication
#
# This plugin handle authentications to ask U2F second factor for users that
# have registered their U2F key
package Lemonldap::NG::Portal::2F::U2F;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64 qw(decode_base64url);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_U2FFAILED
  PE_SENDRESPONSE
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::Main::SecondFactor
  Lemonldap::NG::Portal::Lib::U2F
);
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has rule   => ( is => 'rw' );
has prefix => ( is => 'ro', default => 'u' );
has logo   => ( is => 'rw', default => 'u2f.png' );

sub init {
    my ($self) = @_;

    # If "activation" is just set to "enabled",
    # replace the rule to detect if user has registered its key
    $self->conf->{u2fActivation} = 'has2f("U2F")'
      if $self->conf->{u2fActivation} eq '1';

    return 0
      unless ( $self->Lemonldap::NG::Portal::Main::SecondFactor::init()
        and $self->Lemonldap::NG::Portal::Lib::U2F::init() );

    return 1;
}

# RUNNING METHODS

# Main method
sub run {
    my ( $self, $req, $token ) = @_;

    # Check if user is registered
    if ( my $res = $self->loadUser( $req, $req->sessionInfo ) ) {
        return PE_ERROR     if $res == -1;
        return PE_U2FFAILED if $res == 0;

        # Get a challenge (from first key)
        my $data = eval {
            from_json( $req->data->{crypter}->[0]->authenticationChallenge );
        };

        if ($@) {
            $self->logger->error( Crypt::U2F::Server::u2fclib_getError() );
            return PE_ERROR;
        }

        # Get registered keys
        my @rk =
          map { { keyHandle => $_->{keyHandle}, version => $data->{version} } }
          @{ $req->data->{crypter} };

        $self->ott->updateToken( $token, __ch => $data->{challenge} );

        $self->logger->debug( $self->prefix . '2f: prepare verification' );
        $self->logger->debug( " -> send challenge: " . $data->{challenge} );

        # Serialize data
        $data = to_json( {
                challenge      => $data->{challenge},
                appId          => $data->{appId},
                registeredKeys => \@rk
            }
        );

        # Prepare form
        my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
        my $tmp = $self->p->sendHtml(
            $req,
            'u2fcheck',
            params => {
                DATA          => $data,
                TOKEN         => $token,
                CHECKLOGINS   => $checkLogins,
                STAYCONNECTED => $stayConnected
            }
        );

        $req->response($tmp);
        return PE_SENDRESPONSE;
    }
    return PE_U2FFAILED;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $crypter;

    # Check U2F signature
    if (    my $resp = $req->param('signature')
        and my $challenge = $req->param('challenge') )
    {
        unless ( $self->loadUser( $req, $session ) == 1 ) {
            $req->error(PE_ERROR);
            return $self->fail($req);
        }

        $self->logger->debug(
            $self->prefix . "2f: get challenge ($challenge)" );

        unless ( $session->{__ch} and $session->{__ch} eq $challenge ) {
            $self->userLogger->error( $self->prefix
                  . "2f: challenge changed by user: $session->{__ch} / $challenge"
            );
            $req->error(PE_BADCREDENTIALS);
            return $self->fail($req);
        }
        delete $session->{__ch};

        $self->logger->debug( $self->prefix . "2f: get signature ($resp)" );
        my $data = eval { JSON::from_json($resp) };
        if ($@) {
            $self->logger->error( $self->prefix . "2f: response error ($@)" );
            $req->error(PE_ERROR);
            return $self->fail($req);
        }
        $crypter = $_
          foreach grep { $_->{keyHandle} eq $data->{keyHandle} }
          @{ $req->data->{crypter} };
        unless ($crypter) {
            $self->userLogger->error( $self->prefix . '2f: unregistered key' );
            $req->error(PE_BADCREDENTIALS);
            return $self->fail($req);
        }

        if ( not $crypter->setChallenge($challenge) ) {
            $self->logger->error(
                $@ ? $@ : Crypt::U2F::Server::Simple::lastError() );
            $req->error(PE_ERROR);
            return $self->fail($req);
        }
        if ( $crypter->authenticationVerify($resp) ) {
            $self->userLogger->info( $self->prefix . '2f: signature verified' );
            return PE_OK;
        }
        else {
            $self->userLogger->notice( $self->prefix
                  . '2f: unvalid signature for '
                  . $session->{ $self->conf->{whatToTrace} } . ' ('
                  . Crypt::U2F::Server::u2fclib_getError()
                  . ')' );
            $req->error(PE_U2FFAILED);
            return $self->fail($req);
        }
    }
    else {
        $self->userLogger->notice( $self->prefix
              . '2f: no valid response for user '
              . $session->{ $self->conf->{whatToTrace} } );
        $req->authResult(PE_U2FFAILED);
        return $self->fail($req);
    }
}

sub fail {
    my ( $self, $req ) = @_;
    $req->response(
        $self->p->sendHtml(
            $req,
            'u2fcheck',
            params => {
                AUTH_ERROR      => $req->error,
                AUTH_ERROR_TYPE => $req->error_type,
                AUTH_ERROR_ROLE => $req->error_role,
                FAILED          => 1
            }
        )
    );
    return PE_SENDRESPONSE;
}

sub loadUser {
    my ( $self, $req, $session ) = @_;
    my ( $kh, $uk, $_2fDevices, @u2fs, @crypters );

    # Manage multi U2F keys
    @u2fs = $self->find2fDevicesByType( $req, $session, $self->type );
    if (@u2fs) {
        $self->logger->debug(
            $self->prefix . '2f: generating crypter(s) with uk & kh' );

        foreach (@u2fs) {
            $kh = $_->{_keyHandle};
            $uk = decode_base64url( $_->{_userKey} );
            $self->logger->debug(
                $self->prefix . "2f: append crypter with kh = $kh" );
            my $c = $self->crypter( keyHandle => $kh, publicKey => $uk );
            if ($c) {
                push @crypters, $c;
            }
            else {
                $self->logger->error( $self->prefix
                      . '2f: error ('
                      . Crypt::U2F::Server::u2fclib_getError()
                      . ')' );
            }
        }
        return -1 unless @crypters;

        $req->data->{crypter} = \@crypters;
        return 1;
    }
    else {
        $self->userLogger->info( $self->prefix . '2f: user not registered' );
        return 0;
    }
}

1;
