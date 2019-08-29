use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Hex

=abstract

Data-Object Number Function (Hex) Class

=synopsis

  use Data::Object::Number::Func::Hex;

  my $func = Data::Object::Number::Func::Hex->new(@args);

  $func->execute;

=description

Data::Object::Number::Func::Hex is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Hex';

ok 1 and done_testing;
