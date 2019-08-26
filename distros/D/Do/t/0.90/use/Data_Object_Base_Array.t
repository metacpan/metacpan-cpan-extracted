use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Array

=abstract

Data-Object Abstract Array Class

=synopsis

  use Data::Object::Base::Array;

  my $array = Data::Object::Base::Array->new([1..9]);

=description

Data::Object::Base::Array provides routines for operating on Perl 5 array
references.

=cut

use_ok "Data::Object::Base::Array";

ok 1 and done_testing;
