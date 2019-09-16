use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Delete

=abstract

Data-Object Hash Function (Delete) Class

=synopsis

  use Data::Object::Hash::Func::Delete;

  my $func = Data::Object::Hash::Func::Delete->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
arg2(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Delete is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Delete';

ok 1 and done_testing;
