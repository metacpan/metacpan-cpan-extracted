use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Undef::Base

=abstract

Data-Object Abstract Undef Class

=synopsis

  package My::Undef;

  use parent 'Data::Object::Undef::Base';

  my $undef = My::Undef->new(undef);

=inherits

Data::Object::Base

=description

This package provides routines for operating on Perl 5 undefined data.

=cut

use_ok "Data::Object::Undef::Base";

ok 1 and done_testing;
