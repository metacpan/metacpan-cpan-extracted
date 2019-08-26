use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Ne

=abstract

Data-Object Array Function (Ne) Class

=synopsis

  use Data::Object::Func::Array::Ne;

  my $func = Data::Object::Func::Array::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Ne is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Ne';

ok 1 and done_testing;
