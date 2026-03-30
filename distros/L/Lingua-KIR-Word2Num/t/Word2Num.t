#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KIR::Word2Num');
    $tests++;
}

use Lingua::KIR::Word2Num qw(w2n);

my @cases = (
    [ 'нөл',                                 0         ],
    [ 'беш',                                 5         ],
    [ 'он бир',                              11        ],
    [ 'жыйырма үч',                         23        ],
    [ 'токсон тогуз',                        99        ],
    [ 'жүз',                                 100       ],
    [ 'жүз бир',                             101       ],
    [ 'эки жүз',                             200       ],
    [ 'жүз жыйырма үч',                     123       ],
    [ 'миң',                                 1000      ],
    [ 'миң бир',                             1001      ],
    [ 'эки миң',                             2000      ],
    [ 'он эки миң үч жүз кырк беш',         12_345    ],
    [ 'бир миллион',                         1_000_000 ],
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
