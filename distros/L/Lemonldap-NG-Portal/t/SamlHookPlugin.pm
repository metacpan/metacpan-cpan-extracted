package t::SamlHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => { samlGotAuthnRequest => 'gotRequest', };

sub init {
    my ($self) = @_;
    return 1;
}

sub gotRequest {
    my ( $self, $res, $login ) = @_;

    # Return a weird
    return -999;
}

1;

