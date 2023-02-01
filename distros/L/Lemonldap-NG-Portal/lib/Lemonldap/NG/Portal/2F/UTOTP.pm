package Lemonldap::NG::Portal::2F::UTOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'utotp' );
has logo   => ( is => 'rw', default => 'utotp.png' );
has u2f    => ( is => 'rw' );
has totp   => ( is => 'rw' );

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_FORMEMPTY
  PE_SENDRESPONSE
);

sub init {
    my ($self) = @_;
    $self->conf->{utotp2fActivation} = 'has2f("TOTP") or has2f("U2F")'
      if $self->conf->{utotp2fActivation} eq '1';

    foreach (qw(U2F TOTP)) {

        # Arg "noRoute" is set for sub 2F modules to avoid enabling direct
        # REST routes
        unless ( $self->{ lc($_) } =
                $self->p->loadModule( "::2F::$_", undef, noRoute => 1 )
            and $self->{ lc($_) }->init )
        {
            $self->error("Unable to load ::2F::$_");
            return 0;
        }
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug( $self->prefix . '2f: generate form' );

    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my %tplPrms = (
        TOKEN         => $token,
        CHECKLOGINS   => $checkLogins,
        STAYCONNECTED => $stayConnected
    );

    if ( my $res = $self->u2f->loadUser( $req, $req->sessionInfo ) ) {
        if ( $res > 0 ) {
            $self->logger->debug('u2f: key is registered');

            # Get a challenge (from first key)
            my $data = eval {
                from_json(
                    $req->data->{crypter}->[0]->authenticationChallenge );
            };

            if ($@) {
                $self->logger->error( 'u2f: error ('
                      . Crypt::U2F::Server::u2fclib_getError()
                      . ')' );
                return PE_ERROR;
            }

            # Get registered keys
            my @rk =
              map {
                { keyHandle => $_->{keyHandle}, version => $data->{version} }
              } @{ $req->data->{crypter} };

            $self->ott->updateToken( $token, __ch => $data->{challenge} );

            # Serialize data
            $data = to_json( {
                    challenge      => $data->{challenge},
                    appId          => $data->{appId},
                    registeredKeys => \@rk,
                }
            );
            $tplPrms{DATA} = $data;
        }
    }

    # Prepare form
    my $tmp = $self->p->sendHtml( $req, 'utotp2fcheck', params => \%tplPrms, );
    $self->logger->debug( $self->prefix . '2f: prepare verification' );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my ($r1);
    if ( $req->param('signature') ) {
        $self->logger->debug( $self->prefix . '2f: U2F response detected' );
        my $r1 = $self->u2f->verify( $req, $session );
        return PE_OK if ( $r1 == PE_OK );
    }
    if ( $req->param('code') ) {
        $self->logger->debug( $self->prefix . '2f: TOTP response detected' );
        return $self->totp->verify( $req, $session );
    }
    return $r1 ? $r1 : PE_FORMEMPTY;
}

1;
