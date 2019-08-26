use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $hash = Data::Object::Autobox::Hash->new({1..4});

=description

Construct a new object.

=signature

new(HashRef $arg1) : HashObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Hash;

can_ok "Data::Object::Autobox::Hash", "new";

ok 1 and done_testing;
