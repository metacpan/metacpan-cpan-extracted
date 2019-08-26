use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

array

=usage

  # given [1..4]

  my $object = Data::Object->array([1..4]);

=description

The C<array> constructor function returns a L<Data::Object::Array> object for
given argument.

=signature

array(ArrayRef $arg) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->array([1..4]);

isa_ok $object, 'Data::Object::Array';

ok 1 and done_testing;
