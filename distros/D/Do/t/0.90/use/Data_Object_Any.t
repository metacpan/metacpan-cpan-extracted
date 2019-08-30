use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Any

=abstract

Data-Object Any Class

=synopsis

  use Data::Object::Any;

  my $any = Data::Object::Any->new(\*main);

=description

Data::Object::Any provides routines for operating on any Perl 5 data type. This
package inherits all behavior from L<Data::Object::Any::Base>.

+=head1 ROLES

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Any";

ok 1 and done_testing;
