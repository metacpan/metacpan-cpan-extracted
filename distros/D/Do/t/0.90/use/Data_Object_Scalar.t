use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Scalar

=abstract

Data-Object Scalar Class

=synopsis

  use Data::Object::Scalar;

  my $scalar = Data::Object::Scalar->new(\*main);

=description

This package provides routines for operating on Perl 5 scalar objects. This
package inherits all behavior from L<Data::Object::Scalar::Base>.

+=head1 ROLES

This package inherits all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Scalar";

ok 1 and done_testing;
