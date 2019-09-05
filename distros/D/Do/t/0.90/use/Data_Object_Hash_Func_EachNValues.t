use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::EachNValues

=abstract

Data-Object Hash Function (EachNValues) Class

=synopsis

  use Data::Object::Hash::Func::EachNValues;

  my $func = Data::Object::Hash::Func::EachNValues->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::EachNValues is a function object for
Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::EachNValues';

ok 1 and done_testing;
