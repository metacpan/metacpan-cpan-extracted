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

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::Lib::Code2F
  Lemonldap::NG::Portal::Lib::REST
);

# INITIALIZATION

# Prefix can overriden by sfExtra and is used for routes
has prefix => ( is => 'rw', default => 'rest' );

# Used to lookup config
has conf_type => ( is => 'ro', default => 'rest' );

has legend    => ( is => 'rw', default => 'enterRest2fCode' );
has initAttrs => ( is => 'rw', default => sub { {} } );
has vrfyAttrs => ( is => 'rw', default => sub { {} } );

sub init {
    my ($self) = @_;

    if ( $self->code_activation ) {
        unless ( $self->conf->{rest2fInitUrl} ) {
            $self->logger->error(
                $self->prefix . '2f: missing intialization URL' );
            return 0;
        }
    }
    else {
        unless ( $self->conf->{rest2fVerifyUrl} ) {
            $self->logger->error(
                $self->prefix . '2f: missing verification URL' );
            return 0;
        }
    }

    foreach my $k ( keys %{ $self->conf->{rest2fInitArgs} } ) {
        my $attr = $self->conf->{rest2fInitArgs}->{$k};
        $attr =~ s/^$//;
        unless ( $attr =~ /^\w+$/ ) {
            $self->logger->error( $self->prefix
                  . "2f: $k key must point to a single attribute or macro" );
            return 0;
        }
        $self->initAttrs->{$k} = $attr;
    }
    foreach my $k ( keys %{ $self->conf->{rest2fVerifyArgs} } ) {
        my $attr = $self->conf->{rest2fVerifyArgs}->{$k};
        $attr =~ s/^$//;
        unless ( $attr =~ /^\w+$/ ) {
            $self->logger->error( $self->prefix
                  . "2f: $k key must point to a single attribute or macro" );
            return 0;
        }
        $self->logger->debug( $self->prefix . "2f: push verify attribute $k" );
        $self->vrfyAttrs->{$k} = $attr;
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
        foreach my $k ( keys %{ $self->{initAttrs} } ) {
            $args->{$k} = $sessionInfo->{ $self->{initAttrs}->{$k} };
        }

        # Launch REST request
        $self->logger->debug( $self->prefix . '2f: call init URL' );
        my $res =
          eval { $self->restCall( $self->conf->{rest2fInitUrl}, $args ); };
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

    foreach my $k ( keys %{ $self->{vrfyAttrs} } ) {

        # in older versions, code was not automatically defined
        # if admins defined it explicitely, do not treat it as a session
        # attribute
        $args->{$k} = (
              $k eq 'code'
            ? $code
            : $session->{ $self->{vrfyAttrs}->{$k} }
        );
    }

    # Launch REST request
    $self->logger->debug( $self->prefix . '2f: call verify URL' );
    my $res =
      eval { $self->restCall( $self->conf->{rest2fVerifyUrl}, $args ); };
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
