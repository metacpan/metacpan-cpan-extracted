use strict;
use warnings;

use Log::FreeSWITCH::Line::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'time' => '20:11:23',
	'type' => 'M',
);
my $ret = $obj->file_line;
is($ret, '10', 'Get file line.');
