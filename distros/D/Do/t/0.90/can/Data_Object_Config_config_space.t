use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_space

=usage

  my $plans = config_space;

=description

The config_space function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Space>.

=signature

config_space() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_space";

my $config = Data::Object::Config::config_space();

is_deeply $config, [
  ['use', 'Data::Object::Class'],
  ['use', 'Data::Object::ClassHas'],
  ['call', 'extends', 'Data::Object::Space']
];

ok 1 and done_testing;
