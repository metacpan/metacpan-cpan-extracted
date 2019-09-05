use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Reverse

=abstract

Data-Object Hash Function (Reverse) Class

=synopsis

  use Data::Object::Hash::Func::Reverse;

  my $func = Data::Object::Hash::Func::Reverse->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::Reverse is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Reverse';

ok 1 and done_testing;
