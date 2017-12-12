use Test::More tests => 4;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

{
	my $aryiter = iter([ 'foo', 'bar', iter(['hoge','hage']), 1, 2]);
	$itr = iflatten $aryiter;
	ok is_iterator($itr), 'iflatten creation';
	is_deeply list($itr) => ['foo', 'bar','hoge','hage',1,2], 'iflatten result';
}

{
	my $ary = [ 'foo', 'bar', iter(['hoge','hage']), 1, 2];
	$itr = iflatten $ary;
	ok is_iterator($itr), 'iterable source';
	is_deeply list($itr) => ['foo', 'bar','hoge','hage',1,2], 'iterable source result';
}

