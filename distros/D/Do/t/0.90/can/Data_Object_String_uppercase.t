use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

uppercase

=usage

  # given 'exciting'

  $string->uppercase; # EXCITING

=description

The uppercase method is an alias to the uc method. This method returns a
string object.

=signature

uppercase() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->uppercase(), 'HELLO WORLD';

ok 1 and done_testing;
