#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;
use Font::Metrics;

plan tests => 70;

my $hv = Font::Metrics->new(name => 'Helvetica');
my $hb = Font::Metrics->new(name => 'Helvetica-Bold');
my $tr = Font::Metrics->new(name => 'Times-Roman');
my $tb = Font::Metrics->new(name => 'Times-Bold');
my $ti = Font::Metrics->new(name => 'Times-Italic');
my $cr = Font::Metrics->new(name => 'Courier');

ok(defined $hv, 'Helvetica loaded');
ok(defined $hb, 'Helvetica-Bold loaded');
ok(defined $tr, 'Times-Roman loaded');
ok(defined $tb, 'Times-Bold loaded');
ok(defined $cr, 'Courier loaded');

# ── char_width ──────────────────────────────────────────────────────────────
# Helvetica space=278, A=667, M=778
approx_ok($hv->char_width(' ', 1000),  278, 0.5, 'Hv space width at 1000');
approx_ok($hv->char_width('A', 1000),  667, 0.5, 'Hv A width at 1000');
approx_ok($hv->char_width('M', 1000),  833, 0.5, 'Hv M width at 1000');

# Courier is fixed-pitch: everything is 600
approx_ok($cr->char_width('A', 1000),  600, 0.5, 'Cr A width at 1000');
approx_ok($cr->char_width('i', 1000),  600, 0.5, 'Cr i width at 1000');

# Times-Roman: A=722, space=250
approx_ok($tr->char_width('A', 1000),  722, 0.5, 'Tr A width at 1000');
approx_ok($tr->char_width(' ', 1000),  250, 0.5, 'Tr space width at 1000');

# scale linearly
approx_ok($hv->char_width('A', 12), 12 * 667 / 1000, 0.01, 'Hv A at 12pt scales');
approx_ok($tr->char_width('A',  9),  9 * 722 / 1000, 0.01, 'Tr A at 9pt scales');

# ── string_width ─────────────────────────────────────────────────────────────
# "Hi" in Helvetica: H=722 i=222 → 944
approx_ok($hv->string_width('Hi', 1000), 722 + 222, 0.5, 'Hv "Hi" width');
# Empty string → 0
approx_ok($hv->string_width('', 1000), 0, 0.001, 'empty string width');

# ── ascender / descender / cap_height / x_height / line_height ──────────────
# Helvetica: ascender=718, descender=-207, cap_height=718, x_height=523
approx_ok($hv->ascender(1000),    718, 0.5, 'Hv ascender');
approx_ok($hv->descender(1000),  -207, 0.5, 'Hv descender');
approx_ok($hv->cap_height(1000),  718, 0.5, 'Hv cap_height');
approx_ok($hv->x_height(1000),    523, 0.5, 'Hv x_height');
approx_ok($hv->line_height(1000), 718 + 207, 0.5, 'Hv line_height = asc - desc');

# Helvetica-Bold: ascender=718, descender=-207, cap_height=718, x_height=532
approx_ok($hb->ascender(1000),    718, 0.5, 'HvBold ascender');
approx_ok($hb->x_height(1000),    532, 0.5, 'HvBold x_height');

# Times-Roman: ascender=683, descender=-217, cap_height=662, x_height=450
approx_ok($tr->ascender(1000),    683, 0.5, 'Tr ascender');
approx_ok($tr->descender(1000),  -217, 0.5, 'Tr descender');
approx_ok($tr->cap_height(1000),  662, 0.5, 'Tr cap_height');
approx_ok($tr->x_height(1000),    450, 0.5, 'Tr x_height');
approx_ok($tr->line_height(1000), 683 + 217, 0.5, 'Tr line_height');

# Times-Bold: ascender=683, descender=-217
approx_ok($tb->ascender(1000),    683, 0.5, 'TrBold ascender');
approx_ok($tb->descender(1000),  -217, 0.5, 'TrBold descender');

# Courier: ascender=629, descender=-157
approx_ok($cr->ascender(1000),    629, 0.5, 'Cr ascender');
approx_ok($cr->descender(1000),  -157, 0.5, 'Cr descender');

# metrics scale linearly
approx_ok($hv->ascender(12), 12 * 718 / 1000, 0.01, 'Hv ascender at 12pt');

