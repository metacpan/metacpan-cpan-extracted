use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

string

=usage

  # given 'hello'

  my $object = Data::Object->string('hello');

=description

The C<string> constructor function returns a L<Data::Object::String> object for given
argument.

=signature

string(Str $arg) : ScalarObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->string('hello');

isa_ok $object, 'Data::Object::String';

ok 1 and done_testing;
