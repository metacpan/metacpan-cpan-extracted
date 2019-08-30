use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String

=abstract

Data-Object String Class

=synopsis

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=description

This package provides routines for operating on Perl 5 string data. This
package inherits all behavior from L<Data::Object::String::Base>.

+=head1 ROLES

This package inherits all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::String";

ok 1 and done_testing;
