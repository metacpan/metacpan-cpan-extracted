use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Ne

=abstract

Data-Object Any Function (Ne) Class

=synopsis

  use Data::Object::Any::Func::Ne;

  my $func = Data::Object::Any::Func::Ne->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Ne is a function object for Data::Object::Any. This
package inherits all behavior from L<Data::Object::Any::Func>.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Ne';

ok 1 and done_testing;
