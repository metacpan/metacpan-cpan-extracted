use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_data

=usage

  # given Foo::Bar;

  $object = data_data 'Foo::Bar';
  $object->isa('Data::Object::Data');

=description

The data_data function returns a L<Data::Object::Data> instance which parses
pod-ish data in files and packages.

=signature

data_data(Str $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_data';

ok 1 and done_testing;
