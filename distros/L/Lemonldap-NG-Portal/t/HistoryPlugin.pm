package t::HistoryPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

sub init {
    my ($self) = @_;
    $self->addSessionDataToRemember(
        { "_language" => "Language", "authenticationLevel" => "__hidden__" } );
    return 1;
}

1;

