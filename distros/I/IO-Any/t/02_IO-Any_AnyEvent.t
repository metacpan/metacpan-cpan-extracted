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
	plan tests => 3;
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
		scalar IO::Any->slurp([$Bin, 'stock', '01.txt']),
		qq{1\n22\n333\n},
		'IO::Any->slurp() with AnyEvent loaded'
	);

	my $atomic = File::Spec->catfile($tmpdir, '02-atomic.txt');
	IO::Any->spew($atomic, 'old');
	IO::Any->spew($atomic, qq{atom\n}, { atomic => 1 });
	eq_or_diff(scalar read_file($atomic), qq{atom\n}, 'atomic IO::Any->spew() with AnyEvent loaded');

	return 0;
}
