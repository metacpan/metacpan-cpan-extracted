package Lemonldap::NG::Portal::Password::Combination;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_FIRSTACCESS
);

extends 'Lemonldap::NG::Portal::Password::Base';
with 'Lemonldap::NG::Portal::Lib::OverConf';

our $VERSION = '2.0.16';

has 'mods' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub init {
    my $self = shift;

    # Check if expression exists
    unless ( $self->conf->{combination} ) {
        $self->error('No combination found');
        return 0;
    }

    # Load all declared modules
    my %mods;
    foreach my $key ( keys %{ $self->conf->{combModules} } ) {
        my $tmp;
        my $mod = $self->conf->{combModules}->{$key};

        unless ( $mod->{type} and defined $mod->{for} ) {
            $self->error("Malformed combination module $key");
            return 0;
        }

        # Only load modules used for UserDB
        unless ( $mod->{for} == 1 ) {
            $tmp =
              $self->loadModule( "::Password::$mod->{type}", $mod->{over} );
            unless ($tmp) {
                $self->logger->notice("Unable to load Password::$mod->{type}");
                next;
            }
        }

        # Store modules as array
        $self->mods->{$key} = $tmp;
    }
    return $self->SUPER::init;
}

sub delegate {
    my ( $self, $req, $name, @args ) = @_;

    # The user might want to override which password DB is used with a macro
    # This is useful when using SASL delegation in OpenLDAP
    my $userDB =
      $req->sessionInfo->{_cmbPasswordDB} || $req->sessionInfo->{_userDB};
    unless ( $self->mods->{$userDB} ) {
        $self->logger->error("No Password module available for $userDB");
        return PE_ERROR;
    }

    return $self->mods->{$userDB}->$name( $req, @args );
}

sub confirm {
    my ( $self, $req, @args ) = @_;
    return $self->delegate( $req, "confirm", @args );
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    return $self->delegate( $req, "modifyPassword", $pwd, %args );
}

1;
