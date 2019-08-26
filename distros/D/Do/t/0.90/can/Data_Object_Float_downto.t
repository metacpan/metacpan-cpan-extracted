use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

downto

=usage

  # given 1.23

  $float->downto(0); # [1,0]

=description

The downto method returns an array reference containing integer decreasing
values down to and including the limit. This method returns a
L<Data::Object::Array> object.

=signature

downto(Int $arg1) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Float';

my $data = Data::Object::Float->new(1.23);

is_deeply $data->downto(0), [1,0];

ok 1 and done_testing;
