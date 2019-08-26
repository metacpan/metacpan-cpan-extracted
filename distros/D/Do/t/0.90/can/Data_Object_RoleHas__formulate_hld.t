use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_hld

=usage

  my $_formulate_hld = $self->_formulate_hld();

=description

The _formulate_hld function returns settings for the handler directive.

=signature

_formulate_hld(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::RoleHas';

my $data = 'Data::Object::RoleHas';

can_ok $data, '_formulate_hld';

ok 1 and done_testing;
