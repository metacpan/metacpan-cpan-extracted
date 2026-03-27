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

# ── if inside loop ──────────────────────────────────────────────

assert_exact(
    'if with multi-statement inside foreach',
    sub { for my $x (@_) { if ($x > 0) { my $y = $x * 2; print $y } } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    if (\$x > 0) {\n" .
    "      my \$y = \$x * 2;\n" .
    "      print \$y;\n" .
    "    };\n" .
    "  }\n" .
    "};\n"
);

# ── loop inside if ──────────────────────────────────────────────

assert_exact(
    'while loop inside if block',
    sub { if ($_[0]) { my $i = 0; while ($i < 5) { ++$i } } },
    "\$VAR1 = sub {\n" .
    "  if (\$_[0]) {\n" .
    "    my \$i = 0;\n" .
    "    while (\$i < 5) {\n" .
    "      ++\$i;\n" .
    "    }\n" .
    "  }\n" .
    "};\n"
);

# ── nested for loops with computation ──────────────────────────

assert_exact(
    'nested for loops with arithmetic',
    sub { my $sum = 0; for my $i (1..3) { for my $j (1..3) { $sum += $i * $j } } return $sum },
    "\$VAR1 = sub {\n" .
    "  my \$sum = 0;\n" .
    "  for my \$i (1 .. 3) {\n" .
    "    for my \$j (1 .. 3) {\n" .
    "      \$sum += \$i * \$j;\n" .
    "    }\n" .
    "  }\n" .
    "  return \$sum;\n" .
    "};\n"
);

# ── if/else inside loop ────────────────────────────────────────

assert_exact(
    'if/else inside foreach with assignment',
    sub {
        my @out;
        for my $x (@_) {
            if ($x > 0) { my $y = $x } else { my $y = 0 }
        }
        return @out
    },
    "\$VAR1 = sub {\n" .
    "  my \@out;\n" .
    "  for my \$x (\@_) {\n" .
    "    if (\$x > 0) {\n" .
    "      my \$y = \$x;\n" .
    "    } else {\n" .
    "      my \$y = 0;\n" .
    "    };\n" .
    "  }\n" .
    "  return \@out;\n" .
    "};\n"
);

# ── do block inside loop ──────────────────────────────────────

assert_exact(
    'do block inside foreach',
    sub { for my $x (@_) { my $y = do { $x + 1 }; print $y } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    my \$y = do {\n" .
    "      \$x + 1;\n" .
    "    };\n" .
    "    print \$y;\n" .
    "  }\n" .
    "};\n"
);

# ── foreach inside while ──────────────────────────────────────

assert_exact(
    'foreach loop inside while loop',
    sub {
        my $n = $_[0];
        while ($n > 0) {
            for my $x (1..3) { print $x }
            --$n;
        }
        return $n
    },
    "\$VAR1 = sub {\n" .
    "  my \$n = \$_[0];\n" .
    "  while (\$n > 0) {\n" .
    "    for my \$x (1 .. 3) {\n" .
    "      print \$x;\n" .
    "    }\n" .
    "    --\$n;\n" .
    "  }\n" .
    "  return \$n;\n" .
    "};\n"
);

# ── Hash operations inside loop ────────────────────────────────

assert_exact(
    'hash construction inside loop',
    sub {
        my %counts;
        for my $x (@_) {
            if (exists $counts{$x}) { $counts{$x} += 1 } else { $counts{$x} = 1 }
        }
        return %counts
    },
    "\$VAR1 = sub {\n" .
    "  my %counts;\n" .
    "  for my \$x (\@_) {\n" .
    "    if (exists(\$counts{\$x})) {\n" .
    "      \$counts{\$x} += 1;\n" .
    "    } else {\n" .
    "      \$counts{\$x} = 1;\n" .
    "    };\n" .
    "  }\n" .
    "  return %counts;\n" .
    "};\n"
);

# ── Multiple if blocks in sequence ─────────────────────────────

assert_exact(
    'sequential if blocks',
    sub {
        my $r = 0;
        if ($_[0]) { $r += 1 }
        if ($_[1]) { $r += 2 }
        if ($_[2]) { $r += 4 }
        return $r
    },
    "\$VAR1 = sub {\n" .
    "  my \$r = 0;\n" .
    "  if (\$_[0]) {\n" .
    "    \$r += 1;\n" .
    "  }\n" .
    "  if (\$_[1]) {\n" .
    "    \$r += 2;\n" .
    "  }\n" .
    "  if (\$_[2]) {\n" .
    "    \$r += 4;\n" .
    "  }\n" .
    "  return \$r;\n" .
    "};\n"
);

done_testing();
