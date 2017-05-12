#!/usr/bin/env perl

use strict;
use warnings;

use Hash::Fold qw(flatten unflatten fold unfold);
use Test::More tests => 4;

# Different hash and array delimiters
{
    my $nested = {
        baz => {
            a => 'b',
            c => [ 'd', { e => 'f' }, 42 ],
        },
    };

    my $delim = {
        hash_delimiter  => '/',
        array_delimiter => '#',
    };

    my $flattened = flatten($nested, $delim);
    is_deeply $flattened, {
        'baz/a'     => 'b',
        'baz/c#0'   => 'd',
        'baz/c#1/e' => 'f',
        'baz/c#2'   => 42,
    };

    my $roundtrip = unflatten($flattened, $delim);
    is_deeply $roundtrip, $nested;
}

# Different hash and array delimiter, but shared prefix
{
    my $nested = {
        baz => {
            a => 'b',
            c => [ 'd', { e => 'f' }, 42 ],
        },
    };

    my $delim = {
        hash_delimiter  => '/',
        array_delimiter => '/#',
    };

    my $flattened = flatten($nested, $delim);
    is_deeply $flattened, {
        'baz/a'      => 'b',
        'baz/c/#0'   => 'd',
        'baz/c/#1/e' => 'f',
        'baz/c/#2'   => 42,
    };

    my $roundtrip = unflatten($flattened, $delim);
    is_deeply $roundtrip, $nested;
}
