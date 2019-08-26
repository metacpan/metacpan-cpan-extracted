use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_wrt

=usage

  my $_formulate_wrt = $self->_formulate_wrt();

=description

The _formulate_wrt function returns settings for the writer directive.

=signature

_formulate_wrt(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::RoleHas';

my $data = 'Data::Object::RoleHas';

can_ok $data, '_formulate_wrt';

ok 1 and done_testing;
