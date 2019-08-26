use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::Le

=abstract

Data-Object Integer Function (Le) Class

=synopsis

  use Data::Object::Func::Integer::Le;

  my $func = Data::Object::Func::Integer::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::Le is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::Le';

ok 1 and done_testing;
