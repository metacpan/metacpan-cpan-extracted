use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_deep

=usage

  # given {1,2,3,{4,5,6,[-1]}}

  $deep = deduce_deep {1,2,3,{4,5,6,[-1]}};

  # Data::Object::Hash {
  #   1 => Data::Object::Number ( 2 ),
  #   3 => Data::Object::Hash {
  #      4 => Data::Object::Number ( 5 ),
  #      6 => Data::Object::Array [ Data::Object::Integer ( -1 ) ],
  #   },
  # }

=description

The deduce_deep function returns a data type object. If the data provided is
complex, this function traverses the data converting all nested data to objects.
Note: Blessed objects are not traversed.

=signature

deduce_deep(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_deep';

ok 1 and done_testing;
