#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 2;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Scalar::Util 'blessed', 'reftype';

BEGIN {
	use_ok ( 'IO::Any' ) or exit;
}

exit main();

sub main {
	my $x = *DATA;
	
	my $data_chunk = IO::Any->slurp(*DATA);
	eq_or_diff($data_chunk, "some\ndata\nchunk\n", 'read from <DATA>');
	
	return 0;
}

__DATA__
some
data
chunk
