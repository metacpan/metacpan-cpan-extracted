package t::PasswordHookPlugin;

use Mouse;
use Lemonldap::NG::Portal::Main::Constants
  qw/PE_PP_INSUFFICIENT_PASSWORD_QUALITY PE_OK/;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => {
    passwordBeforeChange => 'beforeChange',
    passwordAfterChange  => 'afterChange',
};

sub beforeChange {
    my ( $self, $req, $user, $password, $old ) = @_;
    if ( $password eq "12345" ) {
        $self->logger->error("I've got the same combination on my luggage");
        return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
    }
    return PE_OK;
}

sub afterChange {
    my ( $self, $req, $user, $password, $old ) = @_;
    $old ||= "";
    $req->pdata->{afterHook} = "$user-$old-$password";
    $self->logger->debug("Password changed for $user: $old -> $password");
    return PE_OK;
}

1;
