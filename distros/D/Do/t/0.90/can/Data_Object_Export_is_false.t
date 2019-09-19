use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

is_false

=usage

  my $bool;

  $bool = is_false; # false
  $bool = is_false 1; # false
  $bool = is_false {}; # false
  $bool = is_false bless {}; # false
  $bool = is_false 0; # true
  $bool = is_false ''; # true
  $bool = is_false undef; # true

=description

The is_false function with no argument returns a falsy boolean object,
otherwise, returns a boolean object based on the value of the argument
provided.

=signature

is_false(Any $arg) : BooleanObject

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "is_false";

ok 1 and done_testing;
