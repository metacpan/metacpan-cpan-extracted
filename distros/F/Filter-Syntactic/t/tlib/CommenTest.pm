package CommenTest;

use 5.022;
use warnings;

use Filter::Syntactic -debug;

filter PerlComment :extend
    ( [#]{3} (?<DESC> [^:]*+ )  :  (?<TEST> [^\n]*+ ) )
    { qq{ok $TEST => qq{$DESC};} }

1; # Magic true value required at end of module


