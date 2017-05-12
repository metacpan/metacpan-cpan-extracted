use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
-1.234e+21
a
b
-.2234
END_INPUT

if (prompt -number, "Enter an integer: ") {
    ok $_ == -1.234e21   => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

$_ = 'UNDERBAR';
if (my $input = prompt -n, "Enter another integer: ") {
    ok $input = -0.2234    => 'Second line retrieved';
    is $_,     'UNDERBAR'          => 'Second line left $_ alone'
}
else {
    fail 'Second line retrieved'; 
}

