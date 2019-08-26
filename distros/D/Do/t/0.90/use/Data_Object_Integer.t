use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Integer

=abstract

Data-Object Integer Class

=synopsis

  use Data::Object::Integer;

  my $integer = Data::Object::Integer->new(9);

=description

This package provides routines for operating on Perl 5 integer data.

=cut

use_ok "Data::Object::Integer";

ok 1 and done_testing;
