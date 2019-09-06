use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Scalar

=abstract

Data-Object Scalar Class

=synopsis

  use Data::Object::Scalar;

  my $scalar = Data::Object::Scalar->new(\*main);

=inherits

Data::Object::Scalar::Base

=integrates

Data::Object::Role::Detract
Data::Object::Role::Dumper
Data::Object::Role::Functable
Data::Object::Role::Output
Data::Object::Role::Throwable

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 scalar objects.

=cut

use_ok "Data::Object::Scalar";

ok 1 and done_testing;
