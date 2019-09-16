use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withimmutable

=usage

  my $plans = config_withimmutable;

=description

The config_withimmutable function returns plans for configuring the package to
consume the L<Data::Object::Role::Immutable> role.

=signature

config_withimmutable() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withimmutable";

my $config = Data::Object::Config::config_withimmutable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Immutable']
];

ok 1 and done_testing;
