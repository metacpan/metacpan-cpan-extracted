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

# ── Scalar lexicals ────────────────────────────────────────────

assert_exact(
    'my scalar declaration and use',
    sub { my $x = 42; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = 42;\n" .
    "  return \$x;\n" .
    "};\n"
);

assert_exact(
    'multiple my declarations',
    sub { my $x = $_[0]; my $y = $_[1]; my $z = $x + $y; return $z },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  my \$y = \$_[1];\n" .
    "  my \$z = \$x + \$y;\n" .
    "  return \$z;\n" .
    "};\n"
);

# ── Array lexicals ─────────────────────────────────────────────

assert_exact(
    'my array declaration',
    sub { my @a; return @a },
    "\$VAR1 = sub {\n" .
    "  my \@a;\n" .
    "  return \@a;\n" .
    "};\n"
);

SKIP: {
    skip 'OP_AELEMFAST_LEX not available before 5.18', 1 if $] < 5.018;
    assert_exact(
        'lexical array constant index',
        sub { my @x; return $x[2] },
        "\$VAR1 = sub {\n" .
        "  my \@x;\n" .
        "  return \$x[2];\n" .
        "};\n"
    );
}

assert_exact(
    'lexical array dynamic index',
    sub { my @x; my $i = 0; return $x[$i] },
    "\$VAR1 = sub {\n" .
    "  my \@x;\n" .
    "  my \$i = 0;\n" .
    "  return \$x[\$i];\n" .
    "};\n"
);

# ── Hash lexicals ──────────────────────────────────────────────

assert_exact(
    'my hash declaration',
    sub { my %h; return %h },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return %h;\n" .
    "};\n"
);

assert_exact(
    'hash constant key access',
    sub { my %h; return $h{'foo'} },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return \$h{'foo'};\n" .
    "};\n"
);

assert_exact(
    'hash chained access',
    sub { my %h; return $h{'a'}{'b'} },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return \$h{'a'}{'b'};\n" .
    "};\n"
);

# ── @_ access patterns ────────────────────────────────────────

assert_exact(
    'direct @_ element access',
    sub { return $_[0] + $_[1] },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] + \$_[1];\n" .
    "};\n"
);

assert_exact(
    'full @_ in list context',
    sub { for my $x (@_) { print $x } },
    "\$VAR1 = sub {\n" .
    "  for my \$x (\@_) {\n" .
    "    print \$x;\n" .
    "  }\n" .
    "};\n"
);

# ── local ──────────────────────────────────────────────────────

assert_exact(
    'local $_ assignment',
    sub { local $_ = $_[0]; return $_ },
    "\$VAR1 = sub {\n" .
    "  local \$_ = \$_[0];\n" .
    "  return \$_;\n" .
    "};\n"
);

# ── Scalar/array deref ────────────────────────────────────────

assert_exact(
    'scalar ref deref',
    sub { my $r = $_[0]; return $$r },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \$\$r;\n" .
    "};\n"
);

assert_exact(
    'array ref deref',
    sub { my $r = $_[0]; return @$r },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \@\$r;\n" .
    "};\n"
);

# ── Hash ref deref access ─────────────────────────────────────

assert_exact(
    'hash ref arrow access',
    sub { my $h = $_[0]; return $h->{'key'} },
    "\$VAR1 = sub {\n" .
    "  my \$h = \$_[0];\n" .
    "  return \$h->{'key'};\n" .
    "};\n"
);

done_testing();
