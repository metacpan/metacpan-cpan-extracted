use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Search

=abstract

Data-Object Search Class

=synopsis

  use Data::Object::Search;

  my $result = Data::Object::Search->new([
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

=libraries

Data::Object::Library

=description

This package provides routines for introspecting the results of a regexp search
operation.

=cut

use_ok "Data::Object::Search";

ok 1 and done_testing;
