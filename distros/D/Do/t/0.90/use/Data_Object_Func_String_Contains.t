use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Contains

=abstract

Data-Object String Function (Contains) Class

=synopsis

  use Data::Object::Func::String::Contains;

  my $func = Data::Object::Func::String::Contains->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Contains is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Contains';

ok 1 and done_testing;
