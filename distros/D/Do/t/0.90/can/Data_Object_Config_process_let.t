use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

process_let

=usage

  process_let($caller, $plan);

=description

The process_let function executes the let-plan on behalf of the caller.

=signature

process_let(Str $arg1, ArrayRef $arg2) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'process_let';

ok 1 and done_testing;
