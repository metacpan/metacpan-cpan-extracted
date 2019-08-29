use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Ne

=abstract

Data-Object Hash Function (Ne) Class

=synopsis

  use Data::Object::Hash::Func::Ne;

  my $func = Data::Object::Hash::Func::Ne->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Ne is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Ne';

ok 1 and done_testing;
