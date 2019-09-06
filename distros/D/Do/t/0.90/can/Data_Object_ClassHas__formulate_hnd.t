use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_hnd

=usage

  my $_formulate_hnd = $self->_formulate_hnd();

=description

The _formulate_hnd function returns settings for the handler directive.

=signature

_formulate_hnd(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::ClassHas';

my $data = 'Data::Object::ClassHas';

can_ok $data, '_formulate_hnd';

ok 1 and done_testing;
