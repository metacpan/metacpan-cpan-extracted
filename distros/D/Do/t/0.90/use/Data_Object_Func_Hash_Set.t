use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Set

=abstract

Data-Object Hash Function (Set) Class

=synopsis

  use Data::Object::Func::Hash::Set;

  my $func = Data::Object::Func::Hash::Set->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Set is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Set';

ok 1 and done_testing;
