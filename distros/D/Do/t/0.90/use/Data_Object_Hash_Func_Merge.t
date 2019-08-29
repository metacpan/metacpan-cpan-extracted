use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Merge

=abstract

Data-Object Hash Function (Merge) Class

=synopsis

  use Data::Object::Hash::Func::Merge;

  my $func = Data::Object::Hash::Func::Merge->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Merge is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Merge';

ok 1 and done_testing;
