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

sub initRadius {

    my $dictionary_file = $_[0]->conf->{radiusDictionaryFile};
    if ($dictionary_file) {

        # required to be able to resolve names and values
        # default to /etc/raddb/dictionary ( same as Authen::Radius library ).
        if ( -f $dictionary_file ) {
            Authen::Radius->load_dictionary($dictionary_file);
        }
        else {
            # log an error, avoid server error if missing.
            $_[0]->logger->error(
"Radius library resolution of attribute names requires to set a dictionary in "
                  . $dictionary_file
                  . ", this file was not found." );
        }
    }
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
    $self->logger->debug("Radius auth OK");

# in case of a valid response $self->radius->{'attributes'} is filled with response attributes
    $req->data->{_radiusAttributes} = [ $self->radius->get_attributes() ];

    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    my $attributeMap = $self->sessionKeys;

    if ($attributeMap) {
        my $radiusReqAttributes = $req->data->{_radiusAttributes};
        foreach my $a ( @{$radiusReqAttributes} ) {
            $self->logger->debug( 'radius attribute '
                  . 'attrName='
                  . $a->{AttrName}
                  . ' name='
                  . $a->{Name} . ' tag='
                  . $a->{Tag} . '['
                  . $a->{Code} . '] = '
                  . $a->{RawValue} );
            my $sessionAttributeName = $attributeMap->{ $a->{AttrName} };
            if ($sessionAttributeName) {
                $req->sessionInfo->{$sessionAttributeName} = $a->{RawValue};
            }
            else {
                $self->logger->debug( 'No mapping for radius attribute '
                      . 'attrName='
                      . $a->{AttrName}
                      . ' name='
                      . $a->{Name} . ' tag='
                      . $a->{Tag} . '['
                      . $a->{Code}
                      . ']' );
            }
        }
    }
}

sub authLogout {
    return PE_OK;
}

1;
