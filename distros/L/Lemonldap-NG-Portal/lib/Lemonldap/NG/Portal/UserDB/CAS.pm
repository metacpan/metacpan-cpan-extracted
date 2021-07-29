package Lemonldap::NG::Portal::UserDB::CAS;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_OK
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Common::Module';

# INITIALIZATION

sub init {
    return 1;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req ) = @_;
    return PE_OK;
}

sub findUser {
    my ( $self, $req ) = @_;

    # Nothing to do here
    return PE_OK;
}

# Get all required attributes
sub setSessionInfo {
    my ( $self, $req ) = @_;
    my $srv;
    unless ( $srv = $req->data->{_casSrvCurrent} ) {
        $self->logger->error('UserDB::CAS must be used with Auth::CAS');
        return PE_ERROR;
    }
    my %ev = (
        %{ $self->conf->{casSrvMetaDataExportedVars}->{$srv} || {} },
        %{ $self->conf->{exportedVars} }
    );
    foreach ( keys %ev ) {
        $req->{sessionInfo}->{$_} = $req->data->{casAttrs}->{$_};
    }

    return PE_OK;
}

# Does nothing
sub setGroups {
    return PE_OK;
}

1;
