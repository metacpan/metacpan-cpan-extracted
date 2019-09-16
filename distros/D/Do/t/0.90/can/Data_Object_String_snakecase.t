use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

snakecase

=usage

  # given 'hello world'

  $string->snakecase; # hello_world

=description

The snakecase method modifies the string such that it will no longer have any
non-alphanumeric characters and all words (groups of alphanumeric characters
separated by 1 or more non-alphanumeric characters) are joined by a single
underscore. This method returns a string value. Any leading or trailing
underscores are removed.

=signature

snakecase() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->snakecase(), 'hello_world';

ok 1 and done_testing;
