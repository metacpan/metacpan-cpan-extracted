package Lemonldap::NG::Portal::UserDB::Proxy;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.12';

# INITIALIZATION

sub init {
    my ($self) = @_;
    if ( $self->conf->{proxyUseSoap} ) {
        extends 'Lemonldap::NG::Common::Module',
          'Lemonldap::NG::Portal::Lib::SOAPProxy';
    }
    else {
        extends 'Lemonldap::NG::Common::Module',
          'Lemonldap::NG::Portal::Lib::RESTProxy';
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub setGroups {
    return PE_OK;
}

1;
