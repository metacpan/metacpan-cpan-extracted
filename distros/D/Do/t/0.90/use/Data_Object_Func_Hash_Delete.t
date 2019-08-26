use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Delete

=abstract

Data-Object Hash Function (Delete) Class

=synopsis

  use Data::Object::Func::Hash::Delete;

  my $func = Data::Object::Func::Hash::Delete->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Delete is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Delete';

ok 1 and done_testing;
