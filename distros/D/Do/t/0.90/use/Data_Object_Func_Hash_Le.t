use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Le

=abstract

Data-Object Hash Function (Le) Class

=synopsis

  use Data::Object::Func::Hash::Le;

  my $func = Data::Object::Func::Hash::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Le is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Le';

ok 1 and done_testing;
