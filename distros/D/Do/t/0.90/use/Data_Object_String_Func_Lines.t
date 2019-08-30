use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Lines

=abstract

Data-Object String Function (Lines) Class

=synopsis

  use Data::Object::String::Func::Lines;

  my $func = Data::Object::String::Func::Lines->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Lines is a function object for
Data::Object::String. This package inherits all behavior from
L<Data::Object::String::Func>.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Lines';

ok 1 and done_testing;
