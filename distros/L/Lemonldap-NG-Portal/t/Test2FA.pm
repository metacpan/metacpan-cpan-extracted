package t::Test2FA;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_SENDRESPONSE
);

our $VERSION = '2.19.0';

extends qw(
  Lemonldap::NG::Portal::Main::SecondFactor
);
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'test' );
has logo   => ( is => 'rw', default => 'test.png' );

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;

    # Prepare form
    my $tmp = $self->p->sendHtml(
        $req,
        'ext2fcheck',
        params => {
            TOKEN  => $token,
            TARGET => "/test2fcheck",
            $self->get2fTplParams($req),
        }
    );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;

    my ($device) = $self->find2fDevicesByType( $req, $session, "test" );
    $req->data->{_2fDevice} = $device;
    return PE_OK;
}

1;
