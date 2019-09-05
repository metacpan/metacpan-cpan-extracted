use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Le

=abstract

Data-Object Number Function (Le) Class

=synopsis

  use Data::Object::Number::Func::Le;

  my $func = Data::Object::Number::Func::Le->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Le is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Le';

ok 1 and done_testing;
