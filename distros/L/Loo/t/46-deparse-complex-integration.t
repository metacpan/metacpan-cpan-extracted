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

# ── Accumulator pattern ────────────────────────────────────────

assert_exact(
    'sum accumulator with C-style for',
    sub {
        my $sum = 0;
        for (my $i = 1; $i <= 10; $i++) {
            $sum += $i;
        }
        return $sum;
    },
    "\$VAR1 = sub {\n" .
    "  my \$sum = 0;\n" .
    "  for (my \$i = 1; \$i <= 10; ++\$i) {\n" .
    "    \$sum += \$i;\n" .
    "  }\n" .
    "  return \$sum;\n" .
    "};\n"
);

# ── Filter pattern ─────────────────────────────────────────────

assert_exact(
    'if with assignment inside foreach',
    sub {
        my @out;
        for my $x (@_) {
            if ($x > 0) {
                my $y = $x * 2;
                print $y;
            }
        }
        return @out;
    },
    "\$VAR1 = sub {\n" .
    "  my \@out;\n" .
    "  for my \$x (\@_) {\n" .
    "    if (\$x > 0) {\n" .
    "      my \$y = \$x * 2;\n" .
    "      print \$y;\n" .
    "    };\n" .
    "  }\n" .
    "  return \@out;\n" .
    "};\n"
);

# ── Transform pattern ─────────────────────────────────────────

assert_exact(
    'transform with hash accumulation',
    sub {
        my %result;
        for my $key (@_) {
            $result{$key} = length($key);
        }
        return %result;
    },
    "\$VAR1 = sub {\n" .
    "  my %result;\n" .
    "  for my \$key (\@_) {\n" .
    "    \$result{\$key} = length(\$key);\n" .
    "  }\n" .
    "  return %result;\n" .
    "};\n"
);

# ── Guard clause pattern ──────────────────────────────────────

assert_exact(
    'guard with unless (negated condition becomes unless)',
    sub {
        if (!defined($_[0])) {
            return 0;
        }
        return $_[0] * 2;
    },
    "\$VAR1 = sub {\n" .
    ($] >= 5.012
        ? "  unless (defined(\$_[0])) {\n"
        : "  if (!defined(\$_[0])) {\n") .
    "    return 0;\n" .
    "  }\n" .
    "  return \$_[0] * 2;\n" .
    "};\n"
);

# ── Multi-step computation ─────────────────────────────────────

assert_exact(
    'multi-step with multiple vars',
    sub {
        my $x = $_[0];
        my $y = $_[1];
        my $sum = $x + $y;
        my $product = $x * $y;
        return $sum + $product;
    },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  my \$y = \$_[1];\n" .
    "  my \$sum = \$x + \$y;\n" .
    "  my \$product = \$x * \$y;\n" .
    "  return \$sum + \$product;\n" .
    "};\n"
);

# ── Nested data structure building ─────────────────────────────

assert_exact(
    'build hash ref with computed values',
    sub {
        my $data = {
            'name' => $_[0],
            'count' => $_[1],
        };
        return $data;
    },
    "\$VAR1 = sub {\n" .
    "  my \$data = {'name' => \$_[0], 'count' => \$_[1]};\n" .
    "  return \$data;\n" .
    "};\n"
);

# ── Builtin chain in loop ─────────────────────────────────────

assert_exact(
    'string processing in loop',
    sub {
        my @out;
        for my $s (@_) {
            my $t = uc($s);
            push @out, $t;
        }
        return @out;
    },
    "\$VAR1 = sub {\n" .
    "  my \@out;\n" .
    "  for my \$s (\@_) {\n" .
    "    my \$t = uc(\$s);\n" .
    "    push(\@out, \$t);\n" .
    "  }\n" .
    "  return \@out;\n" .
    "};\n"
);

# ── While with early exit ─────────────────────────────────────

assert_exact(
    'while loop with conditional exit',
    sub {
        my $i = 0;
        my $found = 0;
        while ($i < 100) {
            if ($_[$i] == 0) {
                $found = 1;
                last;
            }
            ++$i;
        }
        return $found;
    },
    "\$VAR1 = sub {\n" .
    "  my \$i = 0;\n" .
    "  my \$found = 0;\n" .
    "  while (\$i < 100) {\n" .
    "    if (\$_[\$i] == 0) {\n" .
    "      \$found = 1;\n" .
    "      last;\n" .
    "    };\n" .
    "    ++\$i;\n" .
    "  }\n" .
    "  return \$found;\n" .
    "};\n"
);

# ── Multiple return paths ─────────────────────────────────────

assert_exact(
    'multiple returns with if/else',
    sub {
        my $x = $_[0];
        if ($x > 100) {
            return "big";
        } else {
            if ($x > 10) {
                return "medium";
            } else {
                return "small";
            }
        }
    },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  if (\$x > 100) {\n" .
    "    return 'big';\n" .
    "  } else {\n" .
    "    if (\$x > 10) {\n" .
    "      return 'medium';\n" .
    "    } else {\n" .
    "      return 'small';\n" .
    "    }\n" .
    "  }\n" .
    "};\n"
);

# ── do block with complex expression ──────────────────────────

assert_exact(
    'do block with arithmetic',
    sub {
        my $result = do {
            my $a = $_[0];
            my $b = $_[1];
            $a * $b + 1;
        };
        return $result;
    },
    "\$VAR1 = sub {\n" .
    "  my \$result = do {\n" .
    "    my \$a = \$_[0];\n" .
    "    my \$b = \$_[1];\n" .
    "    \$a * \$b + 1;\n" .
    "  };\n" .
    "  return \$result;\n" .
    "};\n"
);

done_testing();
