use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Le

=abstract

Data-Object Number Function (Le) Class

=synopsis

  use Data::Object::Func::Number::Le;

  my $func = Data::Object::Func::Number::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Le is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Le';

ok 1 and done_testing;
