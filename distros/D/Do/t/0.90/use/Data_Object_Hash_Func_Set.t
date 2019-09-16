use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Set

=abstract

Data-Object Hash Function (Set) Class

=synopsis

  use Data::Object::Hash::Func::Set;

  my $func = Data::Object::Hash::Func::Set->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
arg2(StringLike, req, ro)
args(ArrayRef[Any], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Set is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Set';

ok 1 and done_testing;
