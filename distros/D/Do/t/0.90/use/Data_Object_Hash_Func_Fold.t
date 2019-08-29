use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Fold

=abstract

Data-Object Hash Function (Fold) Class

=synopsis

  use Data::Object::Hash::Func::Fold;

  my $func = Data::Object::Hash::Func::Fold->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Fold is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Fold';

ok 1 and done_testing;
