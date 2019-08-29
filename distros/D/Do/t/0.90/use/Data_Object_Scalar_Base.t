use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Scalar::Base

=abstract

Data-Object Abstract Scalar Class

=synopsis

  package My::Scalar;

  use parent 'Data::Object::Scalar::Base';

  my $scalar = My::Scalar->new(\*main);

=description

Data::Object::Scalar::Base provides routines for operating on Perl 5 scalar
objects.

=cut

use_ok "Data::Object::Scalar::Base";

ok 1 and done_testing;
