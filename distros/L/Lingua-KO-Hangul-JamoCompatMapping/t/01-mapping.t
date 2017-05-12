use strict;
use warnings;
use Test::More;

use Lingua::KO::Hangul::JamoCompatMapping qw/jamo_to_compat/;

my @pair_onset = (
    [ "\x{1100}", "\x{3131}", "HANGUL CHOSEONG KIYEOK" ],
    [ "\x{1112}", "\x{314E}", "HANGUL CHOSEONG HIEUH" ],
);

my @pair_nucleus = (
    [ "\x{1161}", "\x{314F}", "HANGUL JUNGSEONG A" ],
    [ "\x{1175}", "\x{3163}", "HANGUL JUNGSEONG I" ],
);

my @pair_coda = (
    [ "\x{11A8}", "\x{3131}", "HANGUL JONGSEONG KIYEOK" ],
    [ "\x{11C2}", "\x{314E}", "HANGUL JONGSEONG HIEUH" ],
);


foreach my $pair ( @pair_onset, @pair_nucleus, @pair_coda ) {
    is( jamo_to_compat($pair->[0]), $pair->[1], $pair->[2] );
}

my @others = (
    [ "\x{10FF}", undef, "out of range" ],
    [ "\x{11C3}", undef, "out of range" ],
);

foreach my $pair ( @others ) {
    is( jamo_to_compat($pair->[0]), $pair->[1], $pair->[2] );
}

done_testing();
