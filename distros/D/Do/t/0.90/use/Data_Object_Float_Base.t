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

=description

Data::Object::Float::Base provides routines for operating on Perl 5
floating-point data.

=cut

use_ok "Data::Object::Float::Base";

ok 1 and done_testing;
