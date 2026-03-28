#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::MLT::Word2Num');
    $tests++;
}

use Lingua::MLT::Word2Num qw(w2n);

my @cases = (
    [ "żero",                              0 ],
    [ "xejn",                              0 ],
    [ "wieħed",                            1 ],
    [ "tnejn",                             2 ],
    [ "tlieta",                            3 ],
    [ "ħamsa",                             5 ],
    [ "disgħa",                            9 ],
    [ "għaxra",                           10 ],
    [ "ħdax",                             11 ],
    [ "tnax",                             12 ],
    [ "tlettax",                          13 ],
    [ "sbatax",                           17 ],
    [ "dsatax",                           19 ],
    [ "għoxrin",                          20 ],
    [ "tlieta u għoxrin",                 23 ],
    [ "tletin",                           30 ],
    [ "erbgħin",                          40 ],
    [ "ħamsin",                           50 ],
    [ "tmienja u sebgħin",                78 ],
    [ "disgħin",                          90 ],
    [ "mija",                            100 ],
    [ "mitejn",                          200 ],
    [ "tliet mija",                      300 ],
    [ "ħames mija",                      500 ],
    [ "elf",                            1000 ],
    [ "elfejn",                         2000 ],
    [ "tlitt elef",                     3000 ],
    [ "miljun",                      1000000 ],
);

for my $case (@cases) {
    my ($word, $expected) = @{$case};
    my $result = w2n($word);
    is($result, $expected, "'$word' => $expected");
    $tests++;
}

# Test undef input
my $result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

# Test capabilities
my $caps = Lingua::MLT::Word2Num->capabilities();
is($caps->{cardinal}, 1, 'capabilities: cardinal supported');
$tests++;
is($caps->{ordinal},  0, 'capabilities: ordinal not supported');
$tests++;

done_testing($tests);
