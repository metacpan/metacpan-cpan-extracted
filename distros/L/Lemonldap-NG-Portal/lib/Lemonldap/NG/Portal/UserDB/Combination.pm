package Lemonldap::NG::Portal::UserDB::Combination;

our $VERSION = '2.0.0';

sub new {
    return $_[1]->{p}->{_authentication};
}

1;
