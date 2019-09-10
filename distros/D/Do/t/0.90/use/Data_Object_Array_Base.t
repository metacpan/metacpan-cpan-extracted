use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Array::Base

=abstract

Data-Object Abstract Array Class

=synopsis

  use Data::Object::Array::Base;

  my $array = Data::Object::Array::Base->new([1..9]);

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 array references. If no
argument is provided, this package is instantiated with a default value of
C<[]>.

=cut

use_ok "Data::Object::Array::Base";

ok 1 and done_testing;
