use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Number::Base

=abstract

Data-Object Abstract Number Class

=synopsis

  package My::Number;

  use parent 'Data::Object::Number::Base';

  my $number = My::Number->new(1_000_000);

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 numeric data. If no
argument is provided, this package is instantiated with a default value of
C<0>.

=cut

use_ok "Data::Object::Number::Base";

ok 1 and done_testing;
