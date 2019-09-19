use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceDeep

=usage

  # given ...

  Data::Object::Utility::DeduceDeep(...);

=description

The C<DeduceDeep> function returns a data type object. If the data provided is
complex, this function traverses the data converting all nested data to
objects. Note: Blessed objects are not traversed.

=signature

DeduceDeep(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceDeep";

use Scalar::Util 'refaddr';

my $main   = bless {}, 'main';
my $object = Data::Object::Utility::DeduceDeep {1, 2, 3, {4, 5, 6, [-1, 99, $main]}};

is $object->{1}, 2;
is $object->{3}{4}, 5;
is $object->{3}{6}[0], -1;
is $object->{3}{6}[1], 99;
is $object->{3}{6}[2], $main;

isa_ok $object, 'Data::Object::Hash';
isa_ok $object->{1}, 'Data::Object::Number';
isa_ok $object->{3}, 'Data::Object::Hash';
isa_ok $object->{3}{4}, 'Data::Object::Number';
isa_ok $object->{3}{6}, 'Data::Object::Array';
isa_ok $object->{3}{6}[0], 'Data::Object::Number';
isa_ok $object->{3}{6}[1], 'Data::Object::Number';
isa_ok $object->{3}{6}[2], 'main';

ok 1 and done_testing;
