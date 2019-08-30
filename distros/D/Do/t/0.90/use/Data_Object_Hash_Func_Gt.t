use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Gt

=abstract

Data-Object Hash Function (Gt) Class

=synopsis

  use Data::Object::Hash::Func::Gt;

  my $func = Data::Object::Hash::Func::Gt->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Gt is a function object for Data::Object::Hash. This
package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Gt';

ok 1 and done_testing;
