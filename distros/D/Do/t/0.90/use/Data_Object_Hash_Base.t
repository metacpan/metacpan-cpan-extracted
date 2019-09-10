use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash::Base

=abstract

Data-Object Abstract Hash Class

=synopsis

  package My::Hash;

  use parent 'Data::Object::Hash::Base';

  my $hash = My::Hash->new({1..4});

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides routines for operating on Perl 5 hash references. If no
argument is provided, this package is instantiated with a default value of
C<{}>.

=cut

use_ok "Data::Object::Hash::Base";

ok 1 and done_testing;
