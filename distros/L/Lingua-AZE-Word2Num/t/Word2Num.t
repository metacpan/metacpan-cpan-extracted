#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::AZE::Word2Num');
    $tests++;
}

use Lingua::AZE::Word2Num qw(w2n);

my @cases = (
    [ 'sıfır',                              0         ],
    [ 'beş',                                5         ],
    [ 'on bir',                              11        ],
    [ 'iyirmi üç',                           23        ],
    [ 'doxsan doqquz',                       99        ],
    [ 'yüz',                                100       ],
    [ 'yüz bir',                             101       ],
    [ 'iki yüz',                             200       ],
    [ 'yüz iyirmi üç',                       123       ],
    [ 'min',                                 1000      ],
    [ 'min bir',                             1001      ],
    [ 'iki min',                             2000      ],
    [ 'on iki min üç yüz qırx beş',         12_345    ],
    [ 'bir milyon',                          1_000_000 ],
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
