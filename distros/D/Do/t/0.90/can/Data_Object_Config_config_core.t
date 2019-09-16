use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_core

=usage

  my $plans = config_core;

=description

The config_core function returns plans for configuring the package to have the
L<Data::Object> framework default configuration.

=signature

config_core() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Config;

can_ok "Data::Object::Config", "config_core";

my $config = Data::Object::Config::config_core();

is_deeply $config, [];

ok 1 and done_testing;
