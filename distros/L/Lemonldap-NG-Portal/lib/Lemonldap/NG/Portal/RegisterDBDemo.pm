##@file
# Demo register backend file

##@class
# Demo register backend class
package Lemonldap::NG::Portal::RegisterDBDemo;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.1';

## @method int computeLogin
# Compute a login from register infos
# @result Lemonldap::NG::Portal constant
sub computeLogin {
    my ($self) = @_;

    # Get first letter of firstname and lastname
    my $login =
      substr( lc $self->{registerInfo}->{firstname}, 0, 1 )
      . lc $self->{registerInfo}->{lastname};

    $self->{registerInfo}->{login} = $login;

    return PE_OK;
}

## @method int createUser
# Do nothing
# @result Lemonldap::NG::Portal constant
sub createUser {
    my ($self) = @_;

    return PE_OK;
}

## @method int registerDBFinish
# Do nothing
# @result Lemonldap::NG::Portal constant
sub registerDBFinish {
    my ($self) = @_;

    return PE_OK;
}

1;
