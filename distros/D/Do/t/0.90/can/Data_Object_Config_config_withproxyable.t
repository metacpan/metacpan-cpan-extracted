use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withproxyable

=usage

  my $plans = config_withproxyable;

=description

The config_withproxyable function returns plans for configuring the package to
consume the L<Data::Object::Role::Proxyable> role.

=signature

config_withproxyable() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withproxyable";

my $config = Data::Object::Config::config_withproxyable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Proxyable']
];

ok 1 and done_testing;
