use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::LogLevel;

subtest 'level constants' => sub {
	is(Trace, 0, 'Trace is 0');
	is(Debug, 1, 'Debug is 1');
	is(Info,  2, 'Info is 2');
	is(Warn,  3, 'Warn is 3');
	is(Error, 4, 'Error is 4');
	is(Fatal, 5, 'Fatal is 5');
};

subtest 'level comparison' => sub {
	ok(Fatal > Error,  'Fatal > Error');
	ok(Error > Warn,   'Error > Warn');
	ok(Warn  > Info,   'Warn > Info');
	ok(Info  > Debug,  'Info > Debug');
	ok(Debug > Trace,  'Debug > Trace');
};

subtest 'meta accessor' => sub {
	my $meta = Level();
	is($meta->count, 6, '6 log levels');
	ok($meta->valid(0), 'Trace (0) is valid');
	ok($meta->valid(5), 'Fatal (5) is valid');
	ok(!$meta->valid(6), '6 is not valid');
	is($meta->name(0), 'Trace', 'name of 0 is Trace');
	is($meta->name(5), 'Fatal', 'name of 5 is Fatal');
};

done_testing;
