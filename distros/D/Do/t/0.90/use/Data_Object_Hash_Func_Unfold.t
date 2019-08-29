use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Unfold

=abstract

Data-Object Hash Function (Unfold) Class

=synopsis

  use Data::Object::Hash::Func::Unfold;

  my $func = Data::Object::Hash::Func::Unfold->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Unfold is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Unfold';

ok 1 and done_testing;
