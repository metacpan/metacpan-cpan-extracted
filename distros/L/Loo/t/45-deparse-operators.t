use strict;
use warnings;
use Test::More;

use Loo qw/dDump/;

sub deparse_code {
    my ($code) = @_;
    my $string = dDump { code => $code };
    return Loo::strip_colour($string);
}

# ── All compound assignments ────────────────────────────────────

like(deparse_code(sub { $_[0] += $_[1] }),  qr/\$_\[0\] \+= \$_\[1\]/,  'compound +=');
like(deparse_code(sub { $_[0] -= $_[1] }),  qr/\$_\[0\] -= \$_\[1\]/,   'compound -=');
like(deparse_code(sub { $_[0] *= $_[1] }),  qr/\$_\[0\] \*= \$_\[1\]/,  'compound *=');
like(deparse_code(sub { $_[0] /= $_[1] }),  qr/\$_\[0\] \/= \$_\[1\]/,  'compound /=');
like(deparse_code(sub { $_[0] %= $_[1] }),  qr/\$_\[0\] %= \$_\[1\]/,   'compound %=');
like(deparse_code(sub { $_[0] **= $_[1] }), qr/\$_\[0\] \*\*= \$_\[1\]/, 'compound **=');
like(deparse_code(sub { $_[0] .= $_[1] }),  qr/\$_\[0\] \.= \$_\[1\]/,  'compound .=');
like(deparse_code(sub { $_[0] x= $_[1] }),  qr/\$_\[0\] x= \$_\[1\]/,   'compound x=');
like(deparse_code(sub { $_[0] <<= $_[1] }), qr/\$_\[0\] <<= \$_\[1\]/,  'compound <<=');
like(deparse_code(sub { $_[0] >>= $_[1] }), qr/\$_\[0\] >>= \$_\[1\]/,  'compound >>=');
like(deparse_code(sub { $_[0] &= $_[1] }),  qr/\$_\[0\] &= \$_\[1\]/,   'compound &=');
like(deparse_code(sub { $_[0] |= $_[1] }),  qr/\$_\[0\] \|= \$_\[1\]/,  'compound |=');
like(deparse_code(sub { $_[0] ^= $_[1] }),  qr/\$_\[0\] \^= \$_\[1\]/,  'compound ^=');

# ── Logical compound assignment ─────────────────────────────────

