use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_req

=usage

  my $_formulate_req = $self->_formulate_req();

=description

The _formulate_req function returns settings for the required directive.

=signature

_formulate_req(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::RoleHas';

my $data = 'Data::Object::RoleHas';

can_ok $data, '_formulate_req';

ok 1 and done_testing;
