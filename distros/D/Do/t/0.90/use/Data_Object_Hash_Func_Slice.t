use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Slice

=abstract

Data-Object Hash Function (Slice) Class

=synopsis

  use Data::Object::Hash::Func::Slice;

  my $func = Data::Object::Hash::Func::Slice->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[StringLike], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Slice is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Slice';

ok 1 and done_testing;
