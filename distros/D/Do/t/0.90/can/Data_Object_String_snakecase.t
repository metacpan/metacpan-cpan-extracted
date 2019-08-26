use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

snakecase

=usage

  # given 'hello world'

  $string->snakecase; # helloWorld

=description

The snakecase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. The only
difference between this method and the camelcase method is that this method
ensures that the first character will always be lowercased. Note, this method
modifies the string. This method returns a string value.

=signature

snakecase() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->snakecase(), 'helloWorld';

ok 1 and done_testing;
