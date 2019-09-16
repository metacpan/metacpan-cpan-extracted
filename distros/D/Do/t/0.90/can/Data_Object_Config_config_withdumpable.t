use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withdumpable

=usage

  my $plans = config_withdumpable;

=description

The config_withdumpable function returns plans for configuring the package to
consume the L<Data::Object::Role::Dumbable> role.

=signature

config_withdumpable() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withdumpable";

my $config = Data::Object::Config::config_withdumpable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Dumpable']
];

ok 1 and done_testing;
