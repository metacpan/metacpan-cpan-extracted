use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Gt

=abstract

Data-Object Any Function (Gt) Class

=synopsis

  use Data::Object::Any::Func::Gt;

  my $func = Data::Object::Any::Func::Gt->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Gt is a function object for Data::Object::Any. This
package inherits all behavior from L<Data::Object::Any::Func>.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Gt';

ok 1 and done_testing;
