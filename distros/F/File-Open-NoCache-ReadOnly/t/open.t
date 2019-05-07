#!perl -wT

use strict;
use warnings;
use autodie qw(:all);

use Test::Most tests => 4;

BEGIN {
	use_ok('File::Open::NoCache::ReadOnly');
}

OPEN: {
	my $fin = new_ok('File::Open::NoCache::ReadOnly' => [
		filename => 'lib/File/Open/NoCache/ReadOnly.pm'
	]);
	my $fd = $fin->fd();
	ok(<$fd> =~ /^package File::Open::NoCache::ReadOnly;/);

	ok(!defined(File::Open::NoCache::ReadOnly->new('/asdasd.not.notthere')));
}
