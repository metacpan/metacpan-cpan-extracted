# Self Yubikey registration
package Lemonldap::NG::Portal::2F::Register::Yubikey;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FORMEMPTY
  PE_ERROR
  PE_OK
);

our $VERSION = '2.19.0';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has type     => ( is => 'rw', default => 'UBK' );
has prefix   => ( is => 'rw', default => 'yubikey' );
has logo     => ( is => 'rw', default => 'yubikey.png' );
has template => ( is => 'ro', default => 'yubikey2fregister' );
has welcome  => ( is => 'ro', default => 'clickOnYubikey' );

# RUNNING METHODS

# Main method

use constant supportedActions => {
    register => "register",
    delete   => "delete",
};

sub register {

    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    my $otp  = $req->param('otp');
    my $UBKName =
      $self->checkNameSfa( $req, $self->type, $req->param('UBKName') );
    return $self->failHtmlResponse( $req, 'badName' ) unless $UBKName;

    if ( $otp
        and length($otp) > $self->conf->{yubikey2fPublicIDSize} )
    {
        my $key = substr( $otp, 0, $self->conf->{yubikey2fPublicIDSize} );

        # Read existing 2F device(s)
        my @alldevices = $self->find2fDevicesByType( $req, $req->userData );

        # Search if the Yubikey is already registered
        if ( grep { $_->{_yubikey} eq $key } @alldevices ) {
            return $self->failHtmlResponse( $req,
                'yourKeyIsAlreadyRegistered' );
        }

        my $res = $self->registerDevice(
            $req,
            $req->userData,
            {
                _yubikey => $key,
                type     => $self->type,
                name     => $UBKName,
                epoch    => time()
            }
        );
        if ( $res == PE_OK ) {
            return [
                302,
                [
                    Location => $self->p->buildUrl(
                        $req->portal, "2fregisters", { continue => 1 }
                    )
                ],
                []
            ];
        }
        else {
            $self->logger->debug( $self->prefix . "2f: unable to add device" );
            return $self->failResponse( $req, "PE$res" );
        }
    }
    else {
        return $self->failHtmlResponse( $req, "PE2" );
    }
}

1;
