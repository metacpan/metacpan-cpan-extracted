use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Log

=abstract

Data-Object Number Function (Log) Class

=synopsis

  use Data::Object::Number::Func::Log;

  my $func = Data::Object::Number::Func::Log->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Log is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Log';

ok 1 and done_testing;
