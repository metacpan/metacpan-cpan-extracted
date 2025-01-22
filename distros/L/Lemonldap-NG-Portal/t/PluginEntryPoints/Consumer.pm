package My::Base;
use Mouse;

package My::Role;
use Mouse::Role;

package t::PluginEntryPoints::Consumer;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

has listeningService => ( is => 'rw' );

sub init {
    my ($self) = @_;

    # Load listening service
    $self->p->loadService( "MyListeningService",
        "t::PluginEntryPoints::ListeningService" );
    $self->listeningService( $self->p->getService("MyListeningService") );

    # Use a callback, match by implemented method
    $self->addEntryPoint(
        can      => "my_entrypoint",
        callback => sub {
            my ( $plugin, @args ) = @_;
            $self->listeningService->notify( $plugin, @args );
        },
        args => ["param1"]
    );

    # Use a service directly, match by superclass
    $self->addEntryPoint(
        isa     => "My::Base",
        service => "MyListeningService",
        method  => "notify",
        args    => ["param2"]
    );

    # Use a service directly, match by implemented role
    $self->addEntryPoint(
        does    => "My::Role",
        service => "MyListeningService",
        method  => "notify",
        args    => ["param3"]
    );

    return 1;
}

1;
