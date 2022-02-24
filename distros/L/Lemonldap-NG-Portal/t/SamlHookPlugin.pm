package t::SamlHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => { samlGotAuthnRequest => 'gotRequest', };

sub gotRequest {
    my ( $self, $res, $login ) = @_;

    # Return a weird
    return -999;
}

1;

