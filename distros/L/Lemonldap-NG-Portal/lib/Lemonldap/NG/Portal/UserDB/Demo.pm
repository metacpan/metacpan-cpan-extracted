## @file
# Demo userDB mechanism

## @class
# Demo userDB mechanism class
package Lemonldap::NG::Portal::UserDB::Demo;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_USERNOTFOUND);

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.0';

# Sample accounts from Doctor Who characters
our %demoAccounts = (
    'rtyler' => {
        'uid'  => 'rtyler',
        'cn'   => 'Rose Tyler',
        'mail' => 'rtyler@badwolf.org',
    },
    'msmith' => {
        'uid'  => 'msmith',
        'cn'   => 'Mickey Smith',
        'mail' => 'msmith@badwolf.org',
    },
    'dwho' => {
        'uid'  => 'dwho',
        'cn'   => 'Doctor Who',
        'mail' => 'dwho@badwolf.org',
    },
);

# INITIALIZATION

sub init {
    1;
}

# RUNNING METHODS

## @apmethod int getUser()
# Check known accounts
# @return Lemonldap::NG::Portal constant
sub getUser {
    my ( $self, $req, %args ) = @_;

    if ( $args{useMail} ) {
        return PE_OK
          if (
            ( $req->{user} ) =
            grep { $demoAccounts{$_}->{mail} eq $req->{user} }
            keys %demoAccounts
          );
    }
    else {
        return PE_OK
          if ( defined $demoAccounts{ $req->user } );
    }

    eval { $self->p->_authentication->setSecurity($req) };
    PE_USERNOTFOUND;
}

## @apmethod int setSessionInfo()
# Get sample data
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my ( $self, $req ) = @_;

    my %vars = ( %{ $self->conf->{exportedVars} },
        %{ $self->conf->{demoExportedVars} } );
    while ( my ( $k, $v ) = each %vars ) {
        $req->{sessionInfo}->{$k} = $demoAccounts{ $req->{user} }->{$v}
          || "";
    }

    PE_OK;
}

## @apmethod int setGroups()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    PE_OK;
}

1;
