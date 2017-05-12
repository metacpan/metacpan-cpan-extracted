use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Line 2
END_INPUT

if (my $input = prompt -verbatim, "Enter line 1") {
    is $input, 'Line 1'  => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

$_ = 'UNDERBAR';
if (my $input = prompt -v, "Enter line 2") {
    is $input, 'Line 2'   => 'Second line retrieved';
    is $_,     'UNDERBAR' => 'Second line left $_ alone'
}
else {
    fail 'Second line retrieved'; 
}

if (my $input = prompt -v, "Enter line 3") {
    fail 'undef on failure (unexpectedly got "$input")'; 
}
else {
    ok !defined $input  => 'undef on failure';
}
