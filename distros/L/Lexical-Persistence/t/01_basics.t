#!perl

use warnings;
use strict;

use Lexical::Persistence;

use constant CATCHALL_X => 100;
use constant X          => 200;
use constant OTHER_X    => 300;

use Test::More tests => 36;

sub target {
	my ($arg_test, $catchall_x, $x, $other_x, $_j);

	is ( $catchall_x++, CATCHALL_X + $arg_test, "persistent catchall $arg_test" );
	is ( $x++, X + $arg_test, "persistent x $arg_test" );
	is ( $other_x++, OTHER_X + $arg_test, "other x $arg_test" );
	is ( $_j++, 0, "dynamic j $arg_test" );
}

my $state = Lexical::Persistence->new();
$state->set_context( other => { '$x' => OTHER_X } );
$state->set_context( _ => { '$catchall_x' => CATCHALL_X, '$x' => X } );

### Test plain old calling.

for my $test (0..2) {
	$state->call(\&target, test => $test);
}

### Test calling via wrapper.

my $thunk = $state->wrap(\&target);
for my $test (3..5) {
	$thunk->(test => $test);
}

### Test method invocation.

{
	package TestObject;
	use Test::More;
	sub new { return bless [ ] }
	sub target {
		my ($arg_test, $catchall_x, $x, $other_x, $_j);

		is (
			$catchall_x++, ::CATCHALL_X + $arg_test,
			"persistent catchall (method) $arg_test"
		);
		is ( $x++, ::X + $arg_test, "persistent x (method) $arg_test" );
		is ( $other_x++, ::OTHER_X + $arg_test, "other x (method) $arg_test" );
		is ( $_j++, 0, "dynamic j (method) $arg_test" );
	}
}

my $object = TestObject->new();
for my $test (6..8) {
	$state->invoke($object, "target", test => $test);
}
