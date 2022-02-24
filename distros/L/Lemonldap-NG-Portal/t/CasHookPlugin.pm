package t::CasHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => {
    casGotRequest                 => 'filterService',
    'casGenerateServiceTicket'    => 'changeRedirectUrl',
    'casGenerateValidateResponse' => 'genResponse',
};

sub filterService {
    my ( $self, $req, $cas_request ) = @_;
    if ( $cas_request->{service} eq "http://auth.sp.com/" ) {
        return 0;
    }
    else {
        return 999;
    }
}

sub changeRedirectUrl {
    my ( $self, $req, $cas_request, $app, $Sinfos ) = @_;
    $cas_request->{service} .= "?hooked=1";
    return 0;
}

sub genResponse {
    my ( $self, $req, $username, $attributes ) = @_;

    $attributes->{hooked} = 1;

    return 0;
}

1;

