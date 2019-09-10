use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_struct

=usage

  my $plans = config_struct;

=description

The config_struct function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Struct>.

=signature

config_struct() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_struct";

my $config = Data::Object::Config::config_struct();

is_deeply $config, [
  ['use', 'Data::Object::Class'],
  ['use', 'Data::Object::ClassHas'],
  ['call', 'extends', 'Data::Object::Struct']
];

ok 1 and done_testing;
