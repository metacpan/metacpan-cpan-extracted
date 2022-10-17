#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Hash::Subset qw(
                       hash_subset
                       hashref_subset
                       hash_subset_without
                       hashref_subset_without

                       merge_hash_subset
                       merge_overwrite_hash_subset
                       merge_ignore_hash_subset
                       merge_hash_subset_without
                       merge_overwrite_hash_subset_without
                       merge_ignore_hash_subset_without
               );

subtest "hash_subset & hashref_subset" => sub {
    is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, [qw/b c/])},             {b=>2, c=>3});
    is_deeply( hashref_subset({a=>1, b=>2, c=>3}, [qw/b c/]) ,             {b=>2, c=>3});

    is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40})}, {b=>2, c=>3});
    is_deeply( hashref_subset({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}) , {b=>2, c=>3});

    is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, qr/[bc]/)}, {b=>2, c=>3});
    is_deeply( hashref_subset({a=>1, b=>2, c=>3}, qr/[bc]/) , {b=>2, c=>3});

    is_deeply({hash_subset   ({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/})}, {b=>2, c=>3});
    is_deeply( hashref_subset({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/}) , {b=>2, c=>3});

    # multiple args
    is_deeply({hash_subset   ({a=>1, b=>2, c=>3, d=>4}, {c=>1}, [qw/b/], qr/cz/, sub {$_[0] =~ /[bd]/})},      {b=>2, c=>3, d=>4});
};

subtest "hash_subset_without & hashref_subset_without" => sub {
    is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, [qw/b c/])},             {a=>1});
    is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, [qw/b c/]) ,             {a=>1});

    is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40})}, {a=>1});
    is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, {b=>20, c=>30, d=>40}) , {a=>1});

    is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, qr/[bcd]/)}, {a=>1});
    is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, qr/[bcd]/) , {a=>1});

    is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/})}, {a=>1});
    is_deeply( hashref_subset_without({a=>1, b=>2, c=>3}, sub {$_[0] =~ /[bcd]/}) , {a=>1});

    # multiple args
    is_deeply({hash_subset_without   ({a=>1, b=>2, c=>3, d=>4}, {c=>1}, [qw/b/], sub {$_[0] =~ /[bcd]/})},      {a=>1});
};

subtest merge_hash_subset => sub {
    my $h1;

    $h1 = {a=>1}; merge_hash_subset($h1, {a=>1, b=>2, c=>3}, [qw/b c/]);
    is_deeply($h1, {a=>1, b=>2, c=>3});

    dies_ok {
        $h1 = {a=>1}; merge_hash_subset($h1, {a=>1, b=>2, c=>3}, [qw/b a/]);
    };
};

subtest merge_hash_subset_without => sub {
    my $h1;

    $h1 = {a=>1}; merge_hash_subset_without($h1, {a=>1, b=>2, c=>3}, [qw/a/]);
    is_deeply($h1, {a=>1, b=>2, c=>3});

    dies_ok {
        $h1 = {a=>1}; merge_hash_subset_without($h1, {a=>1, b=>2, c=>3}, [qw/b/]);
    };
};

subtest merge_overwrite_hash_subset => sub {
    my $h1;

    $h1 = {a=>0}; merge_overwrite_hash_subset($h1, {a=>1, b=>2, c=>3}, [qw/a b/]);
    is_deeply($h1, {a=>1, b=>2});
};

subtest merge_overwrite_hash_subset_without => sub {
    my $h1;

    $h1 = {a=>0}; merge_overwrite_hash_subset_without($h1, {a=>1, b=>2, c=>3}, [qw/b/]);
    is_deeply($h1, {a=>1, c=>3});
};

subtest merge_ignore_hash_subset => sub {
    my $h1;

    $h1 = {a=>0}; merge_ignore_hash_subset($h1, {a=>1, b=>2, c=>3}, [qw/a b/]);
    is_deeply($h1, {a=>0, b=>2});
};

subtest merge_ignore_hash_subset_without => sub {
    my $h1;

    $h1 = {a=>0}; merge_ignore_hash_subset_without($h1, {a=>1, b=>2, c=>3}, [qw/b/]);
    is_deeply($h1, {a=>0, c=>3});
};

done_testing;
