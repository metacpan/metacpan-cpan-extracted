use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Words

=abstract

Data-Object String Function (Words) Class

=synopsis

  use Data::Object::String::Func::Words;

  my $func = Data::Object::String::Func::Words->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Words is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Words';

ok 1 and done_testing;
