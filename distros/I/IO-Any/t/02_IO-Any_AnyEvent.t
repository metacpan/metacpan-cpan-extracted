#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More;
BEGIN {
	plan skip_all => "Cannot run on Windows"
		if $^O eq 'MSWin32';
	eval "use AnyEvent";
	plan skip_all => "requires AnyEvent to run"
		if $@;
	plan tests => 6;
}

use Test::Differences;
use File::Spec;
use File::Temp 'tempdir';
use File::Slurp 'read_file';


use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'IO::Any' ) or exit;
}

exit main();

sub main {
	my $tmpdir = tempdir( CLEANUP => 1 );

	eq_or_diff(
		[ IO::Any->slurp([$Bin, 'stock', '01.txt']) ],
		[ qq{1\n22\n333\n} ],
		'[ IO::Any->slurp() ]'
	);
	eq_or_diff(
		scalar IO::Any->slurp([$Bin, 'stock', '01.txt']),
		qq{1\n22\n333\n},
		'scalar IO::Any->slurp()'
	);
	eq_or_diff(
		scalar IO::Any->slurp(\qq{1\n22\n333\n}),
		qq{1\n22\n333\n},
		'IO::Any->slurp() string'
	);
	
	IO::Any->spew([$tmpdir, '02-test.txt'], qq{4\n55\n666\n});
	eq_or_diff(
		scalar read_file(File::Spec->catfile($tmpdir, '02-test.txt')),
		qq{4\n55\n666\n},
		'IO::Any->spew()'
	);
	my $str;
	IO::Any->spew(\$str, qq{1\n22\n333\n});
	eq_or_diff(
		$str,
		qq{1\n22\n333\n},
		'IO::Any->spew(\$str)'
	);

	return 0;
}

