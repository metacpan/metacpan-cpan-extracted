## @file
# Slave userDB mechanism

## @class
# Slave userDB mechanism class
package Lemonldap::NG::Portal::UserDB::Slave;

use strict;
use Mouse;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_FORBIDDENIP
);

our $VERSION = '2.0.10';

extends qw(
  Lemonldap::NG::Common::Module
  Lemonldap::NG::Portal::Lib::Slave
);

# INITIALIZATION

sub init { 1 }

# RUNNING METHODS

sub getUser {
    PE_OK;
}

sub findUser {
    PE_OK;
}

# Search exportedVars values in HTTP headers.
sub setSessionInfo {
    my ( $self, $req ) = @_;

    return PE_FORBIDDENIP
      unless ( $self->checkIP($req) );

    my %vars = (
        %{ $self->conf->{exportedVars} },
        %{ $self->conf->{slaveExportedVars} }
    );
    while ( my ( $k, $v ) = each %vars ) {
        $v = 'HTTP_' . uc($v);
        $v =~ s/\-/_/g;
        $req->{sessionInfo}->{$k} = $req->{$v};
    }
    return PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
