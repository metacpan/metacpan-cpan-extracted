use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base

=abstract

Data-Object Base Class

=synopsis

  use parent 'Data::Object::Base';

=libraries

Data::Object::Library

=description

This package provides an abstract base class used for identity and
classification of L<Data::Object> classes.

=cut

use_ok "Data::Object::Base";

ok 1 and done_testing;
