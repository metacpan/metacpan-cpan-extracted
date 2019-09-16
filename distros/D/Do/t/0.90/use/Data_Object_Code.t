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

=inherits

Data::Object::Code::Base

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Functable
Data::Object::Role::Throwable

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 code references.

=cut

use_ok "Data::Object::Code";

ok 1 and done_testing;