# ── kern_pair ────────────────────────────────────────────────────────────────
# Helvetica: A→V = -80, A→W = -80, Y→A = -80
approx_ok($hv->kern_pair('A','V',1000),  -80,  0.5, 'Hv A V kern');
approx_ok($hv->kern_pair('A','W',1000),  -80,  0.5, 'Hv A W kern');
approx_ok($hv->kern_pair('A','Y',1000),  -80,  0.5, 'Hv A Y kern');
approx_ok($hv->kern_pair('T','A',1000),  -60,  0.5, 'Hv T A kern');
approx_ok($hv->kern_pair('T','a',1000),  -80,  0.5, 'Hv T a kern');
approx_ok($hv->kern_pair('T',',',1000),  -80,  0.5, 'Hv T comma kern');
approx_ok($hv->kern_pair('V',',',1000),  -80,  0.5, 'Hv V comma kern');
approx_ok($hv->kern_pair('Y',',',1000), -100,  0.5, 'Hv Y comma kern');
approx_ok($hv->kern_pair('P',',',1000), -120,  0.5, 'Hv P comma kern');
approx_ok($hv->kern_pair('P','A',1000), -100,  0.5, 'Hv P A kern');
approx_ok($hv->kern_pair('L','T',1000),  -60,  0.5, 'Hv L T kern');
approx_ok($hv->kern_pair('W','a',1000),  -40,  0.5, 'Hv W a kern');
approx_ok($hv->kern_pair('J','a',1000),  -20,  0.5, 'Hv J a kern');

# Pair that has no kerning → 0
approx_ok($hv->kern_pair('A','A',1000),    0, 0.001, 'Hv A A no kern');
approx_ok($hv->kern_pair('a','v',1000),    0, 0.001, 'Hv a v no kern');

# Kern scales with size
approx_ok($hv->kern_pair('A','V',12), 12 * -80 / 1000, 0.01, 'Hv A V kern at 12pt');

# Times-Roman kern pairs
approx_ok($tr->kern_pair('A','V',1000), -135,  0.5, 'Tr A V kern');
approx_ok($tr->kern_pair('A','W',1000),  -90,  0.5, 'Tr A W kern');
approx_ok($tr->kern_pair('A','Y',1000), -140,  0.5, 'Tr A Y kern');
approx_ok($tr->kern_pair('A','T',1000),  -80,  0.5, 'Tr A T kern');
approx_ok($tr->kern_pair('T','a',1000), -100,  0.5, 'Tr T a kern');
approx_ok($tr->kern_pair('V','.',1000), -111,  0.5, 'Tr V period kern');
approx_ok($tr->kern_pair('W','.',1000),  -92,  0.5, 'Tr W period kern');
approx_ok($tr->kern_pair('Y','.',1000), -111,  0.5, 'Tr Y period kern');
approx_ok($tr->kern_pair('r',',',1000),  -25,  0.5, 'Tr r comma kern');
approx_ok($tr->kern_pair('r','.',1000),  -25,  0.5, 'Tr r period kern');
approx_ok($tr->kern_pair('L','V',1000), -100,  0.5, 'Tr L V kern');
approx_ok($tr->kern_pair('D','A',1000),  -35,  0.5, 'Tr D A kern');
approx_ok($tr->kern_pair('O','V',1000),  -50,  0.5, 'Tr O V kern');
approx_ok($tr->kern_pair('P','.',1000), -110,  0.5, 'Tr P period kern');

# Pair absent in Times → 0
approx_ok($tr->kern_pair('A','A',1000),    0, 0.001, 'Tr A A no kern');

# Times Bold shares same kern data
approx_ok($tb->kern_pair('A','V',1000), -135, 0.5, 'TrBold A V kern same data');

# Times Italic shares same kern data
approx_ok($ti->kern_pair('V','.',1000), -111, 0.5, 'TrItalic V period kern same data');

# Courier has no kern pairs
approx_ok($cr->kern_pair('T','A',1000), 0, 0.001, 'Cr T A no kern');
approx_ok($cr->kern_pair('A','V',1000), 0, 0.001, 'Cr A V no kern');

# unknown font name croaks
eval { Font::Metrics->new(name => 'NotAFont') };
ok($@, 'croaks on unknown font name');

# error on no args
eval { Font::Metrics->new() };
ok($@, 'croaks when no name or file given');
