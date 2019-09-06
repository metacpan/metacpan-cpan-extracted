use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Get

=abstract

Data-Object Hash Function (Get) Class

=synopsis

  use Data::Object::Hash::Func::Get;

  my $func = Data::Object::Hash::Func::Get->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
arg2(Str, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Get is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Get';

ok 1 and done_testing;
