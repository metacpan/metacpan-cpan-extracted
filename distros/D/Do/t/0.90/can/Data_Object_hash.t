use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hash

=usage

  # given {1..4}

  my $object = Data::Object->hash({1..4});

=description

The C<hash> constructor function returns a L<Data::Object::Hash> object for given
argument.

=signature

hash(HashRef $arg) : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->hash({1..4});

isa_ok $object, 'Data::Object::Hash';

ok 1 and done_testing;
