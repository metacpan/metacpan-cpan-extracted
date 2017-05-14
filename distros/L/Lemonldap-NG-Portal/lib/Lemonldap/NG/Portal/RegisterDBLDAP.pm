##@file
# LDAP register backend file

##@class
# LDAP register backend class
package Lemonldap::NG::Portal::RegisterDBLDAP;

use strict;
use Lemonldap::NG::Portal::Simple;

## @method int computeLogin
# Compute a login from register infos
# @result Lemonldap::NG::Portal constant
sub computeLogin {
    my ($self) = @_;

    # Get first letter of firstname and lastname
    my $login =
      substr( lc $self->{registerInfo}->{firstname}, 0, 1 )
      . lc $self->{registerInfo}->{lastname};

    my $finalLogin = $login;

    # The uid must be unique
    my $i = 0;
    while ( $self->isLoginUsed($finalLogin) ) {
        $i++;
        $finalLogin = $login . $i;
    }

    $self->{registerInfo}->{login} = $finalLogin;

    return PE_OK;
}

## @method int createUser
# Insert new user
# @result Lemonldap::NG::Portal constant
sub createUser {
    my ($self) = @_;

    my $mesg = $self->ldap->add(
        "uid=" . $self->{registerInfo}->{login} . "," . $self->{ldapBase},
        attrs => [
            objectClass => [qw/top person organizationalPerson inetOrgPerson/],
            uid         => $self->{registerInfo}->{login},
            cn          => ucfirst $self->{registerInfo}->{firstname} . " "
              . uc $self->{registerInfo}->{lastname},
            sn           => uc $self->{registerInfo}->{lastname},
            givenName    => ucfirst $self->{registerInfo}->{firstname},
            userPassword => $self->{registerInfo}->{password},
            mail         => $self->{registerInfo}->{mail},
        ]
    );

    if ( $mesg->is_error ) {
        $self->lmLog(
            "Can not create entry for " . $self->{registerInfo}->{login},
            'error' );
        $self->lmLog( "LDAP error " . $mesg->error, 'error' );

        $self->ldap->unbind();
        $self->{flags}->{ldapActive} = 0;

        return PE_LDAPERROR;
    }

    return PE_OK;
}

## @method bool isLoginUsed
# Search if login is already in use
# @result 0 if login is used, 1 else
sub isLoginUsed {
    my ( $self, $login ) = @_;

    my $mesg = $self->ldap->search(
        base   => $self->{ldapBase},
        filter => "(uid=$login)",
        scope  => "sub",
        attrs  => ['1.1'],
    );

    if ( $mesg->code() != 0 ) {
        $self->lmLog( "LDAP Search error for $login: " . $mesg->error, 'warn' );
        return 1;
    }

    if ( $mesg->count() > 0 ) {
        $self->lmLog( "Login $login already used in LDAP", 'debug' );
        return 1;
    }

    return 0;
}

## @apmethod int registerDBFinish()
# Unbind.
# @return Lemonldap::NG::Portal constant
sub registerDBFinish {
    my $self = shift;

    if ( ref( $self->{ldap} ) && $self->{flags}->{ldapActive} ) {
        $self->ldap->unbind();
        $self->{flags}->{ldapActive} = 0;
    }

    PE_OK;
}

1;
