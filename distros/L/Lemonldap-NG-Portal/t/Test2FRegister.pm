package t::Test2FRegister;

use strict;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
);
use Mouse;

our $VERSION = '2.23.0';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has logo     => ( is => 'rw', default => 'test.png' );
has prefix   => ( is => 'ro', default => 'test' );
has template => ( is => 'ro', default => 'generic2fregister' );
has welcome  => ( is => 'ro', default => 'generic2fwelcome' );
has type     => ( is => 'ro', default => 'test' );

use constant supportedActions => {
    register => "register",
    modify   => "modify",
    delete   => "delete",
};

sub register {
    my ( $self, $req ) = @_;

    my $private = $req->param('private');
    if ($private) {

        my $res = $self->registerDevice(
            $req,
            $req->userData,
            {
                _private => $private,
                type     => $self->type,
                name     => "MyTest",
                epoch    => time()
            }
        );
        if ( $res == PE_OK ) {
            return $self->p->sendJSONresponse( $req, { result => 1 } );
        }
        else {
            return $self->failResponse( $req, "PE$res" );
        }
    }
}

sub delete {
    my ( $self, $req ) = @_;

    # disable CSRF check
    $req->headers->header( 'X-CSRF-Check' => 1 );

    delete $req->userData->{hookStatus} if $req->userData->{hookStatus};
    if ( $req->param('hookStatus') ) {
        $req->userData->{hookStatus} = $req->param('hookStatus');
    }

    return $self->SUPER::delete($req);
}

1;
