use Test::More tests => 6;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

#1-2 ichain
{
	my $ary = [1,2,3];
	my $aryiter = iter(['foo','bar','baz']);
	my $ioiter = iter(\*DATA);
	ok(($itr = ichain($ary, $aryiter, $ioiter)), 'ichain creation');
	is_deeply list($itr) => [1,2,3,'foo','bar','baz',"dog\n", "cat\n", "cow\n"], 'ichain result'
}

#1-3 izip
{
	my $ary1 = ['dog','cat','cow'];
	my $ary2 = ['inu','neko','ushi', 'what?'];
	ok(($itr = izip($ary1, $ary2)), 'izip creation');
	is_deeply list($itr) => [['dog','inu'],['cat','neko'],['cow', 'ushi']], 'izip result'
}

#1-4 ienumrate
{
	my $ary = ['foo', 'bar', 'baz'];
	ok(($itr = ienumerate($ary)), 'ienumerate creattion');
	is_deeply list($itr) => [[0,'foo'],[1,'bar'],[2,'baz']], 'ienumerate result';
}

__DATA__
dog
cat
cow
