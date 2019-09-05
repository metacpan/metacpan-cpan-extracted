use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::List

=abstract

Data-Object Array Function (List) Class

=synopsis

  use Data::Object::Array::Func::List;

  my $func = Data::Object::Array::Func::List->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::List is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::List';

ok 1 and done_testing;
