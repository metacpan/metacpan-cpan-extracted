use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Functable

=abstract

Data-Object Functable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Functable';

=description

This package provides mechanisms for dispatching to functors, i.e. data object
function classes.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Role::Functable";

ok 1 and done_testing;
