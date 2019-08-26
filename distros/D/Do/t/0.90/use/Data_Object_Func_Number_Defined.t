use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Defined

=abstract

Data-Object Number Function (Defined) Class

=synopsis

  use Data::Object::Func::Number::Defined;

  my $func = Data::Object::Func::Number::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Defined is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Defined';

ok 1 and done_testing;
