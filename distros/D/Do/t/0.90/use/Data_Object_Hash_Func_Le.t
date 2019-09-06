use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Le

=abstract

Data-Object Hash Function (Le) Class

=synopsis

  use Data::Object::Hash::Func::Le;

  my $func = Data::Object::Hash::Func::Le->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
arg2(HashLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Le is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Le';

ok 1 and done_testing;
