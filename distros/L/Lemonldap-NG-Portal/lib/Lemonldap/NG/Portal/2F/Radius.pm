package Lemonldap::NG::Portal::2F::Radius;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Lib::Radius;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADOTP
  PE_SENDRESPONSE
  PE_MALFORMEDUSER
  PE_RADIUSCONNECTFAILED
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION
has modulename => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->prefix . "2f";
    }
);

has radiusLib => ( is => 'rw' );

has prefix => ( is => 'rw', default => 'radius' );

has initial_request => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->conf->{radius2fSendInitialRequest};
    }
);

sub init {
    my ($self) = @_;
    $self->radiusLib(
        Lemonldap::NG::Portal::Lib::Radius->new(
            radius_dictionary => $self->conf->{radius2fDictionaryFile},
            radius_req_attribute_config =>
              $self->conf->{radius2fRequestAttributes},
            radius_secret  => $self->conf->{radius2fSecret},
            radius_server  => $self->conf->{radius2fServer},
            radius_timeout => $self->conf->{radius2fTimeout},
            radius_msgauth => $self->conf->{radius2fMsgAuth},
            modulename     => ( $self->prefix . "2f" ),
            logger         => $self->logger,
            p              => $self->p,
        )
    );
    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug( $self->prefix . '2f: generate form' );

    my $session  = $req->sessionInfo;
    my $username = $session->{ $self->conf->{whatToTrace} };
    if ( $self->initial_request ) {
        $self->logger->debug(
            $self->prefix . "2f: sending empty Access-Request for  $username" );
        my $res = $self->radiusLib->check_pwd( $req, $session, $username );
        unless ($res) {
            return PE_RADIUSCONNECTFAILED;
        }
    }

    # Prepare form
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
            LEGEND => 'enterRadius2fCode',
            $self->get2fTplParams($req),
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

    my $res = $self->radiusLib->check_pwd( $req, $session, $username, $code );
    unless ($res) {
        return PE_RADIUSCONNECTFAILED;
    }
    unless ( $res->{result} == 1 ) {
        $self->userLogger->warn( $self->prefix
              . '2f: failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADOTP;
    }

    $self->logger->debug(
        $self->prefix . '2f: credentials accepted by server' );
    return PE_OK;
}

1;
