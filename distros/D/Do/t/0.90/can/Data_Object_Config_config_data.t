use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_data

=usage

  my $plans = config_data;

=description

The config_data function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Data>.

=signature

config_data() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_data";

my $config = Data::Object::Config::config_data();

is_deeply $config, [
  ['use', 'Data::Object::Class'],
  ['use', 'Data::Object::ClassHas'],
  ['call', 'extends', 'Data::Object::Data']
];

ok 1 and done_testing;
