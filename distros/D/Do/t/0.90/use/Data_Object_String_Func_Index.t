use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Index

=abstract

Data-Object String Function (Index) Class

=synopsis

  use Data::Object::String::Func::Index;

  my $func = Data::Object::String::Func::Index->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(StringLike, req, ro)
arg2(StringLike, req, ro)
arg3(NumberLike, opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Index is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Index';

ok 1 and done_testing;
