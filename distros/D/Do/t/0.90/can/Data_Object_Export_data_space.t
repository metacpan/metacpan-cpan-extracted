use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_space

=usage

  # given Foo::Bar;

  $object = data_space 'Foo::Bar';
  $object->isa('Data::Object::Space');

=description

The data_space function returns a L<Data::Object::Space> instance which
provides methods for operating on package and namespaces.

=signature

data_space(Str $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_space';

ok 1 and done_testing;
