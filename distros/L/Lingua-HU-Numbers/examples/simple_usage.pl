#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Lingua::HU::Numbers qw/num2hu num2hu_ordinal/;

# A small example demonstrating a possible use.

sub rnd {
	return int(rand($_[0]));
}

for (reverse 1..99) {
	# Spider hanging on the wall
	my $rand = rnd($_)+1;
	my $ordinal = num2hu_ordinal($rand);
	print "Pők a falon pók, ".num2hu($_)." pók a falon, lecsapunk egyet ami pont $ordinal volt a sorban és marad ".num2hu($_-1)." pók a falon.\n";

}
# No more spiders left on the wall...
print "Nincs több pók a falon...\n";

