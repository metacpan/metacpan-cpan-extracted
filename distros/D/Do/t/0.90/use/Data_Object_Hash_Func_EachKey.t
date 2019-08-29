use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::EachKey

=abstract

Data-Object Hash Function (EachKey) Class

=synopsis

  use Data::Object::Hash::Func::EachKey;

  my $func = Data::Object::Hash::Func::EachKey->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::EachKey is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::EachKey';

ok 1 and done_testing;
