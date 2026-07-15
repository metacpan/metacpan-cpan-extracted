use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }

# ── integer ───────────────────────────────────────────────────────

{
    my $out = j('{"n":42}');
    like($out, qr/^\s+"n": 42$/m, 'positive integer');
}

# ── zero ─────────────────────────────────────────────────────────

{
    my $out = j('{"n":0}');
    like($out, qr/^\s+"n": 0$/m, 'zero');
}

# ── negative integer ──────────────────────────────────────────────

{
    my $out = j('{"n":-7}');
    like($out, qr/^\s+"n": -7$/m, 'negative integer');
}

# ── float ─────────────────────────────────────────────────────────

{
    my $out = j('{"x":3.14}');
    like($out, qr/^\s+"x": 3\.14$/m, 'float');
}

# ── negative float ────────────────────────────────────────────────

{
    my $out = j('{"x":-1.5}');
    like($out, qr/^\s+"x": -1\.5$/m, 'negative float');
}

# ── scientific notation (lowercase e) ────────────────────────────

{
    my $out = j('{"n":1e10}');
    like($out, qr/^\s+"n": 1e10$/m, 'scientific notation lowercase e');
}

# ── scientific notation (uppercase E) ────────────────────────────

{
    my $out = j('{"n":2E3}');
    like($out, qr/^\s+"n": 2E3$/m, 'scientific notation uppercase E');
}

# ── scientific notation with sign ────────────────────────────────

{
    my $out = j('{"n":1.5e+2}');
    like($out, qr/^\s+"n": 1\.5e\+2$/m, 'scientific notation with +');
    $out = j('{"n":2.5e-3}');
    like($out, qr/^\s+"n": 2\.5e-3$/m, 'scientific notation with -');
}

# ── fractional without leading digit ─────────────────────────────

{
    my $out = j('[0.5]');
    like($out, qr/^\s+0\.5$/m, 'decimal without leading digits in array');
}

# ── multiple numbers in array ─────────────────────────────────────

{
    my $src = '[1,-2,3.14,1e5]';
    my $expected = <<'END';
[
  1,
  -2,
  3.14,
  1e5
]
END
    is(j($src), $expected, 'mixed numeric array');
}

# ── large integer ─────────────────────────────────────────────────

{
    my $out = j('{"big":9007199254740991}');
    like($out, qr/^\s+"big": 9007199254740991$/m, 'large integer (Number.MAX_SAFE_INTEGER)');
}

done_testing;
