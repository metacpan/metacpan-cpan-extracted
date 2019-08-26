use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

process

=usage

  process($caller, $plans);

=description

The process function executes a series of plans on behalf of the caller.

=signature

process(Str $arg1, ArrayRef $arg2) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'process';

ok 1 and done_testing;
