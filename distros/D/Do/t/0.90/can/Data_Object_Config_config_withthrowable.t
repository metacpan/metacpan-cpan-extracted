use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withthrowable

=usage

  my $plans = config_withthrowable;

=description

The config_withthrowable function returns plans for configuring the package to
consume the L<Data::Object::Role::Throwable> role.

=signature

config_withthrowable() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withthrowable";

my $config = Data::Object::Config::config_withthrowable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Throwable']
];

ok 1 and done_testing;
