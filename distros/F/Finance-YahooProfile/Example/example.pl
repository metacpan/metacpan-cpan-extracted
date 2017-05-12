#!c:\perl\bin\perl

use strict;
use Finance::YahooProfile;

print "Usage: $0 symbol [symbol ...]" && exit if $#ARGV == -1;

my $qd = new Finance::YahooProfile (expand => 1);

my @sym = @ARGV;
my @res = $qd->profile( s => [@sym]);

for my $s (@res) {
    print "Symbol: $s->{'symbol'}\n";
    for (sort keys %$s) {
	print "\t '$_' => '$s->{$_}'\n";
    }
}
