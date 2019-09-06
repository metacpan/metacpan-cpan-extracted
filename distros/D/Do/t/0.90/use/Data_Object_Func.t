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

=inherits

Data::Object::Base

=integrates

Data::Object::Role::Throwable

=libraries

Data::Object::Library

=description

This package is an abstract base class for function classes.

=cut

use_ok "Data::Object::Func";

ok 1 and done_testing;
