##@file
# Radius authentication backend file

##@class
# Radius authentication backend class
package Lemonldap::NG::Portal::AuthRadius;

# Author: Sebastien Bahloul

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_WebForm;

our $VERSION = '1.9.1';
use base qw(Lemonldap::NG::Portal::_WebForm);

## @apmethod int authInit()
# Set _authnLevel
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    # require Perl module
    eval { require Authen::Radius; };
    if ($@) {
        $self->lmLog( "Module Authen::Radius not found in @INC", 'error' );
        return PE_ERROR;
    }

    $self->lmLog( "Opening connexion to " . $self->{radiusServer} . " ...",
        'debug' );
    $self->{radius} = new Authen::Radius(
        Host   => $self->{radiusServer},
        Secret => $self->{radiusSecret}
    );

    unless ( $self->{radius} ) {
        return PE_RADIUSCONNECTFAILED;
    }

    $self->{_authnLevel} = $self->{radiusAuthnLevel};

    PE_OK;
}

## @apmethod int authenticate()
# Authenticate user by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    unless ( $self->{radius} ) {
        return PE_RADIUSCONNECTFAILED;
    }

    my $res = $self->{radius}->check_pwd( $self->{user}, $self->{password} );

    unless ( $res == 1 ) {
        $self->_sub( 'userNotice',
            "Unable to authenticate " . $self->{user} . " !" );
        return PE_BADCREDENTIALS;
    }
    return PE_OK;
}

## @apmethod int authFinish()
# Unbind.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    my $self = shift;

    $self->{radius} = 0;

    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "standardform";
}

1;
