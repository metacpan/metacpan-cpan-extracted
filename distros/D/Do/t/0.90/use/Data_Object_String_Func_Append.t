use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Append

=abstract

Data-Object String Function (Append) Class

=synopsis

  use Data::Object::String::Func::Append;

  my $func = Data::Object::String::Func::Append->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[Str], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Append is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Append';

ok 1 and done_testing;
