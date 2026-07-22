use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;
use Font::Metrics;

# STIXGeneral is a math/text OTF font shipped with macOS that has GPOS PairPos
# kerning and no kern table — the ideal test case for the GPOS code path.
my $stix = '/System/Library/Fonts/Supplemental/STIXGeneral.otf';

plan tests => 14;

SKIP: {
    skip 'STIXGeneral.otf not found (macOS only)', 14 unless -f $stix;

    my $f = Font::Metrics->new(file => $stix);
    ok(defined $f, 'STIXGeneral.otf loads');

    # ── basic metrics still work ──────────────────────────────────────────────

    approx_ok($f->char_width('A', 1000),    722, 1.0, 'STIX A width at 1000');
    approx_ok($f->string_width('Hello', 1000), 2222, 2.0, 'STIX "Hello" string width');
    ok($f->ascender(1000) > 0,  'STIX ascender positive');
    ok($f->descender(1000) < 0, 'STIX descender negative');

    # ── GPOS PairPos kern pairs ───────────────────────────────────────────────
    # Values verified from GPOS table (font has no kern table — pure GPOS path)

    approx_ok($f->kern_pair('A', 'V', 1000),  -83, 0.5, 'STIX A V kern (GPOS)');
    approx_ok($f->kern_pair('A', 'W', 1000),  -83, 0.5, 'STIX A W kern (GPOS)');
    approx_ok($f->kern_pair('V', 'A', 1000),  -84, 0.5, 'STIX V A kern (GPOS)');
    approx_ok($f->kern_pair('A', 'T', 1000),  -54, 0.5, 'STIX A T kern (GPOS)');
    approx_ok($f->kern_pair('W', 'A', 1000), -102, 0.5, 'STIX W A kern (GPOS)');
    approx_ok($f->kern_pair('Y', 'a', 1000),  -80, 0.5, 'STIX Y a kern (GPOS)');
    approx_ok($f->kern_pair('T', 'o', 1000),  -32, 0.5, 'STIX T o kern (GPOS)');

    # pair with no kern entry → 0
    approx_ok($f->kern_pair('A', 'A', 1000), 0, 0.001, 'STIX A A no kern');

    # kern scales linearly with size
    approx_ok($f->kern_pair('A', 'V', 12),
              $f->kern_pair('A', 'V', 1000) * 12 / 1000,
              0.05, 'STIX A V kern scales with size');
}

done_testing;
