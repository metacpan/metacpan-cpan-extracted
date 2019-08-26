use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $undef = Data::Object::Autobox::Undef->new;

=description

Construct a new object.

=signature

new(Maybe[Undef] $arg1) : UndefObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Undef;

can_ok "Data::Object::Autobox::Undef", "new";

ok 1 and done_testing;
