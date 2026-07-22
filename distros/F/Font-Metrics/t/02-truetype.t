use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;
use Font::Metrics;

my $ttf = 't/TrebuchetMS.ttf';
unless (-f $ttf) {
    plan skip_all => "TrebuchetMS.ttf not present in t/";
    exit 0;
}

plan tests => 25;

my $f = Font::Metrics->new(file => $ttf);
ok(defined $f, 'TrueType font loaded');

# ── char_width ────────────────────────────────────────────────────────────────
# Trebuchet MS, 2048 UPE; widths computed as advance_units/2048*size
approx_ok($f->char_width(' ', 1000),  301.27, 0.5, 'space width at 1000');
approx_ok($f->char_width('A', 1000),  589.84, 0.5, 'A width at 1000');
approx_ok($f->char_width('H', 1000),  654.30, 0.5, 'H width at 1000');
approx_ok($f->char_width('e', 1000),  545.41, 0.5, 'e width at 1000');
approx_ok($f->char_width('l', 1000),  294.92, 0.5, 'l width at 1000');

# scale linearly
approx_ok($f->char_width('A', 12), 12 * 589.84 / 1000, 0.05, 'A at 12pt scales');

# ── string_width ──────────────────────────────────────────────────────────────
# "Hello" = H+e+l+l+o widths
approx_ok($f->string_width('Hello', 1000), 2326.17, 1.0, '"Hello" string width');
approx_ok($f->string_width('',     1000),     0,    0.001, 'empty string width');

# string_width = sum of char_widths
{
    my $sum = 0;
    $sum += $f->char_width($_, 1000) for split //, 'Test';
    approx_ok($f->string_width('Test', 1000), $sum, 0.01, 'string_width = sum of chars');
}

# ── ascender / descender / line_height ────────────────────────────────────────
# hhea: ascender=1923, descender=-455, UPE=2048
approx_ok($f->ascender(1000),    938.96, 0.5, 'ascender at 1000');
approx_ok($f->descender(1000),  -222.17, 0.5, 'descender at 1000');
approx_ok($f->line_height(1000), 1161.13, 1.0, 'line_height = asc - desc');

# cap_height: v1 OS/2 falls back to sTypoAscender=1510/2048*1000
approx_ok($f->cap_height(1000),  737.30, 1.0, 'cap_height (sTypoAscender fallback)');

# scale linearly
approx_ok($f->ascender(12), 12 * 938.96 / 1000, 0.05, 'ascender at 12pt scales');

# ── kern_pair ────────────────────────────────────────────────────────────────
# Values from kern table (FUnits/UPE*size):
# A(glyph 36)+V(glyph 57)=-180 FUnits  → -180/2048*1000=-87.89
# A(glyph 36)+T(glyph 55)=-199 FUnits  → -199/2048*1000=-97.17
# V(glyph 57)+A(glyph 36)=-209 FUnits  → -209/2048*1000=-102.05
approx_ok($f->kern_pair('A','V',1000),  -87.89, 0.5, 'A V kern at 1000');
approx_ok($f->kern_pair('A','T',1000),  -97.17, 0.5, 'A T kern at 1000');
approx_ok($f->kern_pair('V','A',1000), -102.05, 0.5, 'V A kern at 1000');

# pairs not in table → 0
approx_ok($f->kern_pair('A','A',1000),    0, 0.001, 'A A no kern');
approx_ok($f->kern_pair('e','e',1000),    0, 0.001, 'e e no kern');

# kern scales with size
approx_ok($f->kern_pair('A','V',12), 12 * -87.89 / 1000, 0.05, 'A V kern at 12pt scales');

# ── error handling ────────────────────────────────────────────────────────────
eval { Font::Metrics->new(file => '/nonexistent/font.ttf') };
ok($@, 'croaks on missing file');

# ── multiple instances ────────────────────────────────────────────────────────
my $f2 = Font::Metrics->new(file => $ttf);
approx_ok($f2->char_width('A', 1000), 589.84, 0.5, 'second instance loads correctly');

# Std14 and TT can coexist
my $hv = Font::Metrics->new(name => 'Helvetica');
approx_ok($hv->char_width('A', 1000),  667, 0.5, 'Helvetica still works alongside TT');
approx_ok($hv->kern_pair('A','V',1000), -80, 0.5, 'Helvetica kern still works');
