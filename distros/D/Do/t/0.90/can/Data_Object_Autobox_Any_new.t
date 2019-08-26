use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $any = Data::Object::Autobox::Any->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : AnyObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Any;

can_ok "Data::Object::Autobox::Any", "new";

ok 1 and done_testing;
