package t::PluginEntryPoints::Target;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

extends 'Lemonldap::NG::Portal::Main::Plugin', 'My::Base';

with 'My::Role';

sub init {
    my ($self) = @_;
    1;
}

sub my_entrypoint {
    my ($self) = @_;
    1;
}

1;
