package Lemonldap::NG::Portal::Auth::Radius;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Lib::Radius;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADCREDENTIALS
  PE_RADIUSCONNECTFAILED
);

extends qw(Lemonldap::NG::Portal::Auth::_WebForm);

our $VERSION = '2.0.14';

# PROPERTIES

has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{radiusAuthnLevel};
    }
);

has modulename => ( is => 'ro', default => 'radius' );
has radiusLib  => ( is => 'rw' );

# conf radiusExportedVars with key,value swapped.
has sessionKeys => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self         = shift;
        my $sessionKeys  = {};
        my $attributeMap = $self->conf->{radiusExportedVars};
        if ($attributeMap) {

            # Swap key value  {session => radius} to {radius => session}
            while ( my ( $k, $v ) = each %{$attributeMap} ) {
                $sessionKeys->{$v} = $k;
            }
        }
        return $sessionKeys;
    }
);

# INITIALIZATION

sub init {
    my $self = shift;
    $self->radiusLib(
        Lemonldap::NG::Portal::Lib::Radius->new(
            radius_dictionary           => $self->conf->{radiusDictionaryFile},
            radius_req_attribute_config =>
              $self->conf->{radiusRequestAttributes},
            radius_secret  => $self->conf->{radiusSecret},
            radius_server  => $self->conf->{radiusServer},
            radius_timeout => $self->conf->{radiusTimeout},
            modulename     => "radius",
            logger         => $self->logger,
            p              => $self->p,
        )
    );
    return $self->Lemonldap::NG::Portal::Auth::_WebForm::init();
}

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;

    $self->logger->debug( "Send authentication request ($req->{user})"
          . " to Radius server ($self->{conf}->{radiusServer})" );

    # Session info is empty or unknown at this step
    my $res = $self->radiusLib->check_pwd( $req, {}, $req->user,
        $req->data->{password} );
    unless ($res) {
        return PE_RADIUSCONNECTFAILED;
    }
    unless ( $res->{result} == 1 ) {
        $self->userLogger->warn("Radius authentication failed for user " . $req->{user});
        $self->setSecurity($req);
        return PE_BADCREDENTIALS;
    }
    $self->logger->debug("Radius auth OK");

    # in case of a valid response $self->radius->{'attributes'}
    # is filled with response attributes
    $req->data->{_radiusAttributes} = $res->{attributes};

    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    my $attributeMap = $self->sessionKeys;

    if ($attributeMap) {
        while ( my ( $attr_radname, $attr_value ) =
            each %{ $req->data->{_radiusAttributes} || {} } )
        {
            my $sessionAttributeName = $attributeMap->{$attr_radname};
            if ($sessionAttributeName) {
                $req->sessionInfo->{$sessionAttributeName} = $attr_value;
            }
        }
    }
}

sub authLogout {
    return PE_OK;
}

1;
