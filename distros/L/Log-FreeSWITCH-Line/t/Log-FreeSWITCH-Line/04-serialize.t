use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Log::FreeSWITCH::Line qw(serialize);
use Log::FreeSWITCH::Line::Data;
use Test::MockObject;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
eval {
	serialize('Foo');
};
is($EVAL_ERROR,
	"Serialize object must be 'Log::FreeSWITCH::Line::Data' object.\n",
	"Serialize object must be 'Log::FreeSWITCH::Line::Data' object ".
	"(String).");
clean();

# Test.
eval {
	serialize(Test::MockObject->new);
};
is($EVAL_ERROR,
	"Serialize object must be 'Log::FreeSWITCH::Line::Data' object.\n",
	"Serialize object must be 'Log::FreeSWITCH::Line::Data' object ".
	"(Bad object).");
clean();

# Test.
my $data = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'foo.c',
	'file_line' => 10,
	'time' => '12:12:12',
	'type' => 'X',
);
my $ret = serialize($data);
is($ret, '2015-01-01 12:12:12 [X] foo.c:10 ', 'Get log entry without message.');
is($data->raw, '2015-01-01 12:12:12 [X] foo.c:10 ',
	'Get log entry in raw() method.');

# Test.
$data = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'foo.c',
	'file_line' => 10,
	'message' => 'bar',
	'time' => '12:12:12',
	'type' => 'X',
);
$ret = serialize($data);
is($ret, '2015-01-01 12:12:12 [X] foo.c:10 bar', 'Get log entry with message.');
is($data->raw, '2015-01-01 12:12:12 [X] foo.c:10 bar',
	'Get log entry in raw() method.');

# Test.
$data = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'foo.c',
	'file_line' => 10,
	'message' => 'bar',
	'time' => '12:12:12.123',
	'type' => 'X',
);
$ret = serialize($data);
is($ret, '2015-01-01 12:12:12.123 [X] foo.c:10 bar',
	'Get log entry with message and miliseconds.');
is($data->raw, '2015-01-01 12:12:12.123 [X] foo.c:10 bar',
	'Get log entry in raw() method.');
