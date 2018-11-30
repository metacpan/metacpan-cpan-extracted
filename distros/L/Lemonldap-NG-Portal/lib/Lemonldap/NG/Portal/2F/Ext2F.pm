package Lemonldap::NG::Portal::2F::Ext2F;

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

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'ext' );

sub init {
    my ($self) = @_;
    foreach (qw(ext2FSendCommand ext2FValidateCommand)) {
        unless ( $self->conf->{$_} ) {
            $self->error("Missing $_ parameter, aborting");
            return 0;
        }
    }
    $self->logo( $self->conf->{ext2fLogo} ) if ( $self->conf->{ext2fLogo} );
    return $self->SUPER::init();
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("Ext2F checkLogins set") if ($checkLogins);

    # Prepare command and launch it
    $self->logger->debug( 'Launching "Send" external 2F command -> '
          . $self->conf->{ext2FSendCommand} );
    if ( my $c =
        $self->launch( $req->sessionInfo, $self->conf->{ext2FSendCommand} ) )
    {
        $self->logger->error("External send command failed (code $c)");
        return $self->p->do( $req, [ sub { PE_ERROR } ] );
    }

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO   => $self->conf->{portalMainLogo},
            SKIN        => $self->conf->{portalSkin},
            TOKEN       => $token,
            CHECKLOGINS => $checkLogins
        }
    );
    $self->logger->debug("Prepare external 2F verification");

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my $code;
    unless ( $code = $req->param('code') ) {
        $self->userLogger->error('External 2F: no code');
        return PE_FORMEMPTY;
    }

    # Prepare command and launch it
    $self->logger->debug( 'Launching "Validate" external 2F command -> '
          . $self->conf->{ext2FValidateCommand} );
    $self->logger->debug(" code -> $code");
    if ( my $c =
        $self->launch( $session, $self->conf->{ext2FValidateCommand}, $code ) )
    {
        $self->userLogger->warn( 'Second factor failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADCREDENTIALS;
    }
    PE_OK;
}

# system() is used with an array to avoid shell injection
sub launch {
    my ( $self, $session, $command, $code ) = @_;
    my @args;
    foreach ( split( /\s+/, $command ) ) {
        if ( defined $code ) {
            s#\$code\b#$code#g;
        }
        s#\$(\w+)#$session->{$1} // ''#ge;
        push @args, $_;
    }
    return system @args;
}

1;
