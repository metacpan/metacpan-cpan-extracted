package Lemonldap::NG::Portal::UserDB::REST;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_OK
  PE_BADCREDENTIALS
);

extends 'Lemonldap::NG::Common::Module', 'Lemonldap::NG::Portal::Lib::REST';

our $VERSION = '2.0.2';

# INITIALIZATION

sub init {
    my $self = shift;

    # Add warning in log
    unless ( $self->conf->{restUserDBUrl} ) {
        $self->logger->error('No User REST URL given');
        return 0;
    }
    return 1;
}

# RUNNING METHODS

sub getUser {
    my ( $self, $req, %args ) = @_;
    my $res;
    $res = eval {
        $self->restCall( (
                  $args{useMail}
                ? $self->conf->{restMailDBUrl} || $self->conf->{restUserDBUrl}
                : $self->conf->{restUserDBUrl}
            ),
            { user => $req->user }
        );
    };
    if ($@) {
        $self->logger->error("UserDB REST error: $@");
        return PE_ERROR;
    }
    unless ( $res->{result} ) {
        $self->userLogger->warn( 'User ' . $req->user . ' not found' );
        return PE_BADCREDENTIALS;
    }
    $req->data->{restUserDBInfo} = $res->{info} || {};
    return PE_OK;
}

sub setSessionInfo {
    my ( $self, $req ) = @_;
    $req->sessionInfo->{$_} = $req->data->{restUserDBInfo}->{$_}
      foreach ( keys %{ $req->data->{restUserDBInfo} } );
    PE_OK;
}

sub setGroups {
    PE_OK;
}

1;
