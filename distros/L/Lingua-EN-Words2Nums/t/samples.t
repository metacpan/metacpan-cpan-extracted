#!/usr/bin/perl
use strict;
use Test;

our @samples;
BEGIN {
	open(SAMPLES, "samples") || die "samples: $!";
	@samples=grep { ! /^#/ } <SAMPLES>;
	plan tests => (scalar @samples);
}

use Lingua::EN::Words2Nums;

foreach (@samples) {
	chomp $_;
	my ($num, $text)=split(' ', $_, 2);
	if ($num eq 'undef') {
		ok(! defined words2nums($text));
	}
	else {
		my $w2n = words2nums($text);
		# On win32 platform, exponents semm to have leading zero.
		# This makes it work either way.
		$w2n =~ s/e+0(\d+)/e+$1/;
		ok($w2n, $num);
	}
}
