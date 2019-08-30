use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Struct

=abstract

Data-Object Struct Declaration

=synopsis

  package Environment;

  use Data::Object::Struct;

  has 'mode';

  1;

=description

This package modifies the consuming package making it a struct.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Immutable>

=cut

use_ok "Data::Object::Struct";

ok 1 and done_testing;
