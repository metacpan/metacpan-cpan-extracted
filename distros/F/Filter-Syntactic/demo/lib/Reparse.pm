package Reparse;

use 5.022;
use warnings;

use Filter::Syntactic;

# Replaces (instead of extending) the Block rule, so doesn't match standard blocks...
filter Block
    (  >-\{ (?<CONTENTS> (?&PerlStatementSequence) )  \}-<  )
    { "{$CONTENTS}" }

1; # Magic true value required at end of module

