use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $array = Data::Object::Autobox::Array->new([]);

=description

Construct a new object.

=signature

new(ArrayRef $arg1) : ArrayObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Array;

can_ok "Data::Object::Autobox::Array", "new";

ok 1 and done_testing;
