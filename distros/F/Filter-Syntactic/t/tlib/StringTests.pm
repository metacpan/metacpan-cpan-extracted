package StringTests;

use 5.022;
use warnings;

use Filter::Syntactic;

filter String { "pass $_" }

1; # Magic true value required at end of module
