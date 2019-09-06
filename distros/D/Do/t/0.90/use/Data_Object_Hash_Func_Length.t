use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Length

=abstract

Data-Object Hash Function (Length) Class

=synopsis

  use Data::Object::Hash::Func::Length;

  my $func = Data::Object::Hash::Func::Length->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::Length is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Length';

ok 1 and done_testing;
