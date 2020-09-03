use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
use IO::Callback;

my $count = 0;
my $fh = 'IO::Callback'->new( '<', sub {
	return if ++$count > 10;
	return "foo\n";
}, [] );

my @stat = $fh->stat;

is $stat[7], 0;
