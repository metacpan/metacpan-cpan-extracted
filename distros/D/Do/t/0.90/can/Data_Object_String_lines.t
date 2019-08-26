use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lines

=usage

  # given "who am i?\nwhere am i?\nhow did I get here"

  $string->lines; # ['who am i?','where am i?','how did i get here']

=description

The lines method breaks the string into pieces, split on 1 or more newline
characters, and returns an array reference consisting of the pieces. This method
returns an array value.

=signature

lines() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new("hello\nworld");

is_deeply $data->lines(), ['hello', 'world'];

ok 1 and done_testing;
