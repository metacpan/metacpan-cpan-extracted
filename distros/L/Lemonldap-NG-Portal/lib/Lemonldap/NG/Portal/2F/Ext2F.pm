package Lemonldap::NG::Portal::2F::Ext2F;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_ERROR
  PE_BADOTP
  PE_FORMEMPTY
  PE_SENDRESPONSE
);

our $VERSION = '2.0.15';

extends 'Lemonldap::NG::Portal::Lib::Code2F';

# INITIALIZATION

# Prefix can overriden by sfExtra and is used for routes
has prefix => ( is => 'rw', default => 'ext' );

# Type is used to lookup config
has type   => ( is => 'ro', default => 'ext' );
has legend => ( is => 'rw', default => 'enterExt2fCode' );

sub init {
    my ($self) = @_;

    if ( $self->code_activation ) {
        unless ( $self->conf->{ext2FSendCommand} ) {
            $self->error("Missing 'ext2FSendCommand' parameter, aborting");
            return 0;
        }
    }
    else {
        foreach (qw(ext2FSendCommand ext2FValidateCommand)) {
            unless ( $self->conf->{$_} ) {
                $self->error("Missing $_ parameter, aborting");
                return 0;
            }
        }
    }

    $self->prefix( $self->conf->{sfPrefix} ) if ( $self->conf->{sfPrefix} );
    return $self->SUPER::init();
}

# RUNNING METHODS

sub verify_external {
    my ( $self, $req, $session, $code ) = @_;

    # Prepare command and launch it
    $self->logger->debug( 'Launching "Validate" external 2F command -> '
          . $self->conf->{ext2FValidateCommand} );
    $self->logger->debug(" code -> $code");
    if ( my $c =
        $self->launch( $session, $self->conf->{ext2FValidateCommand}, $code ) )
    {
        $self->userLogger->warn( 'Second factor failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        $self->logger->error("External verify command failed (code $c)");
        return PE_BADOTP;
    }
    return PE_OK;
}

sub sendCode {
    my ( $self, $req, $sessionInfo, $code ) = @_;

    # Prepare command and launch it
    $self->logger->debug( 'Launching "Send" external 2F command -> '
          . $self->conf->{ext2FSendCommand} );
    if ( my $c =
        $self->launch( $sessionInfo, $self->conf->{ext2FSendCommand}, $code ) )
    {
        $self->logger->error("External send command failed (code $c)");
        return 0;
    }
    return 1;
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

