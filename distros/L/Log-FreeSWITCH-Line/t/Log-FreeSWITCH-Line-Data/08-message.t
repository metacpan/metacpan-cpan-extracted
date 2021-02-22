use strict;
use warnings;

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
my $ret = $obj->message;
is($ret, undef, 'Get undefined message.');

# Test.
$obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'message' => 'Foo bar.',
	'time' => '20:11:23',
	'type' => 'M',
);
$ret = $obj->message;
is($ret, 'Foo bar.', 'Get message.');
