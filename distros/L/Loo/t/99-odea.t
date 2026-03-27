use Test::More;

use Loo qw/dDump/;

sub deparse_code {
	my ($code) = @_;
	my $string = dDump { code => $code };
	return Loo::strip_colour($string);
}

# ── Original test: compound assignment += ────────────────────────

sub key2 { } 

my $string = dDump {
	a => 123,
	code => sub {
		do {
			my ($key1, $key2) = (0, key2);
			for (my $i = 0; $i < 10; $i++) {
				print $i;
			}
			return $_[$key1] += $_[key2()];
		}
	}
};

$string = Loo::strip_colour($string);

like($string, qr/'a' => 123/, 'has a => 123');
like($string, qr/sub \{/, 'has deparsed sub');
like($string, qr/do \{/, 'has deparsed do block');
if ($] >= 5.018) {
    like($string, qr/my \(\$key1, \$key2\) = \(0, key2\(\)\)/, 'has deparsed my list assignment');
} else {
    pass('skip padrange list assignment test on old perl');
}
like($string, qr/for \(my \$i = 0; \$i < 10; \+\+\$i\) \{/, 'has deparsed C-style for loop');
if ($] >= 5.012) {
    like($string, qr/return \$_\[\$key1\] \+= \$_\[key2\(\)\]/, 'has deparsed body with += and multideref');
} else {
    pass('skip return += multideref test on old perl');
}
like($string, qr/^  \}/m, 'closing brace properly indented');

# ── Compound assignment operators ────────────────────────────────

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

# ── Logical compound assignment ──────────────────────────────────

