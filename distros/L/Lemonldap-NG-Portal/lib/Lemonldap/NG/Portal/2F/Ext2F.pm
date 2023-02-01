package Lemonldap::NG::Portal::2F::Ext2F;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADOTP
  PE_NOTOKEN
  PE_FORMEMPTY
  PE_SENDRESPONSE
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Lib::Code2F';

# INITIALIZATION

# Prefix can overriden by sfExtra and is used for routes
has prefix => ( is => 'rw', default => 'ext' );

# Used to lookup config
has conf_type => ( is => 'ro', default => 'ext' );
has legend    => ( is => 'rw', default => 'enterExt2fCode' );

sub init {
    my ($self) = @_;

    if ( $self->code_activation ) {
        unless ( $self->conf->{ext2FSendCommand} ) {
            $self->error( $self->prefix
                  . '2f: missing "ext2FSendCommand" parameter, aborting' );
            return 0;
        }
    }
    else {
        foreach (qw(ext2FSendCommand ext2FValidateCommand)) {
            unless ( $self->conf->{$_} ) {
                $self->error(
                    $self->prefix . "2f: missing \"$_\" parameter, aborting" );
                return 0;
            }
        }
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub verify_external {
    my ( $self, $req, $session, $code ) = @_;

    # Prepare command and launch it
    $self->logger->debug( $self->prefix
          . '2f: launching "Validate" command -> '
          . $self->conf->{ext2FValidateCommand} );
    $self->logger->debug(" code -> $code");
    if ( my $c =
        $self->launch( $session, $self->conf->{ext2FValidateCommand}, $code ) )
    {
        $self->userLogger->warn( $self->prefix
              . '2f: validation failed for '
              . $session->{ $self->conf->{whatToTrace} } );
        $self->logger->error(
            $self->prefix . "2f: validate command failed ($c)" );
        return PE_BADOTP;
    }
    return PE_OK;
}

sub sendCode {
    my ( $self, $req, $sessionInfo, $code ) = @_;

    # Prepare command and launch it
    $self->logger->debug( $self->prefix
          . '2f: launching "Send" command -> '
          . $self->conf->{ext2FSendCommand} );
    if ( my $c =
        $self->launch( $sessionInfo, $self->conf->{ext2FSendCommand}, $code ) )
    {
        $self->logger->error( $self->prefix . "2f: send command failed ($c)" );
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
    $self->logger->debug(
        $self->prefix . "2f: executing command: " . join( " ", @args ) );
    return system @args;
}

1;

