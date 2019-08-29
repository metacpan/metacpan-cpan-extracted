use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Utility

=abstract

Data-Object Utility Functions

=synopsis

  use Data::Object::Utility;

  my $array = Data::Object::Utility::Deduce []; # Data::Object::Array
  my $value = Data::Object::Utility::Detract $array; # [,...]

=description

This package provides a suite of utility functions designed to be used
internally across core packages.

=cut

use_ok 'Data::Object::Utility';

ok 1 and done_testing;
