package Lemonldap::NG::Portal::Auth::Radius;

use strict;
use Mouse;
use Authen::Radius;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADCREDENTIALS
  PE_RADIUSCONNECTFAILED
);

extends qw(Lemonldap::NG::Portal::Auth::_WebForm);

our $VERSION = '2.0.14';

# PROPERTIES

has radius => ( is => 'rw' );

has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{radiusAuthnLevel};
    }
);

sub initRadius {
    $_[0]->radius(
        Authen::Radius->new(
            Host   => $_[0]->conf->{radiusServer},
            Secret => $_[0]->conf->{radiusSecret}
        )
    );
}

# INITIALIZATION

sub init {
    my $self = shift;
    unless ( $self->initRadius ) {
        $self->error('Radius initialisation failed');
    }

    return $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
}

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;
    $self->initRadius unless $self->radius;
    unless ( $self->radius ) {
        $self->setSecurity($req);
        return PE_RADIUSCONNECTFAILED;
    }

    $self->logger->debug(
"Send authentication request ($req->{user}) to Radius server ($self->{conf}->{radiusServer})"
    );
    my $res = $self->radius->check_pwd( $req->user, $req->data->{password} );
    unless ( $res == 1 ) {
        $self->userLogger->warn("Unable to authenticate $req->{user}!");
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

1;
