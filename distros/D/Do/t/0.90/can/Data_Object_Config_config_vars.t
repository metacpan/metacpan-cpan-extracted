use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_vars

=usage

  my $plans = config_vars;

=description

The config_vars function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Vars>.

=signature

config_vars() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_vars";

my $config = Data::Object::Config::config_vars();

is_deeply $config, [
  ['use', 'Data::Object::Class'],
  ['use', 'Data::Object::ClassHas'],
  ['call', 'extends', 'Data::Object::Vars']
];

ok 1 and done_testing;
