use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $integer = Data::Object::Autobox::Integer->new(1_000);

=description

Construct a new object.

=signature

new(Int $arg1) : IntegerObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Integer;

can_ok "Data::Object::Autobox::Integer", "new";

ok 1 and done_testing;
