use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Ne

=abstract

Data-Object Integer Function (Ne) Class

=synopsis

  use Data::Object::Integer::Func::Ne;

  my $func = Data::Object::Integer::Func::Ne->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Ne is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Ne';

ok 1 and done_testing;
