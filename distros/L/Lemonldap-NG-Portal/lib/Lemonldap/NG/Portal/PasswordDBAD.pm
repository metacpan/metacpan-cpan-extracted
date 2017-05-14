##@file
# AD password backend file

##@class
# AD password backend class
package Lemonldap::NG::Portal::PasswordDBAD;

use strict;
use Lemonldap::NG::Portal::Simple;

#inherits Lemonldap::NG::Portal::_SMTP

our $VERSION = '1.9.1';

use base qw(Lemonldap::NG::Portal::PasswordDBLDAP);

*_formateFilter = *Lemonldap::NG::Portal::UserDBAD::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBAD::search;

## @apmethod int modifyPassword()
# Modify the password by LDAP mechanism.
# Use AD specific method
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

    # Call the modify password method for AD
    my $code =
      $self->ldap->userModifyPassword( $self->{dn}, $self->{newpassword},
        $self->{confirmpassword},
        $self->{oldpassword}, 1 );

    return $code unless ( $code == PE_PASSWORD_OK );

    # If force reset, set reset flag
    if ( $self->{forceReset} ) {
        my $result =
          $self->ldap->modify( $self->{dn},
            replace => { 'pwdLastSet' => '0' } );

        unless ( $result->code == 0 ) {
            $self->lmLog( "LDAP modify pwdLastSet error: " . $result->code,
                'error' );
            $code = PE_LDAPERROR;
        }

        $self->lmLog( "pwdLastSet set to 0", 'debug' );
    }

    return $code;
}

1;
