#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Hash::Fold qw(merge);
use Storable qw(dclone);
use Test::More tests => 9;

sub merge_ok {
    my ($args, $want) = @_;
    my $folder = Hash::Fold->new;
    my $sub_got = merge(@$args);
    my $method_got = $folder->merge(@$args);

    local ($Data::Dumper::Terse, $Data::Dumper::Indent, $Data::Dumper::Sortkeys) = (1, 1, 1);

    # report errors with the caller's line number
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    unless (is_deeply $sub_got, $want) {
        warn 'got (sub): ', Dumper($sub_got), $/;
        warn 'want: ', Dumper($want), $/;
    }

    unless (is_deeply $method_got, $want) {
        warn 'got (method): ', Dumper($method_got), $/;
        warn 'want: ', Dumper($want), $/;
    }
}

# confirm the basics work: merge two disjoint shallow hashes
{
    my $hash1 = {
        1 => 2,
        3 => 4
    };

    my $hash2 = {
        5 => 6,
        7 => 8
    };

    merge_ok [ $hash1, $hash2 ], {
        1 => 2,
        3 => 4,
        5 => 6,
        7 => 8,
    };
}

# where there are conflicts, confirm the rightmost array takes precedence
# (also confirms more than 2 hashes can be merged)
{
    my $hash1 = {
        foo => 1,
        bar => 2,
    };

    my $hash2 = {
        bar  => 3,
        baz  => 4,
    };

    my $hash3 = {
        baz  => 5,
        quux => 6,
    };

    merge_ok [ $hash1, $hash2, $hash3 ], {
        foo  => 1,
        bar  => 3,
        baz  => 5,
        quux => 6,
    };
}

# confirm a sensible value is returned if only one hash is supplied
{
    my $got = {
        foo => [ bar => 42, { baz => 'quux' } ],
        bar => {},
    };

    my $want = dclone($got);

    merge_ok [ $got ], $got;
    merge_ok [ $got ], $want;
    isnt merge($got), $want; # different refs
}
