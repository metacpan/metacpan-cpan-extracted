#!perl -wT

use strict;
use warnings;
use autodie qw(:all);

use Test::Most tests => 4;

BEGIN {
	use_ok('File::Open::ReadOnly::NoCache');
}

OPEN: {
	my $fin = new_ok('File::Open::ReadOnly::NoCache' => [
		filename => 'lib/File/Open/ReadOnly/NoCache.pm'
	]);
	my $fd = $fin->fd();
	ok(<$fd> =~ /^package File::Open::ReadOnly::NoCache;/);

	ok(!defined(File::Open::ReadOnly::NoCache->new('/asdasd.not.notthere')));
}
