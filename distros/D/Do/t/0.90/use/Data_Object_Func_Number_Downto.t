use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Downto

=abstract

Data-Object Number Function (Downto) Class

=synopsis

  use Data::Object::Func::Number::Downto;

  my $func = Data::Object::Func::Number::Downto->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Downto is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Downto';

ok 1 and done_testing;
