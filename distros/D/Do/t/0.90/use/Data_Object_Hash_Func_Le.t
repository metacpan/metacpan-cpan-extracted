use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Le

=abstract

Data-Object Hash Function (Le) Class

=synopsis

  use Data::Object::Hash::Func::Le;

  my $func = Data::Object::Hash::Func::Le->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Le is a function object for Data::Object::Hash. This
package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Le';

ok 1 and done_testing;
