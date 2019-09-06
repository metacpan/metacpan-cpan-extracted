use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Le

=abstract

Data-Object Float Function (Le) Class

=synopsis

  use Data::Object::Float::Func::Le;

  my $func = Data::Object::Float::Func::Le->new(@args);

  $func->execute;

=inherits

Data::Object::Float::Func

=attributes

arg1(Object, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Float::Func::Le is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Le';

ok 1 and done_testing;
