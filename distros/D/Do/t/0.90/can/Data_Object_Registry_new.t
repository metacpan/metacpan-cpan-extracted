use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $registry = Data::Object::Registry->new;

=description

Construct a new object.

=signature

new() : Object

=type

method

=cut

# TESTING

use Data::Object::Registry;

can_ok "Data::Object::Registry", "new";

ok 1 and done_testing;
