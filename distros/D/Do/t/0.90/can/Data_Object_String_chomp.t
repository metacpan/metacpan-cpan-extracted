use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

chomp

=usage

  # given "name, age, dob, email\n"

  $string->chomp; # name, age, dob, email

=description

The chomp method is a safer version of the chop method, it's used to remove the
newline (or the current value of $/) from the end of the string. Note, this
method modifies and returns the string. This method returns a
string object.

=signature

chomp() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new("hello world\n");

is_deeply $data->chomp(), 'hello world';

ok 1 and done_testing;
