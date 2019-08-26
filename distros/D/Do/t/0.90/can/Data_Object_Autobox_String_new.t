use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $string = Data::Object::Autobox::String->new('ehlo');

=description

Construct a new object.

=signature

new(Str $arg1) : StringObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::String;

can_ok "Data::Object::Autobox::String", "new";

ok 1 and done_testing;
