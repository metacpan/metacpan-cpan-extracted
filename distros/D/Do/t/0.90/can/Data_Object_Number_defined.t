use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given $number

  $number->defined; # 1

=description

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=signature

defined() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->defined(), 1;

ok 1 and done_testing;
