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

# ── Simple if block ─────────────────────────────────────────────

assert_exact(
    'if block with multi-statement body',
    sub { if ($_[0]) { my $x = 1; return $x } },
    "\$VAR1 = sub {\n" .
    "  if (\$_[0]) {\n" .
    "    my \$x = 1;\n" .
    "    return \$x;\n" .
    "  }\n" .
    "};\n"
);

# ── if/else ─────────────────────────────────────────────────────

assert_exact(
    'if/else with assignments',
    sub { my $r; if ($_[0] > 0) { $r = "pos" } else { $r = "neg" } return $r },
    "\$VAR1 = sub {\n" .
    "  my \$r;\n" .
    "  if (\$_[0] > 0) {\n" .
    "    \$r = 'pos';\n" .
    "  } else {\n" .
    "    \$r = 'neg';\n" .
    "  }\n" .
    "  return \$r;\n" .
    "};\n"
);

# ── unless block ────────────────────────────────────────────────

assert_exact(
    'unless block with assignment',
    sub { my $r = 0; unless ($_[0]) { $r = 1 } return $r },
    "\$VAR1 = sub {\n" .
    "  my \$r = 0;\n" .
    "  unless (\$_[0]) {\n" .
    "    \$r = 1;\n" .
    "  }\n" .
    "  return \$r;\n" .
    "};\n"
);

# ── if inside loop ──────────────────────────────────────────────

assert_exact(
    'if block inside foreach loop',
    sub { for my $x (@_) { if ($x > 0) { print $x } } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    if (\$x > 0) {\n" .
    "      print \$x;\n" .
    "    };\n" .
    "  }\n" .
    "};\n"
);

# ── loop inside if ──────────────────────────────────────────────

assert_exact(
    'foreach loop inside if block',
    sub { if ($_[0]) { for my $x (1..5) { print $x } } },
    "\$VAR1 = sub {\n" .
    "  if (\$_[0]) {\n" .
    "    for my \$x (1 .. 5) {\n" .
    "      print \$x;\n" .
    "    }\n" .
    "  }\n" .
    "};\n"
);

# ── nested if blocks ───────────────────────────────────────────

assert_exact(
    'nested if blocks',
    sub { if ($_[0]) { if ($_[1]) { my $x = 1; return $x } } },
    "\$VAR1 = sub {\n" .
    "  if (\$_[0]) {\n" .
    "    if (\$_[1]) {\n" .
    "      my \$x = 1;\n" .
    "      return \$x;\n" .
    "    }\n" .
    "  }\n" .
    "};\n"
);

# ── if with complex condition ──────────────────────────────────

assert_exact(
    'if with compound condition',
    sub { if ($_[0] > 0 && $_[1] > 0) { my $r = 1; return $r } },
    "\$VAR1 = sub {\n" .
    "  if (\$_[0] > 0 && \$_[1] > 0) {\n" .
    "    my \$r = 1;\n" .
    "    return \$r;\n" .
    "  }\n" .
    "};\n"
);

done_testing();
