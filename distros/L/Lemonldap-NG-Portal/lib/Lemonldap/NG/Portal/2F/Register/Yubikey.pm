# Self Yubikey registration
package Lemonldap::NG::Portal::2F::Register::Yubikey;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FORMEMPTY
  PE_ERROR
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
sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    if ( $action eq 'register' ) {
        my $otp = $req->param('otp');
        my $UBKName =
          $self->checkNameSfa( $req, $self->type, $req->param('UBKName') );
        return $self->p->sendError( $req, 'badName', 200 ) unless $UBKName;

        if ( $otp
            and length($otp) > $self->conf->{yubikey2fPublicIDSize} )
        {
            my $key = substr( $otp, 0, $self->conf->{yubikey2fPublicIDSize} );

            # Read existing 2F device(s)
            my @alldevices = $self->find2fDevicesByType( $req, $req->userData );

            # Search if the Yubikey is already registered
            if ( grep { $_->{_yubikey} eq $key } @alldevices ) {
                $self->userLogger->error(
                    $self->prefix . '2f: device already registered!' );
                return $self->p->sendHtml(
                    $req, 'error',
                    params => {
                        RAW_ERROR       => 'yourKeyIsAlreadyRegistered',
                        AUTH_ERROR_TYPE => 'warning',
                    }
                );
            }

            if (
                $self->add2fDevice(
                    $req,
                    $req->userData,
                    {
                        _yubikey => $key,
                        type     => $self->type,
                        name     => $UBKName,
                        epoch    => time()
                    }
                )
              )
            {
                $self->markRegistered($req);
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
                $self->logger->debug(
                    $self->prefix . "2f: unable to add device" );
                return $self->p->sendError( $req, 'serverError' );
            }
        }
        else {
            $self->userLogger->error( $self->prefix . "2f: no code provided" );
            return $self->p->sendHtml(
                $req, 'error',
                params => {
                    AUTH_ERROR                       => PE_FORMEMPTY,
                    ( 'AUTH_ERROR_' . PE_FORMEMPTY ) => 1,
                    AUTH_ERROR_TYPE                  => 'positive',
                }
            );
        }
    }

    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->userCanRemove;

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req,
            $self->prefix . '2f: "epoch" parameter is missing', 400 );
        if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
        $self->logger->error( $self->prefix . "2f: device not found" );
        return $self->p->sendError( $req, '2FDeviceNotFound', 400 );
    }
    else {
        $self->logger->error( $self->prefix . "2f: unknown action ($action)" );
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }
}

1;
