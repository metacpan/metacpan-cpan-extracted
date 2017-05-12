##@file
# LDAP authentication backend file

##@class
# LDAP authentication backend class
package Lemonldap::NG::Portal::AuthLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap
use Lemonldap::NG::Portal::_WebForm;
use Lemonldap::NG::Portal::UserDBLDAP;      #inherits

our $VERSION = '1.4.0';
use base qw(Lemonldap::NG::Portal::_WebForm);

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBLDAP::search;

## @apmethod int authInit()
# Set _authnLevel
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    $self->{_authnLevel} = $self->{ldapAuthnLevel};

    PE_OK;
}

## @apmethod int authenticate()
# Authenticate user by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        $self->{sessionInfo}->{dn} = $self->{dn};
        return $tmp if ($tmp);
    }

    my $res =
      $self->ldap->userBind( $self->{dn}, password => $self->{password} );

    # Remember password if password reset needed
    $self->{oldpassword} = $self->{password}
      if ( $res == PE_PP_CHANGE_AFTER_RESET );

    # Unbind if there was an error
    unless ( $res == PE_OK ) {
        $self->ldap->unbind;
        $self->{flags}->{ldapActive} = 0;
    }

    return $res;
}

## @apmethod int authFinish()
# Unbind.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    my $self = shift;

    if ( ref( $self->{ldap} ) && $self->{flags}->{ldapActive} ) {
        $self->ldap->unbind();
        $self->{flags}->{ldapActive} = 0;
    }

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
