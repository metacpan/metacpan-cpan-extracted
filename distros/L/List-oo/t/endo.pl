#!/usr/bin/perl

use warnings;
use strict;

use List::oo qw(L);

# better example of dice
sub endo {
	my (@List::oo) = @_;
	my $m = int(@List::oo / 2);
	return(reverse(@List::oo[0..$m-1]), reverse(@List::oo[$m..$#List::oo]));
}

{
my @a = 'a'..'q';
print "before: ",
	L(@a)->map(sub {$_. uc($_).$_})->join('|'), "\n";
print "after:  ",
	L(@a)->map(sub {$_. uc($_).$_})->dice(\&endo)->join('|'), "\n";
}


