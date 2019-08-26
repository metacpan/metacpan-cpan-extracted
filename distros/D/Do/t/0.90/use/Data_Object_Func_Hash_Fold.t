use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Fold

=abstract

Data-Object Hash Function (Fold) Class

=synopsis

  use Data::Object::Func::Hash::Fold;

  my $func = Data::Object::Func::Hash::Fold->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Fold is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Fold';

ok 1 and done_testing;
