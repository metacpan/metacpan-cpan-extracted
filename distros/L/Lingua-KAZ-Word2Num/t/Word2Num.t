#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KAZ::Word2Num');
    $tests++;
}

use Lingua::KAZ::Word2Num qw(w2n);

my @cases = (
    [ 'нөл',                                 0         ],
    [ 'бес',                                 5         ],
    [ 'он бір',                              11        ],
    [ 'жиырма үш',                          23        ],
    [ 'тоқсан тоғыз',                       99        ],
    [ 'жүз',                                 100       ],
    [ 'жүз бір',                             101       ],
    [ 'екі жүз',                             200       ],
    [ 'жүз жиырма үш',                      123       ],
    [ 'мың',                                 1000      ],
    [ 'мың бір',                             1001      ],
    [ 'екі мың',                             2000      ],
    [ 'он екі мың үш жүз қырық бес',        12_345    ],
    [ 'бір миллион',                         1_000_000 ],
);

for my $case (@cases) {
    my ($text, $expected) = @$case;
    my $result = w2n($text);
    is($result, $expected, "'$text' => $expected");
    $tests++;
}

# undef input
my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
