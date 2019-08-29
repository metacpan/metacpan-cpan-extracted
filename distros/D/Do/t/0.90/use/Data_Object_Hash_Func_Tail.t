use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Tail

=abstract

Data-Object Hash Function (Tail) Class

=synopsis

  use Data::Object::Hash::Func::Tail;

  my $func = Data::Object::Hash::Func::Tail->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Tail is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Tail';

ok 1 and done_testing;
