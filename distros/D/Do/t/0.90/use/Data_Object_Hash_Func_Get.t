use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Get

=abstract

Data-Object Hash Function (Get) Class

=synopsis

  use Data::Object::Hash::Func::Get;

  my $func = Data::Object::Hash::Func::Get->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Get is a function object for Data::Object::Hash. This
package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Get';

ok 1 and done_testing;
