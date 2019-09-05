use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Snakecase

=abstract

Data-Object String Function (Snakecase) Class

=synopsis

  use Data::Object::String::Func::Snakecase;

  my $func = Data::Object::String::Func::Snakecase->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Snakecase is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Snakecase';

ok 1 and done_testing;
