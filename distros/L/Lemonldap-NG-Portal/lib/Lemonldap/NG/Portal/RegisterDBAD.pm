##@file
# AD register backend file

##@class
# AD register backend class
package Lemonldap::NG::Portal::RegisterDBAD;

use strict;
use Lemonldap::NG::Portal::Simple;
use base qw/Lemonldap::NG::Portal::RegisterDBLDAP/;
use Unicode::String qw(utf8);

## @method int createUser
# Insert new user
# @result Lemonldap::NG::Portal constant
sub createUser {
    my ($self) = @_;

    my $name =
      ucfirst $self->{registerInfo}->{firstname} . " "
      . uc $self->{registerInfo}->{lastname};

    my $mesg = $self->ldap->add(
        "cn=$name," . $self->{ldapBase},
        attrs => [
            objectClass    => [qw/top person organizationalPerson user/],
            sAMAccountName => $self->{registerInfo}->{login},
            cn             => $name,
            sn             => uc $self->{registerInfo}->{lastname},
            givenName      => ucfirst $self->{registerInfo}->{firstname},
            unicodePwd =>
              utf8( chr(34) . $self->{registerInfo}->{password} . chr(34) )
              ->utf16le(),
            mail => $self->{registerInfo}->{mail},
        ]
    );

    if ( $mesg->is_error ) {
        $self->lmLog(
            "Can not create entry for " . $self->{registerInfo}->{login},
            'error' );
        $self->lmLog( "LDAP error " . $mesg->error, 'error' );
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
        filter => "(sAMAccountName=$login)",
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

1;
