package Lemonldap::NG::Portal::Auth::Slave;

use strict;
use Mouse;

# Add constants used by this module
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_FORBIDDENIP
  PE_USERNOTFOUND
);

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Portal::Main::Auth
  Lemonldap::NG::Portal::Lib::Slave
);

# INITIALIZATION

sub init { 1 }

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    return PE_FORBIDDENIP
      unless ( $self->checkIP($req) and $self->checkHeader($req) );

    unless ( $self->conf->{slaveUserHeader} ) {
        $self->logger->debug('slaveUserHeader is undefined');
        return PE_USERNOTFOUND;
    }

    my $user_header = $self->conf->{slaveUserHeader};
    $user_header = 'HTTP_' . uc($user_header);
    $user_header =~ s/\-/_/g;

    unless ( $req->{user} = $req->env->{$user_header} ) {
        $self->userLogger->error(
            "No header " . $self->conf->{slaveUserHeader} . " found" );
        return PE_USERNOTFOUND;
    }
    return PE_OK;
}

sub authenticate {
    my ( $self, $req ) = @_;
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{slaveAuthnLevel};
    return PE_OK;
}

sub getDisplayType {
    my ($self) = @_;
    return ( $self->{conf}->{slaveDisplayLogo} ? "logo" : "_none_" );
}

sub authLogout {
    my ( $self, $req ) = @_;
    return PE_OK;
}

1;
