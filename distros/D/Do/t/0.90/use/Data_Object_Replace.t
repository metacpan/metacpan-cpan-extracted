use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Replace

=abstract

Data-Object Replace Class

=synopsis

  use Data::Object::Replace;

  my $result = Data::Object::Replace->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=inherits

Data::Object::Array

=description

This package provides routines for introspecting the results of a regexp
replace operation.

=cut

use_ok "Data::Object::Replace";

ok 1 and done_testing;
