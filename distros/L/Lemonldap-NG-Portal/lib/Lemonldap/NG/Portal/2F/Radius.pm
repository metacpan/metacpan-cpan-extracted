package Lemonldap::NG::Portal::2F::Radius;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADOTP
  PE_SENDRESPONSE
  PE_MALFORMEDUSER
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'rw', default => 'radius' );
has radius => ( is => 'rw' );

sub init {
    my ($self) = @_;

    eval { require Authen::Radius };
    if ($@) {
        $self->logger->error("Can't load Radius library: $@");
        $self->error("Can't load Radius library: $@");
        return 0;
    }

    foreach (qw(radius2fSecret radius2fServer)) {
        unless ( $self->conf->{$_} ) {
            $self->error(
                $self->prefix . "2f: missing \"$_\" parameter, aborting" );
            return 0;
        }
    }

    $self->error( $self->prefix . '2f: connection to server failed' )
      unless (
        $self->radius(
            Authen::Radius->new(
                Host    => $self->conf->{radius2fServer},
                Secret  => $self->conf->{radius2fSecret},
                TimeOut => $self->conf->{radius2fTimeout}
            )
        )
      );

    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug( $self->prefix . '2f: generate form' );

    # Prepare form
    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            TOKEN  => $token,
            PREFIX => $self->prefix,
            TARGET => '/'
              . $self->prefix
              . '2fcheck?skin='
              . $self->p->getSkin($req),
            LEGEND        => 'enterRadius2fCode',
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayConnected
        }
    );
    $self->logger->debug( $self->prefix . '2f: prepare verification' );

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
        $self->logger->error( $self->prefix
              . "2f: unable to find username from session attribute $userAttr"
        );
        return PE_MALFORMEDUSER;
    }

    $self->logger->debug(
        $self->prefix . "2f: checking credentials $username:$code" );
    my $res = $self->radius->check_pwd( $username, $code );
    unless ( $res == 1 ) {
        $self->userLogger->warn( $self->prefix
              . '2f: failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        $self->logger->warn( $self->prefix
              . '2f: server replied -> '
              . $self->radius->get_error );
        return PE_BADOTP;
    }

    $self->logger->debug(
        $self->prefix . '2f: credentials accepted by server' );
    return PE_OK;
}

1;
