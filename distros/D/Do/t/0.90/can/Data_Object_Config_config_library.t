use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_library

=usage

  my $plans = config_library;

=description

The config_library function returns plans for configuring the package to be a
L<Type::Library> which extends L<Data::Object::Library> with L<Type::Utils>
configured.

=signature

config_library() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_library';

my $config = Data::Object::Config::config_library();

is_deeply $config->[0], ['use', 'Type::Library', '-base'];
is_deeply $config->[1], ['use', 'Type::Utils', '-all'];
is_deeply $config->[2], ['let', 'BEGIN { extends("Data::Object::Library"); }'];

ok 1 and done_testing;
