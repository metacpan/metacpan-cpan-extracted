package Lemonldap::NG::Portal::2F::UTOTP;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'utotp' );

has logo => ( is => 'rw', default => 'utotp.png' );

has u2f => ( is => 'rw' );

has totp => ( is => 'rw' );

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_FORMEMPTY
  PE_OK
  PE_SENDRESPONSE
);

sub init {
    my ($self) = @_;
    if ( (
               $self->conf->{totp2fSelfRegistration}
            or $self->conf->{u2fSelfRegistration}
        )
        and $self->conf->{utotp2fActivation} eq '1'
      )
    {
        $self->conf->{utotp2fActivation} =
          '$_2fDevices && $_2fDevices =~ /"type":\s*"(?:TOTP|U2F)"/s';
    }
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
    $self->logger->debug('Generate TOTP form');

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("UTOTP checkLogins set") if ($checkLogins);

    my %tplPrms = (
        MAIN_LOGO   => $self->conf->{portalMainLogo},
        SKIN        => $self->p->getSkin($req),
        TOKEN       => $token,
        CHECKLOGINS => $checkLogins
    );

    if ( my $res = $self->u2f->loadUser( $req, $req->sessionInfo ) ) {
        if ( $res > 0 ) {
            $self->logger->debug('U2F key is registered');

            # Get a challenge (from first key)
            my $data = eval {
                from_json(
                    $req->data->{crypter}->[0]->authenticationChallenge );
            };

            if ($@) {
                $self->logger->error( Crypt::U2F::Server::u2fclib_getError() );
                return PE_ERROR;
            }

            # Get registered keys
            my @rk;
            foreach ( @{ $req->data->{crypter} } ) {
                push @rk,
                  { keyHandle => $_->{keyHandle}, version => $data->{version} };

            }

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
    $self->logger->debug("Prepare U2F-or-TOTP 2F verification");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my ($r1);
    if ( $req->param('signature') ) {
        $self->logger->debug('UTOTP: U2F response detected');
        my $r1 = $self->u2f->verify( $req, $session );
        if ( $r1 == PE_OK ) {
            return PE_OK;
        }
    }
    if ( $req->param('code') ) {
        $self->logger->debug('UTOTP: TOTP response detected');
        return $self->totp->verify( $req, $session );
    }
    return ( $r1 ? $r1 : PE_FORMEMPTY );
}

1;
