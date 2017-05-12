use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
N
Y
z

EX
END_INPUT

if (prompt "(y)o or ba(z)", -keyletters) {
    is $_, 'Y'  => 'First keyletter retrieved';
}
else {
    fail 'First keyletter retrieved'; 
}


if (prompt "e(y)e or (z)en", -keylets) {
    is $_, 'z'  => 'Second keyletter retrieved';
}
else {
    fail 'Second keyletter retrieved'; 
}



if (prompt "(ex)it, [y]up or (z)en", -key) {
    is $_, 'y'  => 'Default keyletter retrieved';
}
else {
    fail 'Default keyletter retrieved'; 
}

if (prompt "(ex)it, [y]up or (z)en", -_k) {
    is $_, 'EX'  => 'Multi-character keyletter retrieved';
}
else {
    fail 'Multi-character keyletter retrieved'; 
}


