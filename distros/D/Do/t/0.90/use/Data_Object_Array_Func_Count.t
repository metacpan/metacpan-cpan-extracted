use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Count

=abstract

Data-Object Array Function (Count) Class

=synopsis

  use Data::Object::Array::Func::Count;

  my $func = Data::Object::Array::Func::Count->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Count is a function object for Data::Object::Array.
This package inherits all behavior from L<Data::Object::Array::Func>.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Count';

ok 1 and done_testing;
