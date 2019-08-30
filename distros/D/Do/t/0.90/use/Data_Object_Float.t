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
This package inherits all behavior from L<Data::Object::Float::Base>.

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Float";

ok 1 and done_testing;
