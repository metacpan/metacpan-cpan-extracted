use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Lt

=abstract

Data-Object Array Function (Lt) Class

=synopsis

  use Data::Object::Array::Func::Lt;

  my $func = Data::Object::Array::Func::Lt->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Lt is a function object for Data::Object::Array.
This package inherits all behavior from L<Data::Object::Array::Func>.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Lt';

ok 1 and done_testing;
