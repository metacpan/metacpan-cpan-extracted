use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Delete

=abstract

Data-Object Hash Function (Delete) Class

=synopsis

  use Data::Object::Hash::Func::Delete;

  my $func = Data::Object::Hash::Func::Delete->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Delete is a function object for Data::Object::Hash.
This package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Delete';

ok 1 and done_testing;
