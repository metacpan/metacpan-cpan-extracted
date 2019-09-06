use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Sort

=abstract

Data-Object Hash Function (Sort) Class

=synopsis

  use Data::Object::Hash::Func::Sort;

  my $func = Data::Object::Hash::Func::Sort->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Sort is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Sort';

ok 1 and done_testing;
