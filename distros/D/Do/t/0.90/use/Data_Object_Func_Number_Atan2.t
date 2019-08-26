use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Atan2

=abstract

Data-Object Number Function (Atan2) Class

=synopsis

  use Data::Object::Func::Number::Atan2;

  my $func = Data::Object::Func::Number::Atan2->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Atan2 is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Atan2';

ok 1 and done_testing;
