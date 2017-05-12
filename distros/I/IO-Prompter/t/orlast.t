use 5.010;
use warnings;
use Test::More tests=>2;

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Line 2
Line 3
END_INPUT

while (1) {
    my $l1 = prompt "Enter line 1" or last;
    my $l2 = prompt "Enter line 2" or last;
    is $l1, 'Line 1'  => 'First line retrieved';
    is $l2, 'Line 2'  => 'Second line retrieved';
}

