##@file
# DBI password backend file

##@class
# DBI password backend class
package Lemonldap::NG::Portal::PasswordDBDBI;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::AuthDBI;    #inherits
use base qw(Lemonldap::NG::Portal::_DBI );

#inherits Lemonldap::NG::Portal::_SMTP

our $VERSION = '1.9.1';

## @apmethod int passwordDBInit()
# Load SMTP functions and call DBI authInit()
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };
    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }
    unless ( $self->{dbiPasswordMailCol} ) {
        $self->lmLog( "Missing configuration parameters for DBI password reset",
            'error' );
        return PE_ERROR;
    }
    return $self->Lemonldap::NG::Portal::AuthDBI::authInit();
}

## @apmethod int modifyPassword()
# Modify the password
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    # Check if portal require old password
    if ( $self->{portalRequireOldPassword} ) {
        unless ( $self->{oldpassword} ) {
            $self->lmLog( "Portal require old password", 'error' );
            return PE_PP_MUST_SUPPLY_OLD_PASSWORD;
        }
    }

    # Verify confirmation password matching
    return PE_PASSWORD_MISMATCH
      unless ( $self->{newpassword} eq $self->{confirmpassword} );

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiAuthChain}, $self->{dbiAuthUser},
        $self->{dbiAuthPassword} );
    return PE_ERROR unless $dbh;

    my $user = $self->{sessionInfo}->{_user};

    # Check old password
    if ( $self->{oldpassword} ) {

        my $result = $self->check_password( $dbh, $user, $self->{oldpassword} );

        unless ($result) {
            return PE_BADOLDPASSWORD;
        }
    }

    # Modify password
    my $result = $self->modify_password( $user, $self->{newpassword} );

    unless ($result) {
        return PE_ERROR;
    }

    $self->lmLog( "Password changed for $user", 'debug' );

    PE_PASSWORD_OK;
}

1;
