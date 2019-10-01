use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_withtryable

=usage

  my $plans = config_withtryable;

=description

The config_withtryable function returns plans for configuring the package to
consume the L<Data::Object::Role::Tryable> role.

=signature

config_withtryable() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_withtryable";

my $config = Data::Object::Config::config_withtryable();

is_deeply $config, [
  ['call', 'with', 'Data::Object::Role::Tryable']
];

ok 1 and done_testing;
