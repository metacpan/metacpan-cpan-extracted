use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Regexp

=abstract

Data-Object Regexp Class

=synopsis

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

=description

This package provides routines for operating on Perl 5 regular expressions.
This package inherits all behavior from L<Data::Object::Regexp::Base>.

This package assumes all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Regexp";

ok 1 and done_testing;
