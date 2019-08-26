use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $number = Data::Object::Autobox::Number->new(1_000);

=description

Construct a new object.

=signature

new(Num $arg1) : NumberObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Number;

can_ok "Data::Object::Autobox::Number", "new";

ok 1 and done_testing;
