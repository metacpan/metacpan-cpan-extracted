use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Regexp::Base

=abstract

Data-Object Abstract Regexp Class

=synopsis

  package My::Regexp;

  use parent 'Data::Object::Regexp::Base';

  my $re = My::Regexp->new(qr(\w+));

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 regular expressions. If no
argument is provided, this package is instantiated with a default value of
C<qr/.*/>.

=cut

use_ok "Data::Object::Regexp::Base";

ok 1 and done_testing;
