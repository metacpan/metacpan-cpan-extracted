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

=description

Data::Object::Number::Base provides routines for operating on Perl 5 numeric
data. This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Number::Base";

ok 1 and done_testing;
