use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withstashable

=usage

  my $plans = config_withstashable;

=description

The config_withstashable function returns plans for configuring the package to
consume the L<Data::Object::Role::Stashable> role.

=signature

config_withstashable() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withstashable";

my $config = Data::Object::Config::config_withstashable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Stashable']
];

ok 1 and done_testing;