like(deparse_code(sub { $_[0] &&= $_[1] }), qr/\$_\[0\] &&= \$_\[1\]/, 'compound &&=');
like(deparse_code(sub { $_[0] ||= $_[1] }), qr/\$_\[0\] \|\|= \$_\[1\]/, 'compound ||=');
like(deparse_code(sub { $_[0] //= $_[1] }), qr/\$_\[0\] \/\/= \$_\[1\]/, 'compound //=');

# ── Binary arithmetic operators ──────────────────────────────────

like(deparse_code(sub { $_[0] + $_[1] }),  qr/\$_\[0\] \+ \$_\[1\]/,  'binary +');
like(deparse_code(sub { $_[0] - $_[1] }),  qr/\$_\[0\] - \$_\[1\]/,   'binary -');
like(deparse_code(sub { $_[0] * $_[1] }),  qr/\$_\[0\] \* \$_\[1\]/,  'binary *');
like(deparse_code(sub { $_[0] / $_[1] }),  qr/\$_\[0\] \/ \$_\[1\]/,  'binary /');
like(deparse_code(sub { $_[0] % $_[1] }),  qr/\$_\[0\] % \$_\[1\]/,   'binary %');
like(deparse_code(sub { $_[0] ** $_[1] }), qr/\$_\[0\] \*\* \$_\[1\]/, 'binary **');

# ── String operators ─────────────────────────────────────────────

like(deparse_code(sub { $_[0] . $_[1] }),  qr/\$_\[0\] \. \$_\[1\]/,  'concat .');
like(deparse_code(sub { $_[0] x $_[1] }),  qr/\$_\[0\] x \$_\[1\]/,   'repeat x');

# ── Comparison operators ─────────────────────────────────────────

like(deparse_code(sub { $_[0] == $_[1] }),  qr/\$_\[0\] == \$_\[1\]/,   'comparison ==');
like(deparse_code(sub { $_[0] != $_[1] }),  qr/\$_\[0\] != \$_\[1\]/,   'comparison !=');
like(deparse_code(sub { $_[0] < $_[1] }),   qr/\$_\[0\] < \$_\[1\]/,    'comparison <');
like(deparse_code(sub { $_[0] > $_[1] }),   qr/\$_\[0\] > \$_\[1\]/,    'comparison >');
like(deparse_code(sub { $_[0] <= $_[1] }),  qr/\$_\[0\] <= \$_\[1\]/,   'comparison <=');
like(deparse_code(sub { $_[0] >= $_[1] }),  qr/\$_\[0\] >= \$_\[1\]/,   'comparison >=');
like(deparse_code(sub { $_[0] <=> $_[1] }), qr/\$_\[0\] <=> \$_\[1\]/,  'comparison <=>');

# ── String comparison operators ──────────────────────────────────

like(deparse_code(sub { $_[0] eq $_[1] }),  qr/\$_\[0\] eq \$_\[1\]/,  'string eq');
like(deparse_code(sub { $_[0] ne $_[1] }),  qr/\$_\[0\] ne \$_\[1\]/,  'string ne');
like(deparse_code(sub { $_[0] lt $_[1] }),  qr/\$_\[0\] lt \$_\[1\]/,  'string lt');
like(deparse_code(sub { $_[0] gt $_[1] }),  qr/\$_\[0\] gt \$_\[1\]/,  'string gt');
like(deparse_code(sub { $_[0] le $_[1] }),  qr/\$_\[0\] le \$_\[1\]/,  'string le');
like(deparse_code(sub { $_[0] ge $_[1] }),  qr/\$_\[0\] ge \$_\[1\]/,  'string ge');
like(deparse_code(sub { $_[0] cmp $_[1] }), qr/\$_\[0\] cmp \$_\[1\]/, 'string cmp');

# ── Logical operators ────────────────────────────────────────────

like(deparse_code(sub { $_[0] && $_[1] }), qr/\$_\[0\] && \$_\[1\]/, 'logical &&');
like(deparse_code(sub { $_[0] || $_[1] }), qr/\$_\[0\] \|\| \$_\[1\]/, 'logical ||');
like(deparse_code(sub { $_[0] // $_[1] }), qr/\$_\[0\] \/\/ \$_\[1\]/, 'logical //');

# ── Bitwise operators ────────────────────────────────────────────

like(deparse_code(sub { $_[0] & $_[1] }),  qr/\$_\[0\] & \$_\[1\]/,  'bitwise &');
like(deparse_code(sub { $_[0] | $_[1] }),  qr/\$_\[0\] \| \$_\[1\]/, 'bitwise |');
like(deparse_code(sub { $_[0] ^ $_[1] }),  qr/\$_\[0\] \^ \$_\[1\]/, 'bitwise ^');

# ── Shift operators ──────────────────────────────────────────────

like(deparse_code(sub { $_[0] << $_[1] }), qr/\$_\[0\] << \$_\[1\]/, 'left shift <<');
like(deparse_code(sub { $_[0] >> $_[1] }), qr/\$_\[0\] >> \$_\[1\]/, 'right shift >>');

# ── Unary operators ──────────────────────────────────────────────

like(deparse_code(sub { !$_[0] }),  qr/!\$_\[0\]/,  'unary !');
like(deparse_code(sub { -$_[0] }),  qr/-\$_\[0\]/,  'unary -');

# ── Increment/decrement ─────────────────────────────────────────

like(deparse_code(sub { ++$_[0] }),  qr/\+\+\$_\[0\]/,  'pre-increment ++');
like(deparse_code(sub { $_[0]++ }),  qr/\$_\[0\]\+\+/,  'post-increment ++');
like(deparse_code(sub { --$_[0] }),  qr/--\$_\[0\]/,     'pre-decrement --');
like(deparse_code(sub { $_[0]-- }),  qr/\$_\[0\]--/,     'post-decrement --');

# ── Ternary operator ─────────────────────────────────────────────

like(deparse_code(sub { $_[0] ? $_[1] : 0 }), qr/\$_\[0\] \? \$_\[1\] : 0/, 'ternary ?:');

# ── Range operator ───────────────────────────────────────────────

like(deparse_code(sub { $_[0] .. $_[1] }), qr/\$_\[0\] \.\. \$_\[1\]/, 'range ..');

# ── do { } block ─────────────────────────────────────────────────

like(deparse_code(sub { do { 42 } }), qr/do \{/, 'do block deparsed');

# ── Multideref (variable index into array/hash) ─────────────────

like(deparse_code(sub { my $i = 0; $_[$i] }),
    qr/\$_\[\$i\]/, 'multideref: $_[$i]');
like(deparse_code(sub { my %h; $h{foo} }),
    qr/\$h\{'foo'\}/, 'multideref: $h{foo}');

# ── Loops ────────────────────────────────────────────────────────

like(deparse_code(sub { while ($_[0]) { print 1 } }),
    qr/while \(\$_\[0\]\) \{/, 'while loop');
like(deparse_code(sub { until ($_[0]) { print 1 } }),
    qr/until \(\$_\[0\]\) \{/, 'until loop');
like(deparse_code(sub { foreach my $x (@_) { print $x } }),
    qr/for my \$x \(\@_\) \{/, 'foreach loop');
like(deparse_code(sub { for my $x (1..10) { print $x } }),
    qr/for my \$x \(1 \.\. 10\) \{/, 'for range loop');
like(deparse_code(sub { for (my $i = 0; $i < 10; $i++) { print $i } }),
    qr/for \(my \$i = 0; \$i < 10; \+\+\$i\) \{/, 'C-style for loop');

done_testing();
