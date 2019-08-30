use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Le

=abstract

Data-Object Any Function (Le) Class

=synopsis

  use Data::Object::Any::Func::Le;

  my $func = Data::Object::Any::Func::Le->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Le is a function object for Data::Object::Any. This
package inherits all behavior from L<Data::Object::Any::Func>.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Le';

ok 1 and done_testing;
