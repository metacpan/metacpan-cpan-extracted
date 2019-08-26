use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepare_let

=usage

  prepare_let($package, @args);

=description

The prepare_let function returns a let-plan for the arguments passed.

=signature

prepare_let(Str $arg1, Any @args) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'prepare_let';

is_deeply Data::Object::Config::prepare_let(), ['let'];
is_deeply Data::Object::Config::prepare_let('$V=1;'), ['let', '$V=1;'];
is_deeply Data::Object::Config::prepare_let('$V=1;', '$A=2;'), ['let', '$V=1;', '$A=2;'];

ok 1 and done_testing;
