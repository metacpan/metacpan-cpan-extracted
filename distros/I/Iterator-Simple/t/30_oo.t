use Test::More tests => 3;

use strict;
use warnings;

use Iterator::Simple qw(iter list);

my $itr;
{
	$itr = iter(['foo','bar'])->enumerate;
	$itr = iter([1,$itr ,3,4]);
	$itr = $itr->flatten();
	$itr = $itr->chain(iter ['dog','cat']);
	is_deeply list($itr) => [1,[0,'foo'],[1,'bar'],3,4,'dog','cat'], 'misc filter method';
}

{
	my $trans1 = sub { $_ ** 2 };
	my $trans2 = sub { ":$_"  };

	$itr = iter([1,2,3,4,5]);
	$itr = $itr->filter($trans1)->filter($trans2);
	is_deeply list($itr) => [':1', ':4', ':9', ':16', ':25'], 'general filter';

	$itr = iter([1,2,3,4,5]);
	$itr = $itr | $trans1 | $trans2;
	is_deeply list($itr) => [':1', ':4', ':9', ':16', ':25'], 'pipe overload';
}
