use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Upto

=abstract

Data-Object Number Function (Upto) Class

=synopsis

  use Data::Object::Func::Number::Upto;

  my $func = Data::Object::Func::Number::Upto->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Upto is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Upto';

ok 1 and done_testing;
