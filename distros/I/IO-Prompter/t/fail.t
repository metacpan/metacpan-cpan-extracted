use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Loser!
42
END_INPUT

if (prompt -fail=>'Loser!', "Enter line 1") {
    is $_, 'Line 1'  => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

if (prompt -fail=>'Loser!', "Enter line 2") {
    fail 'Failure condition met'; 
}
else {
    pass 'Failure condition met'; 
    ok !$_ => 'Correctly returned false';
}

if (prompt -fail=>[41..43] , "Enter line 2") {
    fail 'Second failure condition met'; 
}
else {
    pass 'Second failure condition met'; 
    ok !$_ => 'Correctly returned false';
}


