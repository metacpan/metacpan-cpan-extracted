use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Calendar;

subtest 'weekday constants' => sub {
	is(Monday,    1, 'Monday is 1');
	is(Tuesday,   2, 'Tuesday is 2');
	is(Wednesday, 3, 'Wednesday is 3');
	is(Thursday,  4, 'Thursday is 4');
	is(Friday,    5, 'Friday is 5');
	is(Saturday,  6, 'Saturday is 6');
	is(Sunday,    7, 'Sunday is 7');
};

subtest 'weekday meta' => sub {
	my $meta = Weekday();
	is($meta->count, 7, '7 weekdays');
	is($meta->name(1), 'Monday', 'name of 1 is Monday');
	is($meta->value('Friday'), 5, 'value of Friday is 5');
	ok($meta->valid(7), '7 is valid');
	ok(!$meta->valid(0), '0 is not valid');
	ok(!$meta->valid(8), '8 is not valid');
};

subtest 'weekday flag constants' => sub {
	is(Mon, 1,  'Mon is 1');
	is(Tue, 2,  'Tue is 2');
	is(Wed, 4,  'Wed is 4');
	is(Thu, 8,  'Thu is 8');
	is(Fri, 16, 'Fri is 16');
	is(Sat, 32, 'Sat is 32');
	is(Sun, 64, 'Sun is 64');
};

subtest 'weekday flag combinations' => sub {
	my $weekdays = Mon | Tue | Wed | Thu | Fri;
	is($weekdays, 31, 'weekdays bitmask is 31');

	my $weekend = Sat | Sun;
	is($weekend, 96, 'weekend bitmask is 96');

	ok($weekdays & Mon, 'weekdays includes Mon');
	ok(!($weekdays & Sat), 'weekdays excludes Sat');
	ok($weekend & Sun, 'weekend includes Sun');
};

subtest 'month constants' => sub {
	is(January,   1,  'January is 1');
	is(February,  2,  'February is 2');
	is(March,     3,  'March is 3');
	is(April,     4,  'April is 4');
	is(May,       5,  'May is 5');
	is(June,      6,  'June is 6');
	is(July,      7,  'July is 7');
	is(August,    8,  'August is 8');
	is(September, 9,  'September is 9');
	is(October,   10, 'October is 10');
	is(November,  11, 'November is 11');
	is(December,  12, 'December is 12');
};

subtest 'month meta' => sub {
	my $meta = Month();
	is($meta->count, 12, '12 months');
	is($meta->name(1), 'January', 'name of 1 is January');
	is($meta->name(12), 'December', 'name of 12 is December');
	is($meta->value('March'), 3, 'value of March is 3');
	ok($meta->valid(6), '6 is valid');
	ok(!$meta->valid(0), '0 is not valid');
	ok(!$meta->valid(13), '13 is not valid');
};

done_testing();
