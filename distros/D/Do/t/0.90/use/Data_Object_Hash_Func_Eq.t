use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Eq

=abstract

Data-Object Hash Function (Eq) Class

=synopsis

  use Data::Object::Hash::Func::Eq;

  my $func = Data::Object::Hash::Func::Eq->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Eq is a function object for Data::Object::Hash. This
package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Eq';

ok 1 and done_testing;
