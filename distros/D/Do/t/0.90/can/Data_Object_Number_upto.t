use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

upto

=usage

  # given 23

  $number->upto(25); # [23,24,25]

=description

The upto method returns an array reference containing integer increasing
values up to and including the limit. This method returns a
L<Data::Object::Array> object.

=signature

upto(Int $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->upto(13), [12,13];

ok 1 and done_testing;
