use strict;
use Test::More 0.98;

use JSON5;

my $payload = <<'__JSON5__';
{
    foo: 'bar',
    while: true,

    this: 'is a \
multi-line string',

    // this is an inline comment
    here: 'is another', // inline comment

    /* this is a block comment
       that continues on another line */

    hex: 0xDEADbeef,
    half: .5,
    delta: +10,
    to: Infinity,   // and beyond!

    finally: 'a trailing comma',
    oh: [
        "we shouldn't forget",
        'arrays can have',
        'trailing commas too',
    ],
}
__JSON5__
my $expected = {
    foo     => 'bar',
    while   => JSON5::true,
    this    => 'is a multi-line string',
    here    => 'is another',
    hex     => 3735928559,
    half    => 0.5,
    delta   => +10,
    to      => 0+'Inf',
    finally => 'a trailing comma',
    oh      => [
        "we shouldn't forget",
        'arrays can have',
        'trailing commas too',
    ],
};

is_deeply+ decode_json5($payload), $expected, 'decode_json5';
is_deeply+ JSON5->new->decode($payload), $expected, 'JSON5->new->decode';

done_testing;

