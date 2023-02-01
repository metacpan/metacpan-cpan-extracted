package Lemonldap::NG::Portal::Password::REST;

use strict;
use Mouse;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_PASSWORD_OK
);

extends qw(
  Lemonldap::NG::Portal::Lib::REST
  Lemonldap::NG::Portal::Password::Base
);

our $VERSION = '2.0.16';

sub init {
    my ($self) = @_;
    unless ($self->conf->{restPwdConfirmUrl}
        and $self->conf->{restPwdModifyUrl} )
    {
        $self->logger->error('Missing REST password URL');
        return 0;
    }
    return $self->SUPER::init;
}

sub confirm {
    my ( $self, $req, $pwd ) = @_;
    my $res = eval {
        $self->restCall(
            $self->conf->{restPwdConfirmUrl},
            { user => $req->user, password => $pwd }
        );
    };
    if ($@) {
        $self->logger("REST password confirm error: $@");
        return 0;
    }
    return ( $res->{result} ? 1 : 0 );
}

sub modifyPassword {
    my ( $self, $req, $pwd, %args ) = @_;
    my $res = eval {
        $self->restCall(
            $self->conf->{restPwdModifyUrl},
            {
                ( $args{useMail} ? 'mail' : 'user' ) => $req->user,
                useMail  => ( $args{useMail} ? JSON::true : JSON::false ),
                password => $pwd
            }
        );
    };
    if ($@) {
        $self->logger("REST password confirm error: $@");
        return PE_ERROR;
    }
    return ( $res->{result} ? PE_PASSWORD_OK : PE_ERROR );
}

1;
