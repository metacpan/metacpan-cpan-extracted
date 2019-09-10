use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String::Base

=abstract

Data-Object Abstract String Class

=synopsis

  package My::String;

  use parent 'Data::Object::String::Base';

  my $string = My::String->new('abcedfghi');

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 string data. If no
argument is provided, this package is instantiated with a default value of
C<''>.

=cut

use_ok "Data::Object::String::Base";

ok 1 and done_testing;
