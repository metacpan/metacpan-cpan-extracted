use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Sin

=abstract

Data-Object Number Function (Sin) Class

=synopsis

  use Data::Object::Number::Func::Sin;

  my $func = Data::Object::Number::Func::Sin->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Sin is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Sin';

ok 1 and done_testing;
