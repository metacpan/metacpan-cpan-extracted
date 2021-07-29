##@file
# Demo authentication backend file

##@class
# Demo authentication backend class
package Lemonldap::NG::Portal::Auth::Demo;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_BADCREDENTIALS);

extends qw(Lemonldap::NG::Portal::Auth::_WebForm);

our $VERSION = '2.0.12';

# INITIALIZATION

# Initialize demo accounts
# @return Lemonldap::NG::Portal constant
sub init {
    my $self = shift;

    # Add warning in log
    $self->logger->warn(
        "Using demonstration mode, go to Manager to edit the configuration");

    return $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
}

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;

    unless ( $req->{user} eq $req->data->{password} ) {
        $self->userLogger->warn("Bad password for $req->{user}");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }

    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

1;
