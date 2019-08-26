use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Float

=abstract

Data-Object Float Class

=synopsis

  use Data::Object::Float;

  my $float = Data::Object::Float->new(9.9999);

=description

This package provides routines for operating on Perl 5 floating-point data.

=cut

use_ok "Data::Object::Float";

ok 1 and done_testing;
