use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash::Base

=abstract

Data-Object Abstract Hash Class

=synopsis

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

=description

Data::Object::Hash::Base provides routines for operating on Perl 5 hash
references. This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Hash::Base";

ok 1 and done_testing;
