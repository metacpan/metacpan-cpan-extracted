package t::CustomMenu;

use strict;
use Test::More;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);
use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant name => "Custom";

has rule => (
    is      => "ro",
    lazy    => 1,
    builder => sub { $_[0]->conf->{customMenuRule} }
);
with 'Lemonldap::NG::Portal::MenuTab';

sub init {
    my ($self) = @_;
    return 1;
}

sub display {
    my ( $self, $req ) = @_;
    return {
        logo => "wrench",
        name => "myplugin",
        id   => "myplugin",
        html => $self->loadTemplate( $req, 'custommenu' ),
    };
}

1;
