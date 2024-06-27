package Nested;

use 5.022;
use warnings;

use Filter::Syntactic;

filter Block :extend
    ( \{\{ (?<BLOCK> (?>(?&PerlBlock)) ) \}\} )
    { "{ warn 'Entering block $_{ORD}';
         defer { warn 'Leaving block $_{ORD}' }
         $BLOCK
       }" }


1; # Magic true value required at end of module
