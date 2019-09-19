use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DetractDeep

=usage

  # given ...

  Data::Object::Utility::DetractDeep(...);

=description

The C<DetractDeep> function returns a value of native type. If the data
provided is complex, this function traverses the data converting all nested
data type objects into native values using the objects underlying reference.
Note: Blessed objects are not traversed.

=signature

DetractDeep(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DetractDeep";

use Scalar::Util 'refaddr';

my $main   = bless {}, 'main';
my $object = Data::Object::Utility::DeduceDeep {1, 2, 3, {4, 5, 6, [-1, 99, $main], 7, "abcd"}};

$object = Data::Object::Utility::DetractDeep($object);
is_deeply $object, {1, 2, 3, {4, 5, 6, [-1, 99, $main], 7, "abcd"}};

is $object->{1}, 2;
is $object->{3}{4}, 5;
is $object->{3}{6}[0], -1;
is $object->{3}{6}[1], 99;
is $object->{3}{6}[2], $main;
is $object->{3}{7}, "abcd";

is ref($object), 'HASH';
is ref($object->{1}), '';
is ref($object->{3}), 'HASH';
is ref($object->{3}{4}), '';
is ref($object->{3}{6}), 'ARRAY';
is ref($object->{3}{6}[0]), '';
is ref($object->{3}{6}[1]), '';
is ref($object->{3}{6}[2]), 'main';
is ref($object->{3}{7}), '';

ok 1 and done_testing;
