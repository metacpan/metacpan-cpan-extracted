use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

titlecase

=usage

  # given 'mr. john doe'

  $string->titlecase; # Mr. John Doe

=description

The titlecase method returns the string capitalizing the first character of
each word (group of alphanumeric characters separated by 1 or more whitespaces).
Note, this method modifies the string. This method returns a
string object.

=signature

titlecase() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->titlecase(), 'Hello World';

ok 1 and done_testing;
