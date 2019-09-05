use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Lt

=abstract

Data-Object Number Function (Lt) Class

=synopsis

  use Data::Object::Number::Func::Lt;

  my $func = Data::Object::Number::Func::Lt->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Lt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Lt';

ok 1 and done_testing;
