use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_opts

=usage

  my $plans = config_opts;

=description

The config_opts function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Opts>.

=signature

config_opts() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_opts";

my $config = Data::Object::Config::config_opts();

is_deeply $config, [
  ['use', 'Data::Object::Class'],
  ['use', 'Data::Object::ClassHas'],
  ['call', 'extends', 'Data::Object::Opts']
];

ok 1 and done_testing;
