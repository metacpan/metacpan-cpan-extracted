#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::MLT::Num2Word');
    $tests++;
}

use Lingua::MLT::Num2Word qw(num2mlt_cardinal);

my @cases = (
    [  0, "żero"                              ],
    [  1, "wieħed"                            ],
    [  2, "tnejn"                             ],
    [  3, "tlieta"                            ],
    [  5, "ħamsa"                             ],
    [  9, "disgħa"                            ],
    [ 10, "għaxra"                            ],
    [ 11, "ħdax"                              ],
    [ 12, "tnax"                              ],
    [ 13, "tlettax"                           ],
    [ 17, "sbatax"                            ],
    [ 19, "dsatax"                            ],
    [ 20, "għoxrin"                           ],
    [ 23, "tlieta u għoxrin"                  ],
    [ 30, "tletin"                            ],
    [ 40, "erbgħin"                           ],
    [ 50, "ħamsin"                            ],
    [ 78, "tmienja u sebgħin"                 ],
    [ 90, "disgħin"                           ],
    [ 99, "disgħa u disgħin"                  ],
    [100, "mija"                              ],
    [200, "mitejn"                            ],
    [300, "tliet mija"                        ],
    [500, "ħames mija"                        ],
    [101, "mija u wieħed"                     ],
    [245, "mitejn u ħamsa u erbgħin"          ],
);

for my $case (@cases) {
    my ($num, $expected) = @{$case};
    my $result = num2mlt_cardinal($num);
    is($result, $expected, "$num => $expected");
    $tests++;
}

# Test that 0 returns a defined value
my $result = num2mlt_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

# Test capabilities
my $caps = Lingua::MLT::Num2Word->capabilities();
is($caps->{cardinal}, 1, 'capabilities: cardinal supported');
$tests++;
is($caps->{ordinal},  0, 'capabilities: ordinal not supported');
$tests++;

done_testing($tests);
