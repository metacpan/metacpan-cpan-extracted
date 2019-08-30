use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash

=abstract

Data-Object Hash Class

=synopsis

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=description

This package provides routines for operating on Perl 5 hash references. This
package inherits all behavior from L<Data::Object::Hash::Base>.

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Hash";

ok 1 and done_testing;
