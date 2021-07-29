package Lemonldap::NG::Portal::UserDB::WebID;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_MISSINGREQATTR
);

extends 'Lemonldap::NG::Common::Module';

our $VERSION = '2.0.12';

# INITIALIZATION

sub init {
    return 1;
}

# RUNNING METHODS

sub getUser {
    return PE_OK;
}

sub findUser {
    return PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    unless ( $req->data->{_webid} ) {
        $self->logger->error('No webid object found');
        return PE_ERROR;
    }

    my %vars = (
        %{ $self->conf->{exportedVars} },
        %{ $self->conf->{webIDExportedVars} }
    );
    while ( my ( $k, $v ) = each %vars ) {
        my $attr = $k;
        my $req;
        $attr =~ s/^!// and $req = 1;
        eval { $req->{sessionInfo}->{$attr} = $req->data->{_webid}->get($v) };
        $self->logger->error("Unable to get $v from FOAF document: $@")
          if ($@);
        if ( $req and not $req->{sessionInfo}->{$attr} ) {
            $self->userLogger->warn(
                "Required attribute $v is missing (user: $req->{user})");
            return PE_MISSINGREQATTR;
        }
    }

    return PE_OK;
}

sub setGroups {
    return PE_OK;
}

1;
