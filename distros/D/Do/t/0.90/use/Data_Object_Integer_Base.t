use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Integer::Base

=abstract

Data-Object Abstract Integer Class

=synopsis

  package My::Integer;

  use parent 'Data::Object::Integer::Base';

  my $integer = My::Integer->new(9);

=description

Data::Object::Integer::Base provides routines for operating on Perl 5 integer
data. This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Integer::Base";

ok 1 and done_testing;
