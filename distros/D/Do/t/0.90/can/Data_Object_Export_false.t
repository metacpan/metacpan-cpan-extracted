use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

false

=usage

  my $false = false;

=description

The false function returns a falsy boolean object.

=signature

false() : BooleanObject

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "false";

ok 1 and done_testing;
