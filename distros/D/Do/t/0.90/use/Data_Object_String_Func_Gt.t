use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Gt

=abstract

Data-Object String Function (Gt) Class

=synopsis

  use Data::Object::String::Func::Gt;

  my $func = Data::Object::String::Func::Gt->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(StringLike, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Gt is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Gt';

ok 1 and done_testing;
