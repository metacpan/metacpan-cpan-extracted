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

=description

This package provides routines for operating on Perl 5 regular expressions.

=cut

use_ok "Data::Object::Regexp::Base";

ok 1 and done_testing;
