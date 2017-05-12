use strict;
use warnings;
use Test::More 0.89;

use List::Gather;

is sub {
    () = gather {
        return 42;
    };

    return 23;
}->(), 42;

done_testing;
