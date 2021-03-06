use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_isa

=usage

  my $_formulate_isa = $self->_formulate_isa();

=description

The _formulate_isa function returns settings for the isa directive.

=signature

_formulate_isa(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::RoleHas';

my $data = 'Data::Object::RoleHas';

can_ok $data, '_formulate_isa';

ok 1 and done_testing;
