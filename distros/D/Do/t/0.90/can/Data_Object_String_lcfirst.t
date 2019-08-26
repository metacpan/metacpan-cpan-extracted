use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lcfirst

=usage

  # given 'EXCITING'

  $string->lcfirst; # eXCITING

=description

The lcfirst method returns a the string with the first character lowercased.
This method returns a string value.

=signature

lc() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('Hello World');

is_deeply $data->lcfirst(), 'hello World';

ok 1 and done_testing;
