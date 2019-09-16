use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Number

=abstract

Data-Object Number Class

=synopsis

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=inherits

Data::Object::Number::Base

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Functable
Data::Object::Role::Throwable

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 numeric data.

=cut

use_ok "Data::Object::Number";

ok 1 and done_testing;
