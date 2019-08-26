use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_defined

=usage

  # given $data

  deduce_defined($data);

=description

The deduce_defined function returns truthy if the argument is defined.

=signature

deduce_defined(Any $arg1) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_defined';

ok 1 and done_testing;
