use strict;
use warnings;

use Memory::Process;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Memory::Process->new;
my $ret = $obj->report;
is($ret, '', 'Get report() string for zero recorded stays.');

# Test.
my @ret = $obj->report;
is_deeply(
	\@ret,
	[],
	'Get report() array for zero recorded stays.',
);

# Test.
# TODO
