use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash

=abstract

Data-Object Hash Class

=synopsis

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=description

This package provides routines for operating on Perl 5 hash references.

=cut

use_ok "Data::Object::Hash";

ok 1 and done_testing;
