#!perl

use strict;
use warnings;
use Test::More 0.98;

use Hash::Subset qw(hash_subset hashref_subset);

is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, [qw/b c/])},             {b=>2, c=>3});
is_deeply( hashref_subset({a=>1, b=>2, c=>3}, [qw/b c/]) ,             {b=>2, c=>3});

is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40})}, {b=>2, c=>3});
is_deeply( hashref_subset({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}) , {b=>2, c=>3});

done_testing;
