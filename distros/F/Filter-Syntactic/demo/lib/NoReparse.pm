package NoReparse;

use 5.022;
use warnings;

use Filter::Syntactic;

filter Block
    (  >-\{  (?<CONTENTS> (?&PerlStatementSequence) )  \}-<  )
    { "!@#%^&*()}" }

1; # Magic true value required at end of module


