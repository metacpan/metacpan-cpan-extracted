use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 'String'

  my $space = Data::Object->new('String');

  my $string = $space->build('hello world');

=description

The new method expects a string representing a class name under the
Data::Object namespace and returns a L<Data::Object::Space> object.

=signature

new(Str $arg) : SpaceObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object;

$object = Data::Object->new('String');

isa_ok $object, 'Data::Object::Space';

my $string_object = $object->build('hello world');

isa_ok $string_object, 'Data::Object::String';

ok 1 and done_testing;
