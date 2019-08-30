use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Array

=abstract

Data-Object Array Class

=synopsis

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=description

This package provides routines for operating on Perl 5 array references. This
package inherits all behavior from L<Data::Object::Array::Base>.

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Array";

ok 1 and done_testing;
