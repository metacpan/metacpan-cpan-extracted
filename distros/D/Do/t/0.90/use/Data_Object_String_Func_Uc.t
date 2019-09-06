use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Uc

=abstract

Data-Object String Function (Uc) Class

=synopsis

  use Data::Object::String::Func::Uc;

  my $func = Data::Object::String::Func::Uc->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::String::Func::Uc is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Uc';

ok 1 and done_testing;
