#!perl -w
use strict;
use POSIX; # floor(), log10()
while(<>) {
    s/\b([0-9\.e\+\-]+)\b/round_number($1)/ige;
    print $_;
}

sub round_number { # keeps the first 4 significant digits
    my $nr = shift;
    
    # shift the 1st siginificant digit to the 1st decimal place
    my $order = floor(log10(abs($nr) + 1e-40)) + 1;
    my $shift_factor = 10 ** $order;
    $nr /= $shift_factor;

    # round to 4 decimals
    $nr = floor($nr * 10000 + 0.5) / 10000;
    
    # shift the 1st digit back to its original position
    $nr *= $shift_factor;

    return $nr;
}

