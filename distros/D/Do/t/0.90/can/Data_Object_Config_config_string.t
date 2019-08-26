use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_string

=usage

  my $plans = config_string;

=description

The config_string function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::String>.

=signature

config_string() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_string';

my $config = Data::Object::Config::config_string();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::String'];

ok 1 and done_testing;
