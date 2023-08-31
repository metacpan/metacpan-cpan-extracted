package t::SendHtmlPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => { sendHtml => 'injectParam', };

sub injectParam {
    my ( $self, $req, $tpl, $args ) = @_;

    # replace Captcha URL
    if ( $$tpl eq "captcha" ) {
        $args->{params}->{CAPTCHA_SRC} = "xxxreplacedxxx";
        return 0;
    }

    # Replace template
    if ( $req->uri =~ /myhook/ ) {
        $$tpl = "oidcGiveConsent";
        return 0;
    }

    # Add variable to the "menu.tpl" template
    if ( $$tpl eq "menu" ) {
        $args->{params}->{AUTH_USER} = "CUSTOM";
        $args->{code} = 299;
        return 0;
    }
    return 0;
}

1;
