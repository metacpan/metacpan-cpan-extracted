# Pragmas.
use strict;
use warnings;

# Modules.
use Log::FreeSWITCH::Line::Data;
use Test::More 'tests' => 3;
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
