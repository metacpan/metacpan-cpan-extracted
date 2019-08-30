use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Code

=abstract

Data-Object Code Class

=synopsis

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { shift + 1 });

=description

This package provides routines for operating on Perl 5 code references. This
package inherits all behavior from L<Data::Object::Code::Base>.

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Code";

ok 1 and done_testing;
