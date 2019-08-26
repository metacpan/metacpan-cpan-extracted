use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepare_add

=usage

  prepare_add($package, $function);

=description

The prepare_add function returns an add-plan for the arguments passed.

=signature

prepare_add(Str $arg1, Str $arg2) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'prepare_add';

is_deeply Data::Object::Config::prepare_add(), ['add', undef, undef];
is_deeply Data::Object::Config::prepare_add('main', 'ok'), ['add', 'main', 'ok'];

ok 1 and done_testing;
