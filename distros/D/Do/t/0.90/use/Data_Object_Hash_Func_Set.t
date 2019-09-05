use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Set

=abstract

Data-Object Hash Function (Set) Class

=synopsis

  use Data::Object::Hash::Func::Set;

  my $func = Data::Object::Hash::Func::Set->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::Set is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Set';

ok 1 and done_testing;
