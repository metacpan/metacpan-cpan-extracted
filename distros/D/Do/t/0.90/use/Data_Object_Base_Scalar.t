use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Scalar

=abstract

Data-Object Abstract Scalar Class

=synopsis

  package My::Scalar;

  use parent 'Data::Object::Base::Scalar';

  my $scalar = My::Scalar->new(\*main);

=description

Data::Object::Base::Scalar provides routines for operating on Perl 5 scalar
objects.

=cut

use_ok "Data::Object::Base::Scalar";

ok 1 and done_testing;
