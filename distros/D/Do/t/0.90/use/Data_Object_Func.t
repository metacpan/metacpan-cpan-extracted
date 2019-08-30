use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Func

=abstract

Data-Object Function-Object Class

=synopsis

  use Data::Object::Func;

=description

This package is an abstract base class for function classes. This package
inherits all behavior from L<Data::Object::Base>.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Throwable>

=cut

use_ok "Data::Object::Func";

ok 1 and done_testing;
