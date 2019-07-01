package Lemonldap::NG::Portal::2F::REST;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_FORMEMPTY
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::SecondFactor',
  'Lemonldap::NG::Portal::Lib::REST';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'rest' );

has initAttrs => ( is => 'rw', default => sub { {} } );

has vrfyAttrs => ( is => 'rw', default => sub { {} } );

sub init {
    my ($self) = @_;
    unless ( $self->conf->{rest2fVerifyUrl} ) {
        $self->logger->error('Missing REST verification URL');
        return 0;
    }
    $self->logo( $self->conf->{rest2fLogo} ) if ( $self->conf->{rest2fLogo} );
    foreach my $k ( keys %{ $self->conf->{rest2fInitArgs} } ) {
        my $attr = $self->conf->{rest2fInitArgs}->{$k};
        $attr =~ s/^$//;
        unless ( $attr =~ /^\w+$/ ) {
            $self->logger->error(
                "2F REST: $k key must point to a single attribute or macro");
            return 0;
        }
        $self->initAttrs->{$k} = $attr;
    }
    foreach my $k ( keys %{ $self->conf->{rest2fVerifyArgs} } ) {
        my $attr = $self->conf->{rest2fVerifyArgs}->{$k};
        $attr =~ s/^$//;
        unless ( $attr =~ /^\w+$/ ) {
            $self->logger->error(
                "2F REST: $k key must point to a single attribute or macro");
            return 0;
        }
        $self->vrfyAttrs->{$k} = $attr;
    }
    return $self->SUPER::init();
}

sub run {
    my ( $self, $req, $token ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("REST2F checkLogins set") if ($checkLogins);

    if ( $self->conf->{rest2fInitUrl} ) {

        # Prepare args
        my $args = {};
        foreach my $k ( keys %{ $self->{initAttrs} } ) {
            $args->{$k} = $req->sessionInfo->{ $self->{initAttrs}->{$k} };
        }

        # Launch REST request
        $self->logger->debug('Call REST init URL');
        my $res =
          eval { $self->restCall( $self->conf->{rest2fInitUrl}, $args ); };
        if ($@) {
            $self->logger->error("REST 2F error: $@");
            return PE_ERROR;
        }
        unless ( $res->{result} ) {
            $self->logger->error("REST 2F initialization has failed");
            return PE_ERROR;
        }
    }
    else {
        $self->logger->debug('No init URL, skipping initialization');
    }

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO   => $self->conf->{portalMainLogo},
            SKIN        => $self->p->getSkin($req),
            TOKEN       => $token,
            TARGET      => '/rest2fcheck',
            CHECKLOGINS => $checkLogins
        }
    );
    $self->logger->debug("Prepare external REST verification");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $code;
    unless ( $code = $req->param('code') ) {
        $self->userLogger->error('External REST 2F: no code');
        return PE_FORMEMPTY;
    }

    # Prepare args
    my $args = {};
    foreach my $k ( keys %{ $self->{vrfyAttrs} } ) {
        $args->{$k} = (
              $k eq 'code'
            ? $code
            : $req->sessionInfo->{ $self->{vrfyAttrs}->{$k} }
        );
    }

    # Launch REST request
    $self->logger->debug('Call REST vrfy URL');
    my $res =
      eval { $self->restCall( $self->conf->{rest2fVerifyUrl}, $args ); };
    if ($@) {
        $self->logger->error("REST 2F error: $@");
        return PE_ERROR;
    }

    # Result
    unless ( $res->{result} ) {
        $self->userLogger->warn( 'REST Second factor failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADCREDENTIALS;
    }
    PE_OK;
}

1;
