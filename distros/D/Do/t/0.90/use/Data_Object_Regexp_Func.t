use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Regexp::Func

=abstract

Functions for RegexpRefs

=synopsis

  use Data::Object::Regexp::Func;

=description

Data::Object::Regexp::Func is an abstract base class for function classes in
the Data::Object::Regexp::Func space. This package inherits all behavior from
L<Data::Object::Func>.

=cut

use_ok "Data::Object::Regexp::Func";

ok 1 and done_testing;
