use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Undef

=abstract

Data-Object Undef Class

=synopsis

  use Data::Object::Undef;

  my $undef = Data::Object::Undef->new;

=description

This package provides routines for operating on Perl 5 undefined data. This
package inherits all behavior from L<Data::Object::Undef::Base>.

+=head1 ROLES

This package inherits all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Undef";

ok 1 and done_testing;
