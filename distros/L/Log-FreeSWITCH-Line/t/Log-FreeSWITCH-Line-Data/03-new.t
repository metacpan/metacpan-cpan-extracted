use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Log::FreeSWITCH::Line::Data;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
eval {
	Log::FreeSWITCH::Line::Data->new;
};
is($EVAL_ERROR, "date required\n", "Parameter 'date' is required.");
clean();

# Test.
eval {
	Log::FreeSWITCH::Line::Data->new(
		'date' => '2015-01-01',
	);
};
is($EVAL_ERROR, "file required\n", "Parameter 'file' is required.");
clean();

# Test.
eval {
	Log::FreeSWITCH::Line::Data->new(
		'date' => '2015-01-01',
		'file' => 'file.c',
	);
};
is($EVAL_ERROR, "file_line required\n", "Parameter 'file_line' is required.");
clean();

# Test.
eval {
	Log::FreeSWITCH::Line::Data->new(
		'date' => '2015-01-01',
		'file' => 'file.c',
		'file_line' => 10,
	);
};
is($EVAL_ERROR, "time required\n", "Parameter 'time' is required.");
clean();

# Test.
eval {
	Log::FreeSWITCH::Line::Data->new(
		'date' => '2015-01-01',
		'file' => 'file.c',
		'file_line' => 10,
		'time' => '20:11:23',
	);
};
is($EVAL_ERROR, "type required\n", "Parameter 'type' is required.");
clean();

# Test.
my $obj = Log::FreeSWITCH::Line::Data->new(
	'date' => '2015-01-01',
	'file' => 'file.c',
	'file_line' => 10,
	'time' => '20:11:23',
	'type' => 'M',
);
isa_ok($obj, 'Log::FreeSWITCH::Line::Data');
