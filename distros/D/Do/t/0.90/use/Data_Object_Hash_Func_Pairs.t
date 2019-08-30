use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Pairs

=abstract

Data-Object Hash Function (Pairs) Class

=synopsis

  use Data::Object::Hash::Func::Pairs;

  my $func = Data::Object::Hash::Func::Pairs->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Pairs is a function object for Data::Object::Hash.
This package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Pairs';

ok 1 and done_testing;
