use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Line 2
42
7
Another line
Text
42
7
cat
END_INPUT

if (prompt "Enter line 1", -must => { 'have a 2' => qr/2/ }) {
    is $_, 'Line 2'  => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

if (prompt "Enter line 2", -must => { 'be in [1..10]' => [1..10] }) {
    is $_, '7'  => 'Second line retrieved';
}
else {
    fail 'Second line retrieved'; 
}


if (prompt "Enter line 3", -must => { 'be Text' => ['Text'] }) {
    is $_, 'Text'  => 'Third line retrieved';
}
else {
    fail 'Third line retrieved'; 
}


if (prompt "Enter line 4", -must => { 'Enter 7' => qr/^7$/ }) {
    is $_, '7'  => 'Fourth line retrieved';
}
else {
    fail 'Fourth line retrieved'; 
}


if (prompt "Enter line 5", -must => { 'Woof!' => ['dog'] }) {
    fail 'Last line should fail'; 
}
else {
    pass 'Last line should fail';
}

