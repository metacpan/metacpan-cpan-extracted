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

# ── while loop ──────────────────────────────────────────────────

assert_exact(
    'while loop with increment',
    sub { my $i = 0; while ($i < 10) { $i++ } return $i },
    "\$VAR1 = sub {\n" .
    "  my \$i = 0;\n" .
    "  while (\$i < 10) {\n" .
    "    ++\$i;\n" .
    "  }\n" .
    "  return \$i;\n" .
    "};\n"
);

assert_exact(
    'while loop with compound condition',
    sub { my $x = $_[0]; while ($x > 0 && $x < 100) { $x *= 2 } return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  while (\$x > 0 && \$x < 100) {\n" .
    "    \$x *= 2;\n" .
    "  }\n" .
    "  return \$x;\n" .
    "};\n"
);

# ── until loop ──────────────────────────────────────────────────

assert_exact(
    'until loop',
    sub { my $i = 0; until ($i >= 10) { $i++ } return $i },
    "\$VAR1 = sub {\n" .
    "  my \$i = 0;\n" .
    "  until (\$i >= 10) {\n" .
    "    ++\$i;\n" .
    "  }\n" .
    "  return \$i;\n" .
    "};\n"
);

# ── foreach with list ──────────────────────────────────────────

assert_exact(
    'foreach loop over @_',
    sub { for my $x (@_) { print $x } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    print \$x;\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'foreach loop with range',
    sub { for my $i (1..10) { print $i } },
    "\$VAR1 = sub {\n" .
    "  for my \$i (1 .. 10) {\n" .
    "    print \$i;\n" .
    "  }\n" .
    "};\n"
);

# ── C-style for loop ──────────────────────────────────────────

assert_exact(
    'C-style for loop with sum',
    sub { my $sum = 0; for (my $i = 0; $i < 10; $i++) { $sum += $i } return $sum },
    "\$VAR1 = sub {\n" .
    "  my \$sum = 0;\n" .
    "  for (my \$i = 0; \$i < 10; ++\$i) {\n" .
    "    \$sum += \$i;\n" .
    "  }\n" .
    "  return \$sum;\n" .
    "};\n"
);

# ── Nested loops ───────────────────────────────────────────────

assert_exact(
    'nested foreach loops',
    sub { for my $i (1..3) { for my $j (1..3) { print $i * $j } } },
    "\$VAR1 = sub {\n" .
    "  for my \$i (1 .. 3) {\n" .
    "    for my \$j (1 .. 3) {\n" .
    "      print \$i * \$j;\n" .
    "    }\n" .
    "  }\n" .
    "};\n"
);

# ── while with last ────────────────────────────────────────────

assert_exact(
    'while loop with last',
    sub { my $i = 0; while ($i < 10) { ++$i; $i == 5 && last } return $i },
    "\$VAR1 = sub {\n" .
    "  my \$i = 0;\n" .
    "  while (\$i < 10) {\n" .
    "    ++\$i;\n" .
    "    \$i == 5 && last;\n" .
    "  }\n" .
    "  return \$i;\n" .
    "};\n"
);

# ── foreach with next ──────────────────────────────────────────

assert_exact(
    'foreach loop with next and last',
    sub { for my $x (@_) { next; } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    next;\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'foreach loop with next and last',
    sub { next for (@_) },
    "\$VAR1 = sub {\n" .
    "  for (\@_) {\n" .
    "    next;\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'foreach loop with last',
    sub { for my $x (@_) { last; } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    last;\n" .
    "  }\n" .
    "};\n"
);

# ── foreach with push ─────────────────────────────────────────

assert_exact(
    'foreach loop with push',
    sub { my @out; for my $x (@_) { my $y = $x * 2; push @out, $y } return @out },
    "\$VAR1 = sub {\n" .
    "  my \@out;\n" .
    "  for my \$x (\@_) {\n" .
    "    my \$y = \$x * 2;\n" .
    "    push(\@out, \$y);\n" .
    "  }\n" .
    "  return \@out;\n" .
    "};\n"
);

done_testing();
