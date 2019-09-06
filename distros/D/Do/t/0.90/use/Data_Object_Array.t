use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Array

=abstract

Data-Object Array Class

=synopsis

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=inherits

Data::Object::Array::Base

=integrates

Data::Object::Role::Detract
Data::Object::Role::Dumper
Data::Object::Role::Functable
Data::Object::Role::Output
Data::Object::Role::Throwable

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 array references.

=cut

use_ok "Data::Object::Array";

ok 1 and done_testing;
