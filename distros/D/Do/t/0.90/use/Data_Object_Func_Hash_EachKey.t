use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::EachKey

=abstract

Data-Object Hash Function (EachKey) Class

=synopsis

  use Data::Object::Func::Hash::EachKey;

  my $func = Data::Object::Func::Hash::EachKey->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::EachKey is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::EachKey';

ok 1 and done_testing;
