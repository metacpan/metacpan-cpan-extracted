use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Regexp::Func::Gt

=abstract

Data-Object Regexp Function (Gt) Class

=synopsis

  use Data::Object::Regexp::Func::Gt;

  my $func = Data::Object::Regexp::Func::Gt->new(@args);

  $func->execute;

=inherits

Data::Object::Regexp::Func

=attributes

arg1(RegexpLike, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Regexp::Func::Gt is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Regexp::Func::Gt';

ok 1 and done_testing;
