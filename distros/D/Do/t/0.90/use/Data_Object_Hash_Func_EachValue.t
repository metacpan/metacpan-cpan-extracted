use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::EachValue

=abstract

Data-Object Hash Function (EachValue) Class

=synopsis

  use Data::Object::Hash::Func::EachValue;

  my $func = Data::Object::Hash::Func::EachValue->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::EachValue is a function object for
Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::EachValue';

ok 1 and done_testing;