like(deparse_code(sub { $_[0] &&= $_[1] }), qr/\$_\[0\] &&= \$_\[1\]/, 'compound &&=');
like(deparse_code(sub { $_[0] ||= $_[1] }), qr/\$_\[0\] \|\|= \$_\[1\]/, 'compound ||=');
like(deparse_code(sub { $_[0] //= $_[1] }), qr/\$_\[0\] \/\/= \$_\[1\]/, 'compound //=');

# ── Binary arithmetic ──────────────────────────────────────────

like(deparse_code(sub { $_[0] + $_[1] }),  qr/\$_\[0\] \+ \$_\[1\]/,  'binary +');
like(deparse_code(sub { $_[0] - $_[1] }),  qr/\$_\[0\] - \$_\[1\]/,   'binary -');
like(deparse_code(sub { $_[0] * $_[1] }),  qr/\$_\[0\] \* \$_\[1\]/,  'binary *');
like(deparse_code(sub { $_[0] / $_[1] }),  qr/\$_\[0\] \/ \$_\[1\]/,  'binary /');
like(deparse_code(sub { $_[0] % $_[1] }),  qr/\$_\[0\] % \$_\[1\]/,   'binary %');
like(deparse_code(sub { $_[0] ** $_[1] }), qr/\$_\[0\] \*\* \$_\[1\]/, 'binary **');

# ── String operators ───────────────────────────────────────────

like(deparse_code(sub { $_[0] . $_[1] }),  qr/\$_\[0\] \. \$_\[1\]/,  'concat .');
like(deparse_code(sub { $_[0] x $_[1] }),  qr/\$_\[0\] x \$_\[1\]/,   'repeat x');

# ── Numeric comparison ─────────────────────────────────────────

like(deparse_code(sub { $_[0] == $_[1] }),  qr/\$_\[0\] == \$_\[1\]/,   '==');
like(deparse_code(sub { $_[0] != $_[1] }),  qr/\$_\[0\] != \$_\[1\]/,   '!=');
like(deparse_code(sub { $_[0] < $_[1] }),   qr/\$_\[0\] < \$_\[1\]/,    '<');
like(deparse_code(sub { $_[0] > $_[1] }),   qr/\$_\[0\] > \$_\[1\]/,    '>');
like(deparse_code(sub { $_[0] <= $_[1] }),  qr/\$_\[0\] <= \$_\[1\]/,   '<=');
like(deparse_code(sub { $_[0] >= $_[1] }),  qr/\$_\[0\] >= \$_\[1\]/,   '>=');
like(deparse_code(sub { $_[0] <=> $_[1] }), qr/\$_\[0\] <=> \$_\[1\]/,  '<=>');

# ── String comparison ──────────────────────────────────────────

like(deparse_code(sub { $_[0] eq $_[1] }),  qr/\$_\[0\] eq \$_\[1\]/,  'eq');
like(deparse_code(sub { $_[0] ne $_[1] }),  qr/\$_\[0\] ne \$_\[1\]/,  'ne');
like(deparse_code(sub { $_[0] lt $_[1] }),  qr/\$_\[0\] lt \$_\[1\]/,  'lt');
like(deparse_code(sub { $_[0] gt $_[1] }),  qr/\$_\[0\] gt \$_\[1\]/,  'gt');
like(deparse_code(sub { $_[0] le $_[1] }),  qr/\$_\[0\] le \$_\[1\]/,  'le');
like(deparse_code(sub { $_[0] ge $_[1] }),  qr/\$_\[0\] ge \$_\[1\]/,  'ge');
like(deparse_code(sub { $_[0] cmp $_[1] }), qr/\$_\[0\] cmp \$_\[1\]/, 'cmp');

# ── Logical operators ──────────────────────────────────────────

like(deparse_code(sub { $_[0] && $_[1] }), qr/\$_\[0\] && \$_\[1\]/, '&&');
like(deparse_code(sub { $_[0] || $_[1] }), qr/\$_\[0\] \|\| \$_\[1\]/, '||');
like(deparse_code(sub { $_[0] // $_[1] }), qr/\$_\[0\] \/\/ \$_\[1\]/, '//');

# ── Bitwise operators ──────────────────────────────────────────

like(deparse_code(sub { $_[0] & $_[1] }),  qr/\$_\[0\] & \$_\[1\]/,  'bitwise &');
like(deparse_code(sub { $_[0] | $_[1] }),  qr/\$_\[0\] \| \$_\[1\]/, 'bitwise |');
like(deparse_code(sub { $_[0] ^ $_[1] }),  qr/\$_\[0\] \^ \$_\[1\]/, 'bitwise ^');

# ── Shift operators ────────────────────────────────────────────

like(deparse_code(sub { $_[0] << $_[1] }), qr/\$_\[0\] << \$_\[1\]/, '<<');
like(deparse_code(sub { $_[0] >> $_[1] }), qr/\$_\[0\] >> \$_\[1\]/, '>>');

# ── Unary operators ────────────────────────────────────────────

like(deparse_code(sub { !$_[0] }),  qr/!\$_\[0\]/,  'unary !');
like(deparse_code(sub { -$_[0] }),  qr/-\$_\[0\]/,  'unary -');

# ── Increment/decrement ───────────────────────────────────────

like(deparse_code(sub { ++$_[0] }),  qr/\+\+\$_\[0\]/,  'pre-increment');
like(deparse_code(sub { $_[0]++ }),  qr/\$_\[0\]\+\+/,  'post-increment');
like(deparse_code(sub { --$_[0] }),  qr/--\$_\[0\]/,     'pre-decrement');
like(deparse_code(sub { $_[0]-- }),  qr/\$_\[0\]--/,     'post-decrement');

# ── Ternary ────────────────────────────────────────────────────

like(deparse_code(sub { $_[0] ? $_[1] : 0 }), qr/\$_\[0\] \? \$_\[1\] : 0/, 'ternary ?:');

# ── Range ──────────────────────────────────────────────────────

like(deparse_code(sub { $_[0] .. $_[1] }), qr/\$_\[0\] \.\. \$_\[1\]/, 'range ..');

done_testing();
