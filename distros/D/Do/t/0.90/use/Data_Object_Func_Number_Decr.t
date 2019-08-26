use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Number::Decr

=abstract

Data-Object Number Function (Decr) Class

=synopsis

  use Data::Object::Func::Number::Decr;

  my $func = Data::Object::Func::Number::Decr->new(@args);

  $func->execute;

=description

Data::Object::Func::Number::Decr is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Func::Number::Decr';

ok 1 and done_testing;
