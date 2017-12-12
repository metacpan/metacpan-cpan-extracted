use Test::More tests => 5;
use strict;
use warnings;

use Iterator::Simple qw(:all);

sub mk_itr {
	my($start, $max) = @_;
	my $cur = $start;
	iterator {
		return if $cur > $max;
		return $cur++;
	}
}

my $itr;

#1
ok( mk_itr(1,5), 'iterator creation' );

#2
{
	$itr = mk_itr(2,8);
	my @res;
	while(defined(my $r = $itr->next)) {
		push @res, $r
	}
	is_deeply ( \@res, [2,3,4,5,6,7,8], 'next method');
}

#3
{
	$itr = mk_itr(3,6);
	my @res;
	while(defined(my $r = $itr->())) {
		push @res, $r
	}
	is_deeply ( \@res, [3,4,5,6], 'direct execute' );
}

#4
{
	$itr = mk_itr(11,15);
	is_deeply ( list($itr), [11,12,13,14,15], 'listize' );
}

#5
{
	$itr = mk_itr(1,5);
	my @res;
	while(<$itr>) {
		push @res, $_;
	}
	is_deeply ( \@res, [1,2,3,4,5], '"<>" overload' );
}

# @{} overloads could cause confusion
##6
#{
#	$itr = mk_itr(12,17);
#	is_deeply ( [@{$itr}], [12,13,14,15,16,17], '"@{}" overload' );
#}

