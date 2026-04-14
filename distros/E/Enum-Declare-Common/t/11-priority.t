use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Priority;

subtest 'level constants' => sub {
	is(Lowest,  1, 'Lowest is 1');
	is(Low,     2, 'Low is 2');
	is(Medium,  3, 'Medium is 3');
	is(High,    4, 'High is 4');
	is(Highest, 5, 'Highest is 5');
};

subtest 'level meta' => sub {
	my $meta = Level();
	is($meta->count, 5, '5 priority levels');
	ok($meta->valid(1), '1 is valid');
	ok($meta->valid(5), '5 is valid');
	ok(!$meta->valid(0), '0 is not valid');
	ok(!$meta->valid(6), '6 is not valid');
	is($meta->name(3), 'Medium', 'name of 3 is Medium');
};

subtest 'level comparison' => sub {
	ok(High > Low, 'High > Low');
	ok(Lowest < Highest, 'Lowest < Highest');
	is(Medium, 3, 'Medium equals 3');
};

subtest 'severity constants' => sub {
	is(Debug,    'debug',    'Debug');
	is(Info,     'info',     'Info');
	is(Warning,  'warning',  'Warning');
	is(Error,    'error',    'Error');
	is(Critical, 'critical', 'Critical');
};

subtest 'severity meta' => sub {
	my $meta = Severity();
	is($meta->count, 5, '5 severity levels');
	ok($meta->valid('debug'),    'debug is valid');
	ok($meta->valid('critical'), 'critical is valid');
	ok(!$meta->valid('fatal'),   'fatal is not valid');
	is($meta->name('warning'), 'Warning', 'name of warning is Warning');
};

done_testing;
