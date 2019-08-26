use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

any

=usage

  # given \*main

  my $object = Data::Object->any(\*main);

=description

The C<any> constructor function returns a L<Data::Object::Any> object for given
argument.

=signature

any(Any $arg) : AnyObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->any(\*main);

isa_ok $object, 'Data::Object::Any';

ok 1 and done_testing;
