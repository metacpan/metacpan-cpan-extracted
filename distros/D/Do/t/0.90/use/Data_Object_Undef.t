use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Undef

=abstract

Data-Object Undef Class

=synopsis

  use Data::Object::Undef;

  my $undef = Data::Object::Undef->new;

=description

This package provides routines for operating on Perl 5 undefined data.

=cut

use_ok "Data::Object::Undef";

ok 1 and done_testing;
