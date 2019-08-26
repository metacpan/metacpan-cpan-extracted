use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Reverse

=abstract

Data-Object String Function (Reverse) Class

=synopsis

  use Data::Object::Func::String::Reverse;

  my $func = Data::Object::Func::String::Reverse->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Reverse is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Reverse';

ok 1 and done_testing;
