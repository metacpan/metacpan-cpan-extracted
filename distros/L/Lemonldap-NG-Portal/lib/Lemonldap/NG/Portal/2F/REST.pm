package Lemonldap::NG::Portal::2F::REST;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADOTP
  PE_ERROR
  PE_FORMEMPTY
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.23.0';

extends qw(
  Lemonldap::NG::Portal::Lib::Code2F
  Lemonldap::NG::Portal::Lib::REST
);

# INITIALIZATION

# Prefix can overriden by sfExtra and is used for routes
has prefix => ( is => 'rw', default => 'rest' );

# Used to lookup config
has conf_type => ( is => 'ro', default => 'rest' );

has legend => ( is => 'rw', default => 'enterRest2fCode' );

sub init {
    my ($self) = @_;

    my $init_result   = $self->initNamedCallFromConf( 'rest2fInit',   'init' );
    my $verify_result = $self->initNamedCallFromConf( 'rest2fVerify', 'vrfy' );

    if ( $self->code_activation ) {
        unless ($init_result) {
            $self->logger->error(
                $self->prefix . '2f: missing intialization URL' );
            return 0;
        }
    }
    else {
        unless ($verify_result) {
            $self->logger->error(
                $self->prefix . '2f: missing verification URL' );
            return 0;
        }
    }

    return $self->SUPER::init();
}

sub sendCode {
    my ( $self, $req, $sessionInfo, $code ) = @_;

    if ( $self->conf->{rest2fInitUrl} ) {

        # Prepare args
        my $args = {
            user => $sessionInfo->{ $self->conf->{whatToTrace} },
            ( $code ? ( code => $code ) : () ),
        };

        # Launch REST request
        $self->logger->debug( $self->prefix . '2f: call init URL' );
        my $res =
          eval { $self->restNamedCall( $req, 'init', $args, $sessionInfo ); };
        if ($@) {
            $self->logger->error( $self->prefix . "2f: error ($@)" );
            return PE_ERROR;
        }
        unless ( $res->{result} ) {
            $self->logger->error( $self->prefix . '2f: initialization failed' );
            return PE_ERROR;
        }
    }
    else {
        $self->logger->debug(
            $self->prefix . '2f: no init URL, skipping initialization' );
    }

    return 1;
}

sub verify_external {
    my ( $self, $req, $session, $code ) = @_;

    # Prepare args
    my $args = {
        user => $session->{ $self->conf->{whatToTrace} },
        code => $code
    };

    # in older versions, code was not automatically defined
    # if admins defined it explicitly, do not treat it as a session
    # attribute
    my $session_data = { %{ $session || {} }, code => $code };

    # Launch REST request
    $self->logger->debug( $self->prefix . '2f: call verify URL' );
    my $res =
      eval { $self->restNamedCall( $req, 'vrfy', $args, $session_data ) };
    if ($@) {
        $self->logger->error( $self->prefix . "2f: error ($@)" );
        return PE_ERROR;
    }

    # Result
    unless ( $res->{result} ) {
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
