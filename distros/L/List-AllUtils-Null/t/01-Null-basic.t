#!perl

use strict;
use warnings;
use Test::More;

use List::AllUtils::Null qw(
    max maxstr min minstr
    sum
);

is_deeply(max(1,2,3,4,5)      , 5);
is_deeply(max(1,2,undef,4,5)  , undef);
is_deeply(maxstr("a","b","c","d","e")      , "e");
is_deeply(maxstr("a","b",undef,"d","e")    , undef);
is_deeply(min(1,2,3,4,5)      , 1);
is_deeply(min(1,2,undef,4,5)  , undef);
is_deeply(minstr("a","b","c","d","e")      , "a");
is_deeply(minstr("a","b",undef,"d","e")    , undef);
is_deeply(sum(1,2,3,4,5)      , 15);
is_deeply(sum(1,2,undef,4,5)  , undef);

done_testing;
