package Lemonldap::NG::Portal::UserDB::Proxy;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';

extends 'Lemonldap::NG::Portal::Main::UserDB';

our $VERSION = '2.19.0';

# INITIALIZATION

sub init {
    my ($self) = @_;
    if ( $self->conf->{proxyUseSoap} ) {
        extends 'Lemonldap::NG::Portal::Main::UserDB',
          'Lemonldap::NG::Portal::Lib::SOAPProxy';
    }
    else {
        extends 'Lemonldap::NG::Portal::Main::UserDB',
          'Lemonldap::NG::Portal::Lib::RESTProxy';
    }
    return $self->SUPER::init();
}

1;
