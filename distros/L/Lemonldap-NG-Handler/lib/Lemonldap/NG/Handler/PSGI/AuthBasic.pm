package Lemonldap::NG::Handler::PSGI::AuthBasic;

use strict;
use Mouse;
use Lemonldap::NG::Handler::Specific::AuthBasic;

extends 'Lemonldap::NG::Handler::PSGI::Server';

sub init {
    my $self = shift;
    $self->subhandler('Lemonldap::NG::Handler::Specific::AuthBasic');
    return $self->SUPER::init(@_);
}

our $VERSION = '1.9.6';

1;
