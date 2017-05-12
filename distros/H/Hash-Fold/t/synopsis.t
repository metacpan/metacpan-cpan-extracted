#!/usr/bin/env perl

use strict;
use warnings;

use Hash::Fold qw(flatten unflatten fold unfold);
use Test::More tests => 4;

# make sure the example in the synopsis works
{
    my $object = bless { foo => 'bar' };
    my $nested = {
        foo => $object,
        baz => {
            a => 'b',
            c => [ 'd', { e => 'f' }, 42 ],
        },
    };

    my $flattened = flatten($nested);
    is_deeply $flattened, {
        'baz.a'     => 'b',
        'baz.c.0'   => 'd',
        'baz.c.1.e' => 'f',
        'baz.c.2'   => 42,
        'foo'       => $object,
    };

    my $roundtrip = unflatten($flattened);
    is_deeply $roundtrip, $nested;
}

# same again with fold/unfold
{
    my $object = bless { foo => 'bar' };
    my $nested = {
        foo => $object,
        baz => {
            a => 'b',
            c => [ 'd', { e => 'f' }, 42 ],
        },
    };

    my $folded = fold($nested);
    my $roundtrip = unfold($folded);

    is_deeply $folded, {
        'baz.a'     => 'b',
        'baz.c.0'   => 'd',
        'baz.c.1.e' => 'f',
        'baz.c.2'   => 42,
        'foo'       => $object,
    };

    is_deeply $roundtrip, $nested;
}
