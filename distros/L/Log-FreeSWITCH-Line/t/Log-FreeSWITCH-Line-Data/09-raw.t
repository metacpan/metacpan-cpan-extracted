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
my $ret = $obj->raw;
is($ret, undef, 'Get undefined raw log entry.');

# Test.
$obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'message' => 'Foo bar.',
	'raw' => '2015-01-01 20:11:23 [M] file.c:10 Foo bar.',
	'time' => '20:11:23',
	'type' => 'M',
);
$ret = $obj->raw;
is($ret, '2015-01-01 20:11:23 [M] file.c:10 Foo bar.', 'Get raw log entry.');
