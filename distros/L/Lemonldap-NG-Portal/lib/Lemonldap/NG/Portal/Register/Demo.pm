package Lemonldap::NG::Portal::Register::Demo;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.0';

sub init {
    1;
}

# Compute a login from register infos
# @result Lemonldap::NG::Portal constant
sub computeLogin {
    my ( $self, $req ) = @_;

    # Get first letter of firstname and lastname
    my $login =
      substr( lc $req->data->{registerInfo}->{firstname}, 0, 1 )
      . lc $req->data->{registerInfo}->{lastname};

    $req->data->{registerInfo}->{login} = $login;

    return PE_OK;
}

## @method int createUser
# Do nothing
# @result Lemonldap::NG::Portal constant
sub createUser {
    my ( $self, $req ) = @_;
    $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{ $req->data
          ->{registerInfo}->{login} } = {
        uid => $req->data->{registerInfo}->{login},
        cn  => $req->data->{registerInfo}->{firstname} . ' '
          . $req->data->{registerInfo}->{lastname},
        mail => $req->data->{registerInfo}->{login} . '@badwolf.org',
          };
    return PE_OK;
}

1;
