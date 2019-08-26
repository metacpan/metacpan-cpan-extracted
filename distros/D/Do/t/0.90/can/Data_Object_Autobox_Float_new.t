use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $float = Data::Object::Autobox::Float->new(1.23);

=description

Construct a new object.

=signature

new(Float $arg1) : FloatObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Float;

can_ok "Data::Object::Autobox::Float", "new";

ok 1 and done_testing;
