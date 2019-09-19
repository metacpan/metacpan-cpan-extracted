use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

is_true

=usage

  my $bool;

  $bool = is_true; # true
  $bool = is_true 1; # true
  $bool = is_true {}; # true
  $bool = is_true bless {}; # true
  $bool = is_true 0; # false
  $bool = is_true ''; # false
  $bool = is_true undef; # false

=description

The is_true function with no argument returns a truthy boolean object,
otherwise, returns a boolean object based on the value of the argument
provided.

=signature

is_true(Any $arg) : BooleanObject

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "is_true";

ok 1 and done_testing;
