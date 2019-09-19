use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

keyraise

=usage

  keyraise($message, $context, $offset);

=description

The keyraise function is used internally by function keywords to L</raise>
exceptions from the persepective of the caller and not the keyword itself.

=signature

keyraise(Str $message, Any $context, Num $offset) : ()

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "keyraise";

ok 1 and done_testing;
