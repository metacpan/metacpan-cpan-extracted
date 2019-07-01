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

our $VERSION = '2.0.4';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'ext' );
has random => ( is => 'rw' );

sub init {
    my ($self) = @_;
    unless ( $self->conf->{ext2fCodeActivation} ) {
        foreach (qw(ext2FSendCommand ext2FValidateCommand)) {
            unless ( $self->conf->{$_} ) {
                $self->error("Missing $_ parameter, aborting");
                return 0;
            }
        }
        $self->logo( $self->conf->{ext2fLogo} )
          if ( $self->conf->{ext2fLogo} );
        return $self->SUPER::init();
    }
    if ( $self->conf->{ext2fCodeActivation} ) {
        unless ( $self->conf->{ext2FSendCommand} ) {
            $self->error("Missing 'ext2FSendCommand' parameter, aborting");
            return 0;
        }
        $self->random( Lemonldap::NG::Common::Crypto::srandom() );
        $self->logo( $self->conf->{ext2fLogo} )
          if ( $self->conf->{ext2fLogo} );
        return $self->SUPER::init();
    }
    return 0;
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("Ext2F checkLogins set") if ($checkLogins);

    # Generate Code to send
    my $code;
    if ( $self->conf->{ext2fCodeActivation} ) {
        $code = $self->random->randregex( $self->conf->{ext2fCodeActivation} );
        $self->logger->debug("Generated ext2f code : $code");
        $self->ott->updateToken( $token, __ext2fcode => $code );
    }

    # Prepare command and launch it
    $self->logger->debug( 'Launching "Send" external 2F command -> '
          . $self->conf->{ext2FSendCommand} );
    if (
        my $c = $self->launch(
            $req->sessionInfo, $self->conf->{ext2FSendCommand}, $code
        )
      )
    {
        $self->logger->error("External send command failed (code $c)");
        return PE_ERROR;
    }

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            MAIN_LOGO   => $self->conf->{portalMainLogo},
            SKIN        => $self->p->getSkin($req),
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
    my $usercode;
    unless ( $usercode = $req->param('code') ) {
        $self->userLogger->error('External 2F: no code found');
        return PE_FORMEMPTY;
    }

    unless ( $self->conf->{ext2fCodeActivation} ) {

        # Prepare command and launch it
        $self->logger->debug( 'Launching "Validate" external 2F command -> '
              . $self->conf->{ext2FValidateCommand} );
        $self->logger->debug(" code -> $usercode");
        if (
            my $c = $self->launch(
                $session, $self->conf->{ext2FValidateCommand}, $usercode
            )
          )
        {
            $self->userLogger->warn( 'Second factor failed for '
                  . $session->{ $self->conf->{whatToTrace} } );
            $self->logger->error("External verify command failed (code $c)");
            return PE_BADCREDENTIALS;
        }
        return PE_OK;
    }

    my $savedcode = $session->{__ext2fcode};
    unless ($savedcode) {
        $self->logger->error(
            'Unable to find generated 2F code in token session');
        return PE_ERROR;
    }

    $self->logger->debug("Verifying Ext 2F code: $usercode VS $savedcode");
    return PE_OK if ( $usercode eq $savedcode );

    $self->userLogger->warn( 'Second factor failed for '
          . $session->{ $self->conf->{whatToTrace} } );
    return PE_BADCREDENTIALS;
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
    $self->logger->debug( "Executing command: " . join( " ", @args ) );
    return system @args;
}

1;

