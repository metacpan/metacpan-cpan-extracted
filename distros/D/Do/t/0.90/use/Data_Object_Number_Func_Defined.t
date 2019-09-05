use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Defined

=abstract

Data-Object Number Function (Defined) Class

=synopsis

  use Data::Object::Number::Func::Defined;

  my $func = Data::Object::Number::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Defined is a function object for
Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Defined';

ok 1 and done_testing;
