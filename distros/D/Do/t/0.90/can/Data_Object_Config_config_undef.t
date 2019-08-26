use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_undef

=usage

  my $plans = config_undef;

=description

The config_undef function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Undef>.

=signature

config_undef() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_undef';

my $config = Data::Object::Config::config_undef();

is_deeply $config->[0], ['use', 'Role::Tiny::With'];
is_deeply $config->[1], ['use', 'parent', 'Data::Object::Undef'];

ok 1 and done_testing;
