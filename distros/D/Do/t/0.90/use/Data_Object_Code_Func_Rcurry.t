use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Rcurry

=abstract

Data-Object Code Function (Rcurry) Class

=synopsis

  use Data::Object::Code::Func::Rcurry;

  my $func = Data::Object::Code::Func::Rcurry->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(CodeLike, req, ro)
args(ArrayRef[Any], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Rcurry is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Rcurry';

ok 1 and done_testing;
