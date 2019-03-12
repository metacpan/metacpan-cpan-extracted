#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Hash::Fold qw(merge);
use Storable qw(dclone);
use Test::Fatal;
use Test::More tests => 10;

sub merge_ok {
    my ($args, $want) = @_;
    my $folder = Hash::Fold->new;
    my $sub_got = merge(@$args);
    my $method_got = $folder->merge(@$args);

    local (
        $Data::Dumper::Terse,
        $Data::Dumper::Indent,
        $Data::Dumper::Sortkeys
    ) = (1, 1, 1);

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

# where there are conflicts, confirm the rightmost array takes precedence (also
# confirms more than 2 hashes can be merged)
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

# nice error message if merging incompatible structures
subtest 'incompatible structures' => sub {
    # check single path component and multiple components separately
    # to make sure there's no off-by-one error.

    my $test = sub {
        my ($component, $array, $scalar, $hash) = @_;
        like(
            exception { merge($array, $scalar) },
                qr/attempt to use non-array \($component\) as an array/i, 'array on scalar'
        );

        like(
            exception { merge($scalar, $array) },
                qr/attempt to use non-array \($component\) as an array/i, 'scalar on array'
        );

        like(
            exception { merge($scalar, $hash) },
                qr/attempt to use non-hash \($component\) as a hash/i, 'scalar on hash'
        );

        like(
            exception { merge($hash, $scalar) },
                qr/attempt to use non-hash \($component\) as a hash/i, 'hash on scalar'
        );

        like(
            exception { merge($hash, $array) },
                qr/attempt to use non-hash \($component\) as a hash/i, 'hash on array'
        );

        like(
            exception { merge($array, $hash) },
                qr/attempt to use non-hash \($component\) as a hash/i, 'array on hash'
        );
    };

    subtest 'single path component' => $test, 'foo',
        { foo => [ 'a', 'b', 'c' ], },
        { foo => 3, },
        { foo => { a => 1 } };

    subtest 'multiple path components, hash' => $test, 'foo.a',
        { foo => { a => [ 'a', 'b', 'c' ] }, },
        { foo => { a => 3 }, },
        { foo => { a => { b => 1 } } };

    subtest 'multiple path components, array ' => $test, 'foo.0',
        { foo => [ [ 'a', 'b', 'c' ] ], },
        { foo => [ 3 ], },
        { foo => [ { b => 1 } ] };

};
