use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Hex

=abstract

Data-Object String Function (Hex) Class

=synopsis

  use Data::Object::String::Func::Hex;

  my $func = Data::Object::String::Func::Hex->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Hex is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Hex';

ok 1 and done_testing;
