#!perl

use strict;
use warnings;
use Test::More 0.98;

use List::Rank qw(rank rankstr rankby sortrank sortrankstr sortrankby);

subtest rank => sub {
    is_deeply([rank], []);
    is_deeply([rank 10], [1]);
    is_deeply([rank 10,30,20,20], [1,4,"2=","2="]);
};

subtest rankstr => sub {
    is_deeply([rankstr], []);
    is_deeply([rankstr "a"], [1]);
    is_deeply([rankstr "a","c","b","b"], [1,4,"2=","2="]);
};

subtest rankby => sub {
    is_deeply([rankby {length($a) <=> length($b)}], []);
    is_deeply([rankby {length($a) <=> length($b)} "a"], [1]);
    is_deeply([rankby {length($a) <=> length($b)} "apricot","cucumber","banana","banana"], [3,4,"1=","1="]);
};

subtest sortrank => sub {
    is_deeply([sortrank], []);
    is_deeply([sortrank 10], [10,1]);
    is_deeply([sortrank 10,30,20,20], [10,1, 20,"2=",20,"2=", 30,4]);
};

subtest sortrankstr => sub {
    is_deeply([sortrankstr], []);
    is_deeply([sortrankstr "a"], ["a",1]);
    is_deeply([sortrankstr "a","c","b","b"], ["a",1, "b","2=","b","2=", "c",4]);
};

subtest sortrankby => sub {
    is_deeply([sortrankby {length($a) <=> length($b)}], []);
    is_deeply([sortrankby {length($a) <=> length($b)} "a"], ["a",1]);
    is_deeply([sortrankby {length($a) <=> length($b)} "apricot","cucumber","banana","banana"], ["banana","1=", "banana","1=", "apricot",3, "cucumber",4]);
};

done_testing;
