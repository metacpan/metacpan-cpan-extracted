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

# ════════════════════════════════════════════════════════════════
# These tests document known deparser bugs. Each one currently
# FAILS and should be fixed. When you fix a bug, the corresponding
# test will start passing — remove the TODO block around it.
# ════════════════════════════════════════════════════════════════

# ── BUG: elsif chain shows as nested else { if (...;) } ────────
# Expected: elsif ($cond) { ... }
# Actual:   else { \n if (    $cond;) { ... } }

assert_exact(
    'if/elsif/else chain',
    sub {
        my $r;
        if ($_[0] > 0)    { $r = "pos"  }
        elsif ($_[0] < 0) { $r = "neg"  }
        else              { $r = "zero" }
        return $r;
    },
    "\$VAR1 = sub {\n" .
    "  my \$r;\n" .
    "  if (\$_[0] > 0) {\n" .
    "    \$r = 'pos';\n" .
    "  } elsif (\$_[0] < 0) {\n" .
    "    \$r = 'neg';\n" .
    "  } else {\n" .
    "    \$r = 'zero';\n" .
    "  }\n" .
    "  return \$r;\n" .
    "};\n"
);

# ── BUG: anonymous subs not deparsed (OP_SREFGEN/OP_ANONCODE) ──
# Expected: my $cb = sub { ... }
# Actual:   my $cb = ;

assert_exact(
    'anonymous sub assigned to variable',
    sub { my $cb = sub { return $_[0] + 1 }; return $cb },
    "\$VAR1 = sub {\n" .
    "  my \$cb = sub {\n" .
    "    return \$_[0] + 1;\n" .
    "  };\n" .
    "  return \$cb;\n" .
    "};\n"
);

assert_exact(
    'anonymous sub as hash value',
    sub { my $h = { fn => sub { return 1 } }; return $h },
    "\$VAR1 = sub {\n" .
    "  my \$h = {'fn' => sub {\n" .
    "    return 1;\n" .
    "  }};\n" .
    "  return \$h;\n" .
    "};\n"
);

# ── BUG: .= as standalone statement not deparsed ───────────────
# Expected: $s .= 'b';
# Actual:   'b';  (the concat-assign is lost)

assert_exact(
    'concat-assign .= as statement',
    sub { my $s = "a"; $s .= "b"; return $s },
    "\$VAR1 = sub {\n" .
    "  my \$s = 'a';\n" .
    "  \$s .= 'b';\n" .
    "  return \$s;\n" .
    "};\n"
);

# ── BUG: method calls lose method name ─────────────────────────
# Expected: $obj->method()
# Actual:   $obj->()

assert_exact(
    'method call on object',
    sub { my $obj = $_[0]; $obj->method() },
    "\$VAR1 = sub {\n" .
    "  my \$obj = \$_[0];\n" .
    "  \$obj->method();\n" .
    "};\n"
);

# ── BUG: split args are wrong ─────────────────────────────────
# Expected: split(/:/, $_[0])
# Actual:   split($_[0], 0)

assert_exact(
    'split with regex',
    sub { return split(/:/, $_[0]) },
    "\$VAR1 = sub {\n" .
    "  return split(/:/, \$_[0]);\n" .
    "};\n"
);

# ── BUG: grep/map formatting broken ───────────────────────────
# Expected: grep { $_ > 0 } @_
# Actual:   grep { do {\n    $_ > 0;\n  }@_ }

assert_exact(
    'grep with block',
    sub { return grep { $_ > 0 } @_ },
    "\$VAR1 = sub {\n" .
    "  return grep { \$_ > 0 } \@_;\n" .
    "};\n"
);

assert_exact(
    'map with block',
    sub { return map { $_ * 2 } @_ },
    "\$VAR1 = sub {\n" .
    "  return map { \$_ * 2 } \@_;\n" .
    "};\n"
);

# ── BUG: my @a = @_ shows as my @a = my @a ────────────────────
# Expected: my @a = @_;
# Actual:   my @a = my @a;

assert_exact(
    'array copy from @_',
    sub { my @a = @_; return @a },
    "\$VAR1 = sub {\n" .
    "  my \@a = \@_;\n" .
    "  return \@a;\n" .
    "};\n"
);

# ── BUG: precedence wrong for ($_[2] || 1) ────────────────────
# Expected: ... / ($_[2] || 1)
# Actual:   ... / $_[2] || 1  (missing parens, wrong precedence)

assert_exact(
    'complex precedence with parens around ||',
    sub { return ($_[0] + 1) * ($_[1] - 2) / ($_[2] || 1) },
    "\$VAR1 = sub {\n" .
    "  return (\$_[0] + 1) * (\$_[1] - 2) / (\$_[2] || 1);\n" .
    "};\n"
);

# ── BUG: eval block has spurious semicolons ────────────────────
# Expected: eval { ... }
# Actual:   eval {\n;    ...\n  }

assert_exact(
    'eval block',
    sub { my $r = eval { $_[0] / $_[1] }; return $r },
    "\$VAR1 = sub {\n" .
    "  my \$r = eval {\n" .
    "    \$_[0] / \$_[1];\n" .
    "  };\n" .
    "  return \$r;\n" .
    "};\n"
);

# ── BUG: string interpolation not deparsed ─────────────────────
# Expected: "hello $_[0]"  (or the concat equivalent)
# Actual:   'hello ' .   (missing the variable part)

like(deparse_exact(sub { return "hello $_[0]" }),
    qr/hello.+\$_\[0\]/,
    'interpolated string preserves variable');

# ── BUG: wantarray ternary with list loses parens ──────────────
# Expected: wantarray() ? (1, 2) : 1
# Actual:   wantarray() ? 1, 2 : 1  (missing parens around list)

assert_exact(
    'wantarray with list in ternary',
    sub { return wantarray() ? (1, 2) : 1 },
    "\$VAR1 = sub {\n" .
    "  return wantarray() ? (1, 2) : 1;\n" .
    "};\n"
);

# ── BUG: next/last with condition shows as && not statement modifier ──
# Not strictly a bug (valid Perl) but ideally should be: next if $x > 10

like(deparse_exact(sub { for my $x (@_) { next if $x > 10; print $x } }),
    qr/next if \$x > 10/,
    'next if condition (statement modifier)');

# ── BUG: array/hash slices broken ─────────────────────────────
# Expected: @a[0, 1]
# Actual:   0, 1@a

like(deparse_exact(sub { my @a = (1,2,3); return @a[0, 1] }),
    qr/\@a\[0, 1\]/,
    'array slice @a[0,1]');

like(deparse_exact(sub { my %h; return @h{qw(a b)} }),
    qr/\@h\{/,
    'hash slice @h{qw(a b)}');

# ── BUG: C-style for inside loop body not detected ────────────
# C-for detection only works at top-level stmts, not inside
# loop bodies where the lineseq is deparsed differently.

like(deparse_exact(sub {
        while ($_[0]) {
            for (my $i = 0; $i < 5; $i++) { print $i }
        }
    }),
    qr/for \(my \$i = 0;/,
    'C-style for inside while body');

done_testing();
