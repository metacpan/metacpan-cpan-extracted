package Lemonldap::NG::Portal::UserDB::Remote;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Common::Module
  Lemonldap::NG::Portal::Lib::Remote
);

# RUNNING METHODS

*getUser = *Lemonldap::NG::Portal::Lib::Remote::checkRemoteId;

sub findUser {

    # Nothing to do here
    return PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    delete $req->data->{rSessionInfo}->{_session_id};
    $req->{sessionInfo} = $req->data->{rSessionInfo};

    return PE_OK;
}

sub setGroups {
    return PE_OK;
}

1;
