use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Rcurry

=abstract

Data-Object Code Function (Rcurry) Class

=synopsis

  use Data::Object::Func::Code::Rcurry;

  my $func = Data::Object::Func::Code::Rcurry->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Rcurry is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Rcurry';

ok 1 and done_testing;
