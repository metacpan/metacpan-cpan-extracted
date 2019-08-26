use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

scalar

=usage

  # given \*main

  my $object = Data::Object->scalar(\*main);

=description

The C<scalar> constructor function returns a L<Data::Object::Scalar> object for given
argument.

=signature

scalar(Any $arg) : ScalarObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->scalar(\*main);

isa_ok $object, 'Data::Object::Scalar';

ok 1 and done_testing;
