use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Values

=abstract

Data-Object Hash Function (Values) Class

=synopsis

  use Data::Object::Hash::Func::Values;

  my $func = Data::Object::Hash::Func::Values->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[StringLike], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Values is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Values';

ok 1 and done_testing;
