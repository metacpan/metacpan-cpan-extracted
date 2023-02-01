package Lemonldap::NG::Portal::Password::Choice;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_ERROR';

extends qw(
  Lemonldap::NG::Portal::Lib::Choice
  Lemonldap::NG::Portal::Password::Base
);

our $VERSION = '2.0.16';

sub init {
    my ($self) = @_;
    return 0
      unless ( $self->Lemonldap::NG::Portal::Password::Base::init()
        and $self->Lemonldap::NG::Portal::Lib::Choice::init(2) );
    $self->p->{_passwordDB} = $self;
}

sub confirm {
    my ( $self, $req, $pwd ) = @_;
    $self->checkChoice($req) or return PE_ERROR;
    return $req->data->{enabledMods2}->[0]->confirm( $req, $pwd );
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    $self->checkChoice($req) or return PE_ERROR;
    return $req->data->{enabledMods2}->[0]->modifyPassword( $req, $pwd, %args );
}

1;
