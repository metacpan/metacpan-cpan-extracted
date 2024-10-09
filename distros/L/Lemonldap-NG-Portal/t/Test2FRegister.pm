package t::Test2FRegister;

use strict;
use Lemonldap::NG::Portal::Main::Constants qw/PE_OK PE_ERROR/;
use Mouse;

our $VERSION = '2.19.0';

extends qw(
  Lemonldap::NG::Portal::2F::Register::Base
);

with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has logo     => ( is => 'rw', default => 'test.png' );
has prefix   => ( is => 'rw', default => 'test' );
has template => ( is => 'ro', default => 'generic2fregister' );
has welcome  => ( is => 'ro', default => 'generic2fwelcome' );
has type     => ( is => 'ro', default => 'test' );

sub run {
    my ( $self, $req, $path ) = @_;
    if ( $path eq "register" ) {

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
    return $self->p->sendError( $req, 'error', 400 );
}

1;
