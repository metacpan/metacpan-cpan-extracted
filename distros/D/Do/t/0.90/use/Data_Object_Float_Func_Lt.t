use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Lt

=abstract

Data-Object Float Function (Lt) Class

=synopsis

  use Data::Object::Float::Func::Lt;

  my $func = Data::Object::Float::Func::Lt->new(@args);

  $func->execute;

=description

Data::Object::Float::Func::Lt is a function object for Data::Object::Float.
This package inherits all behavior from L<Data::Object::Float::Func>.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Lt';

ok 1 and done_testing;
