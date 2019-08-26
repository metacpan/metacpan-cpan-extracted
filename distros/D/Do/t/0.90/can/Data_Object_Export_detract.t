use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

detract

=usage

  # given bless({1..4}, 'Data::Object::Hash');

  $object = detract $object; # {1..4}

=description

The detract function returns a value of native type, based upon the underlying
reference of the data type object provided.

=signature

detract(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'detract';

ok 1 and done_testing;
