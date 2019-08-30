use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Upto

=abstract

Data-Object Float Function (Upto) Class

=synopsis

  use Data::Object::Float::Func::Upto;

  my $func = Data::Object::Float::Func::Upto->new(@args);

  $func->execute;

=description

Data::Object::Float::Func::Upto is a function object for Data::Object::Float.
This package inherits all behavior from L<Data::Object::Float::Func>.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Upto';

ok 1 and done_testing;
