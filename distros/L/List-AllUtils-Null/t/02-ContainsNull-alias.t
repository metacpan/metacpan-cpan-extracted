#!perl

use strict;
use warnings;
use Test::More;

use List::Util::ContainsNull qw(
    max maxstr min minstr
    sum
);

# copy-pasted from 01-ContainsNull-basic.t:

is_deeply([max()               ], [undef,0]);
is_deeply([max(1,2,3,4,5)      ], [5,0]);
is_deeply([max(1,2,undef,4,5)  ], [5,1]);
is_deeply([max(undef)          ], [undef,1]);
is_deeply([max(undef,undef)    ], [undef,1]);

is_deeply([maxstr()            ], [undef,0]);
is_deeply([maxstr("a","b","c","d","e")      ], ["e",0]);
is_deeply([maxstr("a","b",undef,"d","e")    ], ["e",1]);
is_deeply([maxstr(undef)       ], [undef,1]);
is_deeply([maxstr(undef,undef) ], [undef,1]);

is_deeply([min()               ], [undef,0]);
is_deeply([min(1,2,3,4,5)      ], [1,0]);
is_deeply([min(1,2,undef,4,5)  ], [1,1]);
is_deeply([min(undef)          ], [undef,1]);
is_deeply([min(undef,undef)    ], [undef,1]);

is_deeply([minstr()            ], [undef,0]);
is_deeply([minstr("a","b","c","d","e")      ], ["a",0]);
is_deeply([minstr("a","b",undef,"d","e")    ], ["a",1]);
is_deeply([minstr(undef)       ], [undef,1]);
is_deeply([minstr(undef,undef) ], [undef,1]);

is_deeply([sum()               ], [undef,0]);
is_deeply([sum(1,2,3,4,5)      ], [15,0]);
is_deeply([sum(1,2,undef,4,5)  ], [12,1]);
is_deeply([sum(undef)          ], [undef,1]);
is_deeply([sum(undef,undef)    ], [undef,1]);

done_testing;
