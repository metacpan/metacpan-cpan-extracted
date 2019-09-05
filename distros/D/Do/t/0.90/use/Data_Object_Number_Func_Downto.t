use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Downto

=abstract

Data-Object Number Function (Downto) Class

=synopsis

  use Data::Object::Number::Func::Downto;

  my $func = Data::Object::Number::Func::Downto->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=description

Data::Object::Number::Func::Downto is a function object for
Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Downto';

ok 1 and done_testing;
