use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Hex

=abstract

Data-Object Number Function (Hex) Class

=synopsis

  use Data::Object::Func::Number::Hex;

  my $func = Data::Object::Func::Number::Hex->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Hex is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Hex';

ok 1 and done_testing;
