# mock version
use strict;
use warnings;
package Net::Netrc;

my $fake = {
  login => 'jdoe@example.com',
  account => 'jdoe',
  password => 'example',
};

sub lookup { return bless $fake }

sub login { return $fake->{login} }
sub account { return $fake->{account} }
sub password { return $fake->{password} }
sub lpa { ($fake->login, $fake->password, $fake->account) }

1;
