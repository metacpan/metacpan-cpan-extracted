package Lemonldap::NG::Portal::Register::LDAP;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_LDAPERROR
  PE_MALFORMEDUSER
  PE_LDAPCONNECTFAILED
);

extends qw(
  Lemonldap::NG::Portal::Lib::LDAP
  Lemonldap::NG::Portal::Register::Base
);

our $VERSION = '2.0.14';

# RUNNING METHODS

# Compute a login from register infos
# @result Lemonldap::NG::Portal constant
sub computeLogin {
    my ( $self, $req ) = @_;
    return PE_LDAPCONNECTFAILED unless $self->ldap and $self->bind();

    # Get first letter of firstname and lastname
    my $login = $self->applyLoginRule($req);
    return PE_MALFORMEDUSER unless $login;

    my $finalLogin = $login;

    # The uid must be unique
    my $i = 0;
    while ( $self->isLoginUsed($finalLogin) ) {
        $i++;
        $finalLogin = $login . $i;
    }

    $req->data->{registerInfo}->{login} = $finalLogin;
    return PE_OK;
}

## @method int createUser
# Do nothing
# @result Lemonldap::NG::Portal constant
sub createUser {
    my ( $self, $req ) = @_;

    # LDAP connection has been verified by computeLogin
    my $sn = uc $req->data->{registerInfo}->{lastname};
    my $gn = ucfirst $req->data->{registerInfo}->{firstname};
    my $cn = "$gn $sn";
    utf8::decode($cn);
    utf8::decode($sn);
    utf8::decode($gn);
    my $mesg = $self->ldap->add(
        "uid="
          . $req->data->{registerInfo}->{login} . ","
          . $self->conf->{ldapBase},
        attrs => [
            objectClass  => [qw/top person organizationalPerson inetOrgPerson/],
            uid          => $req->data->{registerInfo}->{login},
            cn           => $cn,
            sn           => $sn,
            givenName    => $gn,
            userPassword => $req->data->{registerInfo}->{password},
            mail         => $req->data->{registerInfo}->{mail},
        ]
    );

    if ( $mesg->is_error ) {
        $self->userLogger->error(
            "Can not create entry for " . $req->data->{registerInfo}->{login} );
        $self->logger->error(
            "LDAP error " . $mesg->code . ": " . $mesg->error );

        $self->ldap->unbind();

        return PE_LDAPERROR;
    }
    return PE_OK;
}

# PRIVATE METHODS

# Search if login is already in use
sub isLoginUsed {
    my ( $self, $login ) = @_;

    my $mesg = $self->ldap->search(
        base   => $self->conf->{ldapBase},
        filter => "(uid=$login)",
        scope  => "sub",
        attrs  => ['1.1'],
    );

    if ( $mesg->code() != 0 ) {
        $self->logger->warn( "LDAP Search error for $login: " . $mesg->error );
        return 1;
    }

    if ( $mesg->count() > 0 ) {
        $self->logger->debug("Login $login already used in LDAP");
        return 1;
    }

    return 0;
}

1;
