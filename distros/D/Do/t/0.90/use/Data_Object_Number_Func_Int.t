use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Int

=abstract

Data-Object Number Function (Int) Class

=synopsis

  use Data::Object::Number::Func::Int;

  my $func = Data::Object::Number::Func::Int->new(@args);

  $func->execute;

=description

Data::Object::Number::Func::Int is a function object for Data::Object::Number.
This package inherits all behavior from L<Data::Object::Number::Func>.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Int';

ok 1 and done_testing;
