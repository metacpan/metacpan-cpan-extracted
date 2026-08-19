#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin     qw($RealBin);
use lib "$RealBin/../../lib";
use Time::HiRes qw(time sleep);

use_ok('Fugu::Timeout');
use_ok('Fugu::Signal');

subtest 'bounded returns what the code returns' => sub {
	is( Fugu::Timeout::bounded( 5, sub { 'value' } ),
		'value', 'the return value passes through' );
	is_deeply( Fugu::Timeout::bounded( 5, sub { [ 1, 2 ] } ),
		[ 1, 2 ], 'a reference passes through' );
	is( Fugu::Timeout::bounded( 5, sub { undef } ),
		undef, 'undef passes through' );
};

subtest 'bounded stops a call that runs too long' => sub {
	my $start = time;
	my $result = Fugu::Timeout::bounded( 1, sub { sleep 30; 'never' } );
	my $elapsed = time - $start;

	is( $result, undef, 'a timeout gives undef' );
	ok( $elapsed < 10, 'and it returned near the deadline' )
	    or diag("took ${elapsed}s");

	# The alarm must not survive the call. A leaked alarm would kill
	# the caller some seconds later, far from the cause.
	is( alarm(0), 0, 'no alarm is left pending' );
};

subtest 'bounded lets a real error through' => sub {
	ok( !eval { Fugu::Timeout::bounded( 5, sub { die "real failure\n" } ); 1 },
		'a die inside the code propagates' );
	is( $@, "real failure\n", 'with its own message' );
	is( alarm(0), 0, 'and no alarm is left pending' );
};

subtest 'wait_until polls until the condition holds' => sub {
	my $calls = 0;
	my $result = Fugu::Timeout::wait_until( 5, 0.05, sub { ++$calls >= 3 } );

	ok( $result, 'the condition was met' );
	is( $calls, 3, 'the code ran until it returned true' );
};

subtest 'wait_until runs the code at least once' => sub {
	my $calls = 0;
	my $result = Fugu::Timeout::wait_until( 0, 0.05, sub { $calls++; 'now' } );

	is( $result, 'now', 'a zero timeout still asks once' );
	is( $calls,  1,     'exactly once' );
};

subtest 'wait_until gives up at the deadline' => sub {
	my $start = time;
	my $result = Fugu::Timeout::wait_until( 0.5, 0.05, sub { 0 } );
	my $elapsed = time - $start;

	is( $result, undef, 'a condition that never holds gives undef' );
	ok( $elapsed >= 0.4, 'it waited for the timeout' )
	    or diag("took ${elapsed}s");
	ok( $elapsed < 5, 'and no longer' ) or diag("took ${elapsed}s");
};

subtest 'wait_until stops on an interrupt' => sub {

	my $sig = Fugu::Signal->new;
	$sig->setup_interrupt_flag('USR1');

	my $calls = 0;
	my $start = time;
	kill 'USR1', $$;
	sleep 0.05;

	my $result = Fugu::Timeout::wait_until( 30, 0.05,
		sub { $calls++; 0 } );
	my $elapsed = time - $start;

	is( $result, undef, 'an interrupted wait gives undef' );
	is( $calls,  0,     'and the code never ran' );
	ok( $elapsed < 5, 'it returned at once' ) or diag("took ${elapsed}s");

	$sig->restore;
};

done_testing();
