use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String::Base

=abstract

Data-Object Abstract String Class

=synopsis

  package My::String;

  use parent 'Data::Object::String::Base';

  my $string = My::String->new('abcedfghi');

=description

Data::Object::String::Base provides routines for operating on Perl 5 string
data.

=cut

use_ok "Data::Object::String::Base";

ok 1 and done_testing;
