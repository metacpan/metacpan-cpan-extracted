use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
N
Y
z

ex
END_INPUT

if (prompt "(y)o or ba(z)", -guarantee=>qr/[yz]/i) {
    is $_, 'Y'  => 'First guaranteed input retrieved';
}
else {
    fail 'First guaranteed input retrieved'; 
}


if (prompt "e(y)e or (z)en", -gaurenty=>['y','z']) {
    is $_, 'z'  => 'Second guaranteed input retrieved';
}
else {
    fail 'Second guaranteed input retrieved'; 
}



if (prompt "(ex)it, [y]up or (z)en", -g=>{ex=>1, y=>1, z=>1}, -dy) {
    is $_, 'y'  => 'Default guaranteed input retrieved';
}
else {
    fail 'Default guaranteed input retrieved'; 
}

if (prompt "(ex)it, [y]up or (z)en", -g=>{ex=>1, y=>1, z=>1}) {
    is $_, 'ex'  => 'Multi-character guaranteed input retrieved';
}
else {
    fail 'Multi-character guaranteed input retrieved'; 
}


