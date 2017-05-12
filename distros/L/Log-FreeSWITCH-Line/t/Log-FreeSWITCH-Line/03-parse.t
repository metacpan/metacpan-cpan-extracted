# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure::Utils qw(clean);
use Log::FreeSWITCH::Line qw(parse);
use Test::More 'tests' => 23;
use Test::NoWarnings;

# Test.
eval {
	parse('Foo');
};
is($EVAL_ERROR, "Cannot parse data.\n", 'Cannot parse data.');
clean();

# Test.
my $ret = parse('2015-01-01 12:12:12 [X] foo.c:10 ');
isa_ok($ret, 'Log::FreeSWITCH::Line::Data',
	'1. Data object in parsing of log entry without message.');
is($ret->date, '2015-01-01', '1. Get date.');
is($ret->time, '12:12:12', '1. Get time.');
is($ret->type, 'X', '1. Get type.');
is($ret->file, 'foo.c', '1. Get file.');
is($ret->file_line, 10, '1. Get file line.');
is($ret->message, '', '1. Get message.');

# Test.
$ret = parse("2015-01-01 12:12:12 [X] foo.c:10 bar");
isa_ok($ret, 'Log::FreeSWITCH::Line::Data',
	'2. Data object in parsing of log entry with message.');
is($ret->date, '2015-01-01', '2. Get date.');
is($ret->time, '12:12:12', '2. Get time.');
is($ret->type, 'X', '2. Get type.');
is($ret->file, 'foo.c', '2. Get file.');
is($ret->file_line, 10, '2. Get file line.');
is($ret->message, 'bar', '2. Get message.');

# Test.
$ret = parse("2015-01-01 12:12:12.123456 [X] foo.c:10 bar");
isa_ok($ret, 'Log::FreeSWITCH::Line::Data',
	'3. Data object in parsing of log entry with message and miliseconds.');
is($ret->date, '2015-01-01', '3. Get date.');
is($ret->time, '12:12:12.123456', '3. Get time.');
is($ret->type, 'X', '3. Get type.');
is($ret->file, 'foo.c', '3. Get file.');
is($ret->file_line, 10, '3. Get file line.');
is($ret->message, 'bar', '3. Get message.');
