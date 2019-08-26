use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Head

=abstract

Data-Object Array Function (Head) Class

=synopsis

  use Data::Object::Func::Array::Head;

  my $func = Data::Object::Func::Array::Head->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Head is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Head';

ok 1 and done_testing;
