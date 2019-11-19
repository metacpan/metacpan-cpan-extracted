#!perl

use strict;
use warnings;
use Test::More 0.98;

use Hash::Subset qw(
                       hash_subset
                       hashref_subset
                       hash_subset_without
                       hashref_subset_without
               );

is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, [qw/b c/])},             {b=>2, c=>3});
is_deeply( hashref_subset({a=>1, b=>2, c=>3}, [qw/b c/]) ,             {b=>2, c=>3});

is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40})}, {b=>2, c=>3});
is_deeply( hashref_subset({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}) , {b=>2, c=>3});

is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/})}, {b=>2, c=>3});
is_deeply( hashref_subset({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/}) , {b=>2, c=>3});


is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, [qw/b c/])},             {a=>1});
is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, [qw/b c/]) ,             {a=>1});

is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40})}, {a=>1});
is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}) , {a=>1});

is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/})}, {a=>1});
is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/}) , {a=>1});

done_testing;
