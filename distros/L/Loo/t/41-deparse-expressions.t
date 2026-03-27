use strict;
use warnings;
use Test::More;

use Loo;

sub deparse_exact {
    my ($code) = @_;
    return Loo::strip_colour(Loo::dDump($code));
}

sub assert_exact {
    my ($name, $code, $expected) = @_;
    is(deparse_exact($code), $expected, $name);
}

# ── Precedence and parenthesisation ────────────────────────────

assert_exact(
    'mul higher than add, no parens needed',
    sub { return $_[0] + $_[1] * 2 },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] + \$_[1] * 2;\n" .
    "};\n"
);

assert_exact(
    'parens force addition before multiply',
    sub { return ($_[0] + $_[1]) * 2 },
    "\$VAR1 = sub {\n" .
    "  return (\$_[0] + \$_[1]) * 2;\n" .
    "};\n"
);

# ── Logical chains ─────────────────────────────────────────────

assert_exact(
    'logical and/or chain',
    sub { return $_[0] && $_[1] || $_[2] },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] && \$_[1] || \$_[2];\n" .
    "};\n"
);

assert_exact(
    'defined-or operator',
    sub { return $_[0] // $_[1] },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] // \$_[1];\n" .
    "};\n"
);

# ── Ternary ────────────────────────────────────────────────────

assert_exact(
    'simple ternary',
    sub { return $_[0] ? 1 : 0 },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] ? 1 : 0;\n" .
    "};\n"
);

assert_exact(
    'nested ternary',
    sub { return $_[0] > 0 ? 'pos' : $_[0] < 0 ? 'neg' : 'zero' },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] > 0 ? 'pos' : \$_[0] < 0 ? 'neg' : 'zero';\n" .
    "};\n"
);

# ── String operations ─────────────────────────────────────────

assert_exact(
    'string concat chain',
    sub { return uc($_[0]) . " " . lc($_[1]) },
    "\$VAR1 = sub {\n" .
    "  return uc(\$_[0]) . ' ' . lc(\$_[1]);\n" .
    "};\n"
);

# ── Regex match ───────────────────────────────────────────────

assert_exact(
    'regex bind on variable',
    sub { return $_[0] =~ m/foo/ },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] =~ m/foo/;\n" .
    "};\n"
);

# ── wantarray ─────────────────────────────────────────────────

assert_exact(
    'wantarray ternary',
    sub { return wantarray() ? @_ : $_[0] },
    "\$VAR1 = sub {\n" .
    "  return wantarray() ? \@_ : \$_[0];\n" .
    "};\n"
);

# ── Compound assignments ─────────────────────────────────────

assert_exact(
    'compound += in multi-statement',
    sub { my $x = $_[0]; $x += $_[1]; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  \$x += \$_[1];\n" .
    "  return \$x;\n" .
    "};\n"
);

assert_exact(
    'compound *= in multi-statement',
    sub { my $x = $_[0]; $x *= $_[1]; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  \$x *= \$_[1];\n" .
    "  return \$x;\n" .
    "};\n"
);

# ── Logical compound assignment ───────────────────────────────

assert_exact(
    'compound ||= with default',
    sub { my $x = $_[0]; $x ||= "default"; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  \$x ||= 'default';\n" .
    "  return \$x;\n" .
    "};\n"
);

assert_exact(
    'compound //= with default',
    sub { my $x = $_[0]; $x //= 0; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  \$x //= 0;\n" .
    "  return \$x;\n" .
    "};\n"
);

# ── Scalar deref ─────────────────────────────────────────────

assert_exact(
    'scalar deref',
    sub { my $r = $_[0]; return $$r },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \$\$r;\n" .
    "};\n"
);

assert_exact(
    'array deref',
    sub { my $r = $_[0]; return @$r },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \@\$r;\n" .
    "};\n"
);

# ── local ────────────────────────────────────────────────────

assert_exact(
    'local variable',
    sub { local $_ = $_[0]; return $_ },
    "\$VAR1 = sub {\n" .
    "  local \$_ = \$_[0];\n" .
    "  return \$_;\n" .
    "};\n"
);

# ── chomp/die/warn ───────────────────────────────────────────

assert_exact(
    'chomp on variable',
    sub { my $x = $_[0]; chomp $x; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  chomp(\$x);\n" .
    "  return \$x;\n" .
    "};\n"
);

assert_exact(
    'die with string',
    sub { die "error" },
    "\$VAR1 = sub {\n" .
    "  die 'error';\n" .
    "};\n"
);

assert_exact(
    'warn with variable',
    sub { warn $_[0] },
    "\$VAR1 = sub {\n" .
    "  warn \$_[0];\n" .
    "};\n"
);

done_testing();
