use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Float::Base

=abstract

Data-Object Abstract Float Class

=synopsis

  package My::Float;

  use parent 'Data::Object::Float::Base';

  my $float = My::Float->new(9.9999);

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 floating-point data. If
no argument is provided, this package is instantiated with a default value of
C<0.00>.

=cut

use_ok "Data::Object::Float::Base";

ok 1 and done_testing;
