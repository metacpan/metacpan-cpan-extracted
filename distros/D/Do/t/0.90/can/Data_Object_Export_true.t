use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

true

=usage

  my $true = true;

=description

The true function returns a truthy boolean object.

=signature

true() : BooleanObject

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "true";

ok 1 and done_testing;
