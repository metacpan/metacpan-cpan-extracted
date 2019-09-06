use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Length

=abstract

Data-Object String Function (Length) Class

=synopsis

  use Data::Object::String::Func::Length;

  my $func = Data::Object::String::Func::Length->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Length is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Length';

ok 1 and done_testing;
