use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
1
a
b
-2234
-1
0
2
1
3
5
177
END_INPUT

if (prompt -integer, "Enter an integer: ") {
    like $_, qr/^\s*[+-]?\d++\s*/ => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

$_ = 'UNDERBAR';
if (my $input = prompt -i, "Enter another integer: ") {
    like $input, qr/^\s*[+-]?\d++\s*/ => 'Second line retrieved';
    is $_,       'UNDERBAR'           => 'Second line left $_ alone';
}
else {
    fail 'Second line retrieved'; 
}

if (prompt -integer=>'pos odd', "Enter an integer: ") {
    is $_, 1 => 'Constrained line retrieved';
}
else {
    fail 'Constrained line retrieved'; 
}

if (prompt -integer=>qr/7/, "Enter an integer: ") {
    is $_, 177 => 'Constrained line 2 retrieved';
}
else {
    fail 'Constrained line 2 retrieved'; 
}

