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

This package provides routines for operating on Perl 5 string data.

=cut

use_ok "Data::Object::String";

ok 1 and done_testing;
