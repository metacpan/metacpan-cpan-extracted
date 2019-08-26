use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepare_use

=usage

  prepare_use($package, @args);

=description

The prepare_use function returns a use-plan for the arguments passed.

=signature

prepare_use(Str $arg1, Any @args) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'prepare_use';

is_deeply Data::Object::Config::prepare_use(), ['use', undef];
is_deeply Data::Object::Config::prepare_use('strict'), ['use', 'strict'];
is_deeply Data::Object::Config::prepare_use('feature', 'say'), ['use', 'feature', 'say'];

ok 1 and done_testing;
