use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Ne

=abstract

Data-Object Float Function (Ne) Class

=synopsis

  use Data::Object::Float::Func::Ne;

  my $func = Data::Object::Float::Func::Ne->new(@args);

  $func->execute;

=description

Data::Object::Float::Func::Ne is a function object for Data::Object::Float.
This package inherits all behavior from L<Data::Object::Float::Func>.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Ne';

ok 1 and done_testing;
