##@file
# LDAP password backend file

##@class
# LDAP password backend class
package Lemonldap::NG::Portal::PasswordDBLDAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap
use Lemonldap::NG::Portal::UserDBLDAP;      #inherits

#inherits Lemonldap::NG::Portal::_SMTP

our $VERSION = '1.9.1';

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBLDAP::search;

## @apmethod int passwordDBInit()
# Load SMTP functions
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };
    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }
    PE_OK;
}

## @apmethod int modifyPassword()
# Modify the password by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit method if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }

    $self->lmLog( "Modify password request for " . $self->{dn}, 'debug' );

    # Call the modify password method
    my $code = $self->ldap->userModifyPassword(
        $self->{dn},              $self->{newpassword},
        $self->{confirmpassword}, $self->{oldpassword}
    );

    unless ( $code == PE_PASSWORD_OK ) {
        $self->ldap->unbind;
        $self->{flags}->{ldapActive} = 0;
        return $code;
    }

    # If password policy and force reset, set reset flag
    if (    $self->{ldapPpolicyControl}
        and $self->{forceReset}
        and $self->{ldapUsePasswordResetAttribute} )
    {
        my $result = $self->ldap->modify(
            $self->{dn},
            replace => {
                $self->{ldapPasswordResetAttribute} =>
                  $self->{ldapPasswordResetAttributeValue}
            }
        );

        unless ( $result->code == 0 ) {
            $self->lmLog(
                "LDAP modify "
                  . $self->{ldapPasswordResetAttribute}
                  . " error: "
                  . $result->code,
                'error'
            );
            $self->ldap->unbind;
            $self->{flags}->{ldapActive} = 0;
            return PE_LDAPERROR;
        }

        $self->lmLog(
            $self->{ldapPasswordResetAttribute}
              . " set to "
              . $self->{ldapPasswordResetAttributeValue},
            'debug'
        );
    }

    return $code;
}

## @apmethod int passwordDBFinish()
# Unbind.
# @return Lemonldap::NG::Portal constant
sub passwordDBFinish {
    my $self = shift;

    if ( ref( $self->{ldap} ) && $self->{flags}->{ldapActive} ) {
        $self->ldap->unbind();
        $self->{flags}->{ldapActive} = 0;
    }

    PE_OK;
}

1;
