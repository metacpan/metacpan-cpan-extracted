use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Invert

=abstract

Data-Object Hash Function (Invert) Class

=synopsis

  use Data::Object::Hash::Func::Invert;

  my $func = Data::Object::Hash::Func::Invert->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Invert is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Invert';

ok 1 and done_testing;
