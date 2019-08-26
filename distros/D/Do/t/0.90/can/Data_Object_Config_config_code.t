use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_code

=usage

  my $plans = config_code;

=description

The config_code function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Code>.

=signature

config_code() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_code';

my $config = Data::Object::Config::config_code();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Code'];

ok 1 and done_testing;
