######################################################################
#
# t/9040_roundtrip_invariant.t - encoding round-trip invariants
#
# For a small corpus that covers hiragana, katakana, kanji, fullwidth
# forms, halfwidth katakana and punctuation, verify that converting the
# corpus from any supported encoding X to any encoding Y and back to X
# reproduces the original X bytes exactly, for every ordered pair
# (X, Y) drawn from jis / euc / sjis / utf8.
#
# This catches regressions in the conversion tables or in the escape-
# sequence handling that a one-directional test could miss.
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }
use warnings;
use FindBin;

require "$FindBin::Bin/../lib/jacode.pl";
jacode::init();

# Corpus given as UTF-8 byte strings. Each entry round-trips cleanly
# across all four encodings (no lossy mappings are included here).
my @corpus = (
    [ "\xe3\x81\x82", 'HIRAGANA A'       ],
    [ "\xe3\x81\x84", 'HIRAGANA I'       ],
    [ "\xe3\x82\x93", 'HIRAGANA N'       ],
    [ "\xe3\x82\xa2", 'KATAKANA A'       ],
    [ "\xe3\x82\xab", 'KATAKANA KA'      ],
    [ "\xe3\x83\xb3", 'KATAKANA N'       ],
    [ "\xe6\x97\xa5", 'KANJI NICHI'      ],
    [ "\xe6\x9c\xac", 'KANJI HON'        ],
    [ "\xe8\xaa\x9e", 'KANJI GO'         ],
    [ "\xef\xbc\xa1", 'FULLWIDTH A'      ],
    [ "\xef\xbc\x91", 'FULLWIDTH 1'      ],
    [ "\xef\xbd\xb1", 'HALFWIDTH KANA A' ],
    [ "\xef\xbd\xb6", 'HALFWIDTH KANA KA'],
    [ "\xef\xbe\x9d", 'HALFWIDTH KANA N' ],
    [ "\xe2\x98\x86", 'WHITE STAR'       ],
    [ "\xe3\x80\x82", 'IDEOGRAPHIC FULL STOP' ],
    [ "\xe3\x80\x81", 'IDEOGRAPHIC COMMA' ],
);

my @enc = qw(jis euc sjis utf8);

my $tno = 0;
sub ok {
    my ($pass, $name) = @_;
    $tno++;
    print $pass ? "ok $tno" : "not ok $tno";
    print " - $name" if defined $name;
    print "\n";
}

# One test per (char, X, Y): X -> Y -> X must equal the X form.
# (Each "for my" iteration gets a fresh lexical, so the closures below
#  capture the correct per-iteration value.)
my @tests = ();
for my $entry (@corpus) {
    my $utf8  = $entry->[0];
    my $label = $entry->[1];
    for my $x (@enc) {
        for my $y (@enc) {
            push @tests, sub {
                my $src  = jacode::to($x, $utf8, 'utf8');
                my $mid  = jacode::to($y, $src, $x);
                my $back = jacode::to($x, $mid, $y);
                ok(
                    $back eq $src,
                    "$label: $x -> $y -> $x"
                    . (($back eq $src)
                        ? ''
                        : ' got=' . unpack('H*', $back)
                        . ' want=' . unpack('H*', $src))
                );
            };
        }
    }
}

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

__END__
