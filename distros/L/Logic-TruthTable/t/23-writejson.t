#!perl
use 5.010001;
use strict;
use warnings FATAL => 'all';

use Logic::TruthTable;
use JSON;

use Test::More tests => 1;
use Test::Deep;

#
# (in column F1)
#
# 'MG0_Blue' translates to '0-1101-10000--11010-1-0--00-1111'
# which breaks down to:
# minterms: [2, 3, 5, 7, 14, 15, 17, 20, 28 .. 31]
# maxterms: [0, 4, 8 .. 11, 16, 18, 22, 25, 26]
# don't-cares: [1, 6, 12, 13, 19, 21, 23, 24, 27]
#
# (in column F0)
#
# 'Purdu3!!' translates to '0--1-00-1---1110-00-0010-0---0--'
# which breaks down to:
# minterms: [3, 8, 12, 13, 14, 22]
# maxterms: [0, 5, 6, 15, 17, 18, 20, 21, 23, 25, 29]
# don't-cares: [1, 2, 4, 7, 9, 10, 11, 16, 19, 24, 26, 27, 28, 30, 31]
#
my %col_mins = (
	F1 => [2, 3, 5, 7, 14, 15, 17, 20, 28 .. 31],
	F0 => [3, 8, 12, 13, 14, 22]
);
my %col_maxs = (
	F1 => [0, 4, 8 .. 11, 16, 18, 22, 25, 26],
	F0 => [0, 5, 6, 15, 17, 18, 20, 21, 23, 25, 29]
);
my %col_dcs = (
	F1 => [1, 6, 12, 13, 19, 21, 23, 24, 27],
	F0 => [1, 2, 4, 7, 9, 10, 11, 16, 19, 24, 26, 27, 28, 30, 31]
);

my $ttable = Logic::TruthTable->new(
	width => 5,
	dc => 'X',
	title => "Testing export of JSON",
	vars => [qw(a4 a3 a2 a1 a0)],
	columns => [{
		minterms => $col_mins{F0},
		dontcares => $col_dcs{F0},
	},
	{
		minterms => $col_mins{F1},
		dontcares => $col_dcs{F1},
	},
	],
);

#
# The variables that will read __DATA__ and
# that will take the export_json output.
#
my($json_export, $json_data);
open TESTOUT, '>', \$json_export or die "Can't open Test output variable.";

$ttable->export_json(write_handle => \*TESTOUT, dc => 'X');
close TESTOUT or die "Problem closing the output variable.";
{ local $/ = undef; $json_data = <DATA>; }

#
# Now convert them into hash refs.
#
my($export, $data) = (decode_json($json_export), decode_json($json_data));

cmp_deeply({output => $export}, {output => $data}, "JSON strings break down okay");

__DATA__
{
"width": 5,
"title": "Testing export of JSON",
"dc": "X",
"vars": ["a4", "a3", "a2", "a1", "a0"],
"functions": ["F0", "F1"],
"columns": [{"title": "F0", "pack81": "Purdu3!!"}, {"title": "F1", "pack81": "MG0_Blue"}]
}
