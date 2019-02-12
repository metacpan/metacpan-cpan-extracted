#!perl
use 5.010001;
use strict;
use warnings FATAL => 'all';

use Logic::TruthTable;

use Test::More tests => 7;

my %col_mins = (
	w0 => [8, 12, 14, 15],
	w1 => [6, 9, 11, 14],
);
my %col_dcs = (
	w0 => [1..5, 9, 13],
	w1 => [0..4, 8, 12],
);

my $ttable = Logic::TruthTable->import_csv(
	title => "Table created from __DATA__ section.",
	read_handle => \*DATA,
);

ok(defined $ttable, "Logic::TruthTable object not created.");

SKIP: {
	#
	# There are two function columns, so there are
	# six tests to run if nothing goes wrong.
	#
	skip "No object to test", 4 unless defined $ttable;

	for my $f ( @{$ttable->functions()} )
	{
		my $col = $ttable->fncolumn($f);
		ok(defined $col, "Column $f not found.");

		if (defined $col)
		{
			my $terms = $col->minterms;
			my $dcs = $col->dontcares;

			is_deeply($terms, $col_mins{$f},
				"Columm $f minterms returned: " . join(", ", @$terms));
			is_deeply($dcs, $col_dcs{$f},
				"Columm $f don't-cares returned: " . join(", ", @$dcs));
		}
	}
}

__DATA__
a1,a0,b1,b0,,w1,w0
0,0,0,0,,X,0
0,0,0,1,,X,X
0,0,1,0,,X,X
0,0,1,1,,X,X
0,1,0,0,,X,X
0,1,0,1,,0,X
0,1,1,0,,1,0
0,1,1,1,,0,0
1,0,0,0,,X,1
1,0,0,1,,1,X
1,0,1,0,,0,0
1,0,1,1,,1,0
1,1,0,0,,X,1
1,1,0,1,,0,X
1,1,1,0,,1,1
1,1,1,1,,0,1
