#!/usr/bin/perl

use warnings;
use strict;

use Math::Round::Var;
use Math::Round qw(nearest);

use Benchmark qw(:all);
my @nums = (
	1.4445,
	1.27,
	1.88884567,
	);
my @prec = (
	1,
	0.1,
	0.01,
	0.001,
	0.00001,
	);

foreach my $num (@nums) {
	foreach my $pre (@prec) {
	my $r = Math::Round::Var->new($pre);
		print "$num at $pre\n";
		my $subs = {
			'M::R::Var  ' => sub {
				$r->round($num);
				},
			'Math::Round' => sub {
				nearest($pre, $num);
				},
			};
		my @res;
		foreach my $k (keys(%$subs)) {
			my $v = $subs->{$k}->();
			push(@res, $v);
			print "$k $v\n";
		}
		($res[0] == $res[1]) or print " "x16, "== FALSE!\n";
		($res[0] eq $res[1]) or print " "x16, "eq FALSE!\n";
		if(0) {
			my $results = timethese(100_000, $subs);
			cmpthese($results);
		}
		elsif(1) {
			cmpthese(-1, $subs);
		}
		else {
		}
		print "\n";
	}
}
