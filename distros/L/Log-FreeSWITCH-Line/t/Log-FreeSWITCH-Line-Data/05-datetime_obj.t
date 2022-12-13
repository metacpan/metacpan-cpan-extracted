use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Log::FreeSWITCH::Line::Data;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'time' => '20:11:23',
	'type' => 'M',
);
my $ret = $obj->datetime_obj;
isa_ok($ret, 'DateTime', 'Get DateTime object without miliseconds.');

# Test.
$obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'time' => '20:11:23.100',
	'type' => 'M',
);
$ret = $obj->datetime_obj;
isa_ok($ret, 'DateTime', 'Get DateTime object with miliseconds.');

# Test.
$obj = Log::FreeSWITCH::Line::Data->new(
	'date' => 'bad',
	'file' => 'file.c',
	'file_line' => 10,
	'time' => '20:11:23.100',
	'type' => 'M',
);
eval {
	$obj->datetime_obj;
};
is($EVAL_ERROR, "Cannot create DateTime object.\n", "Cannot create DateTime object.");
clean();
