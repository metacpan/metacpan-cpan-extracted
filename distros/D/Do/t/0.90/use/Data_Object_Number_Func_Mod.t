use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Mod

=abstract

Data-Object Number Function (Mod) Class

=synopsis

  use Data::Object::Number::Func::Mod;

  my $func = Data::Object::Number::Func::Mod->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(Object, req, ro)
arg2(StringLike, opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Mod is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Mod';

ok 1 and done_testing;
