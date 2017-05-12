use strict;
use warnings;
use Test::More tests => 7;

use Graph;
use Graph::Maker::Utils qw/:all/;

require 't/matches.pl';

&Test(1);
&Test(0);

ok(is_valid_degree_seq(5,3,3,3,3,2,2,2,1,1,1));
ok(is_valid_degree_seq(3,3,3,3,3,3,3,3,3,3,3,3));
ok(is_valid_degree_seq(2,1,1,1,1));
ok(not is_valid_degree_seq(2,2,1,1,1));
ok(not is_valid_degree_seq(50,1,1,1));

sub Test
{
	my $dir = shift;

	my $g = new Graph(directed => $dir);
	$g->add_path(1..5);
	$g->add_path(reverse 1..5);

	my $h = new Graph(directed => $dir);
	$h->add_path(1..5);
	$h->add_path(reverse 1..5);

	my $p = cartesian_product($g, $h);

	ok(matches($p,
		  "1-2,1-6,10-15,11-12,11-16,12-13,12-17,13-14,13-18,14-15,14-19,15-20,16-17,16-21,17-18,17-22,18-19,18-23,19-20,19-24,2-3,2-7,20-25,21-22,22-23,23-24,24-25,3-4,3-8,4-5,4-9,5-10,6-11,6-7,7-12,7-8,8-13,8-9,9-10,9-14",
		  $dir
	));
}
