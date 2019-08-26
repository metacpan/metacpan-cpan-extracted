use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_number

=usage

  my $plans = config_number;

=description

The config_number function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Number>.

=signature

config_number() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_number';

my $config = Data::Object::Config::config_number();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Number'];

ok 1 and done_testing;
