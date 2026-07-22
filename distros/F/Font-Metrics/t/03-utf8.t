use 5.008003;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test2::Bundle::Numerical;
use Font::Metrics;

plan tests => 25;

my $hv = Font::Metrics->new(name => 'Helvetica');

# ── char_width: UTF-8 Perl string vs Latin-1 byte string ─────────────────────
# chr(0xE9) with use utf8 -> SvUTF8 set, UTF-8 bytes \xC3\xA9
# "\xE9"                  -> SvUTF8 clear, single byte 0xE9
# Both must decode to codepoint U+00E9 and return the same width.

approx_ok($hv->char_width("\x{E9}", 1000),
          $hv->char_width("\xE9",   1000),
          0.001, 'Hv char_width: U+00E9 UTF-8 string == Latin-1 byte');

approx_ok($hv->char_width("\x{FC}", 1000),
          $hv->char_width("\xFC",   1000),
          0.001, 'Hv char_width: U+00FC UTF-8 string == Latin-1 byte');

approx_ok($hv->char_width("\x{E0}", 1000),
          $hv->char_width("\xE0",   1000),
          0.001, 'Hv char_width: U+00E0 UTF-8 string == Latin-1 byte');

# ── char_width: codepoint > 0xFF returns 0 for Std14 (no AFM data) ───────────

approx_ok($hv->char_width("\x{100}",  1000), 0, 0.001, 'Hv char_width: U+0100 -> 0 (above Std14 range)');
approx_ok($hv->char_width("\x{20AC}", 1000), 0, 0.001, 'Hv char_width: U+20AC -> 0 (above Std14 range)');

# ── string_width: UTF-8 string == sum of per-char widths ─────────────────────

{
    my $w_utf8 = $hv->string_width("caf\x{E9}", 1000);
    my $w_sum  = $hv->string_width("caf", 1000) + $hv->char_width("é", 1000);
    approx_ok($w_utf8, $w_sum, 0.01, 'Hv string_width UTF-8 "cafe+U+00E9" == sum of parts');
}

# ── string_width: UTF-8 string == Latin-1 byte string (Latin-1 range) ────────

approx_ok($hv->string_width("caf\x{E9}", 1000),
          $hv->string_width("café",   1000),
          0.01, 'Hv string_width "cafe+U+00E9": UTF-8 == Latin-1 bytes');

# Two Latin-1 Unicode chars in a row

{
    my $w_utf8 = $hv->string_width("\x{E9}\x{FC}", 1000);
    my $w_sum  = $hv->char_width("\xE9", 1000) + $hv->char_width("\xFC", 1000);
    approx_ok($w_utf8, $w_sum, 0.01, 'Hv string_width "U+00E9 U+00FC" UTF-8 == sum');
}

# 3-byte UTF-8 sequence (U+2014 em-dash) -> codepoint > 0xFF -> contributes 0

{
    my $w    = $hv->string_width("a\x{2014}b", 1000);
    my $w_ab = $hv->string_width("ab", 1000);
    approx_ok($w, $w_ab, 0.01, 'Hv string_width: U+2014 (em-dash) contributes 0 in Std14');
}

# ASCII is unchanged

approx_ok($hv->string_width("Hello", 1000),
          $hv->string_width("Hello", 1000),
          0.001, 'Hv ASCII string_width unchanged');

# Empty UTF-8 string

approx_ok($hv->string_width("", 1000), 0, 0.001, 'Hv empty string -> 0');

# ── Times-Roman Latin-1 range ─────────────────────────────────────────────────

{
    my $tr = Font::Metrics->new(name => 'Times-Roman');

    approx_ok($tr->char_width("\x{E9}", 1000),
              $tr->char_width("\xE9",   1000),
              0.001, 'Tr char_width: U+00E9 UTF-8 == Latin-1 byte');

    my $w = $tr->string_width("r\x{E9}sum\x{E9}", 1000);
    my $e = $tr->string_width("r\xE9sum\xE9",     1000);
    approx_ok($w, $e, 0.01, 'Tr string_width "r+U+00E9+sum+U+00E9": UTF-8 == Latin-1 bytes');
}

# ── TrueType (Trebuchet MS) ───────────────────────────────────────────────────

my $ttf = 't/TrebuchetMS.ttf';
SKIP: {
    skip 'TrebuchetMS.ttf not present in t/', 12 unless -f $ttf;

    my $f = Font::Metrics->new(file => $ttf);

    # char_width: UTF-8 U+00E9 == byte 0xE9 codepoint

    approx_ok($f->char_width("\x{E9}", 1000),
              $f->char_width("\xE9",   1000),
              0.001, 'TT char_width: U+00E9 UTF-8 == byte (same codepoint)');

    ok($f->char_width("\x{E9}", 1000) > 0, 'TT U+00E9 has non-zero width');
    ok($f->char_width("\x{FC}", 1000) > 0, 'TT U+00FC has non-zero width');

    # string_width UTF-8 == sum of parts

    {
        my $w = $f->string_width("caf\x{E9}", 1000);
        my $e = $f->string_width("caf", 1000) + $f->char_width("\x{E9}", 1000);
        approx_ok($w, $e, 0.01, 'TT string_width "cafe+U+00E9" UTF-8 == sum');
    }

    # string_width UTF-8 == Latin-1 byte string (Latin-1 range)

    approx_ok($f->string_width("caf\x{E9}", 1000),
              $f->string_width("caf\xE9",   1000),
              0.01, 'TT string_width "cafe+U+00E9": UTF-8 == Latin-1 bytes');

    # Two accented chars

    {
        my $w = $f->string_width("\x{E9}\x{FC}", 1000);
        my $e = $f->char_width("\x{E9}", 1000) + $f->char_width("\x{FC}", 1000);
        approx_ok($w, $e, 0.01, 'TT string_width "U+00E9 U+00FC" UTF-8 == sum');
    }

    # 3-byte UTF-8: U+20AC euro sign (Trebuchet supports it)

    ok($f->char_width("\x{20AC}", 1000) > 0, 'TT U+20AC (euro, 3-byte UTF-8) has non-zero width');

    {
        my $euro_w = $f->char_width("\x{20AC}", 1000);
        my $w = $f->string_width("\x{20AC}100", 1000);
        my $e = $euro_w + $f->string_width("100", 1000);
        approx_ok($w, $e, 0.01, 'TT string_width "U+20AC+100" == sum of parts');
    }

    # Mixed ASCII + multi-byte decomposition

    {
        my $w = $f->string_width("A\x{E9}Z", 1000);
        my $e = $f->char_width('A', 1000)
              + $f->char_width("\x{E9}", 1000)
              + $f->char_width('Z', 1000);
        approx_ok($w, $e, 0.01, 'TT string_width "A+U+00E9+Z" mixed ASCII+UTF-8 == sum');
    }

    # kern_pair still works with byte strings after UTF-8 build

    approx_ok($f->kern_pair('A', 'V', 1000), -87.89, 0.5, 'TT kern_pair A V unchanged');

    # kern_pair with UTF-8 char args

    approx_ok($f->kern_pair("\x{E9}", "\x{E9}", 1000), 0, 0.001, 'TT kern_pair U+00E9 U+00E9 -> 0');

    # char_width scales linearly at different sizes

    approx_ok($f->char_width("é", 12),
              $f->char_width("é", 1000) * 12 / 1000,
              0.05, 'TT U+00E9 char_width scales linearly');
}

done_testing;
