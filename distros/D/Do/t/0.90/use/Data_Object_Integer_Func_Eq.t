use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Eq

=abstract

Data-Object Integer Function (Eq) Class

=synopsis

  use Data::Object::Integer::Func::Eq;

  my $func = Data::Object::Integer::Func::Eq->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Eq is a function object for Data::Object::Integer.
This package inherits all behavior from L<Data::Object::Integer::Func>.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Eq';

ok 1 and done_testing;
