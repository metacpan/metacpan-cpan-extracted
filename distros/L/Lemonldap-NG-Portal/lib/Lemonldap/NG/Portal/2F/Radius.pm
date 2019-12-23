package Lemonldap::NG::Portal::2F::Radius;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADOTP
  PE_ERROR
  PE_MALFORMEDUSER
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.6';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'rw', default => 'radius' );

has radius => ( is => 'rw' );

sub init {
    my ($self) = @_;

    foreach (qw(radius2fSecret radius2fServer)) {
        unless ( $self->conf->{$_} ) {
            $self->error("Missing $_ parameter, aborting");
            return 0;
        }
    }

    eval { require Authen::Radius };
    if ($@) {
        $self->error("Unable to load Authen::Radius: $@");
        return 0;
    }

    unless (
        $self->radius(
            Authen::Radius->new(
                Host    => $self->conf->{radius2fServer},
                Secret  => $self->conf->{radius2fSecret},
                TimeOut => $self->conf->{radius2fTimeout},
            )
        )
      )
    {
        $self->error('Radius connect failed');
    }
    $self->prefix( $self->conf->{sfPrefix} )
      if ( $self->conf->{sfPrefix} );
    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("Radius2F checkLogins set") if ($checkLogins);

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->p->getSkin($req),
            TOKEN     => $token,
            PREFIX    => $self->prefix,
            TARGET    => '/'
              . $self->prefix
              . '2fcheck?skin='
              . $self->p->getSkin($req),
            LEGEND      => 'enterRadius2fCode',
            CHECKLOGINS => $checkLogins
        }
    );
    $self->logger->debug("Prepare Radius 2F verification");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;

    # Some Radius Servers allow empty codes and perform
    # out of band, interactive verification (InWebo...)
    my $code = $req->param('code');

    # Launch Radius request
    my $userAttr =
      $self->conf->{radius2fUsernameSessionKey} || $self->conf->{whatToTrace};
    my $username = $session->{$userAttr};
    unless ($username) {
        $self->logger->error(
            "Could not find Radius username from session attribute $userAttr");
        return PE_MALFORMEDUSER;
    }

    $self->logger->debug("Checking Radius credentials $username:$code");

    my $res = $self->radius->check_pwd( $username, $code );
    unless ( $res == 1 ) {
        $self->userLogger->warn( "Radius second factor failed for "
              . $session->{ $self->conf->{whatToTrace} } );
        $self->logger->warn(
            "Radius server replied: " . $self->radius->get_error );
        return PE_BADOTP;
    }
    $self->logger->debug("Radius server accepted 2F credentials");
    PE_OK;
}

1;
