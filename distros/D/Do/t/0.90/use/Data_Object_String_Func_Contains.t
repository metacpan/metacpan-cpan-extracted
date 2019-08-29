use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Contains

=abstract

Data-Object String Function (Contains) Class

=synopsis

  use Data::Object::String::Func::Contains;

  my $func = Data::Object::String::Func::Contains->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Contains is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Contains';

ok 1 and done_testing;
