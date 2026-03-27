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

# ── Hash ref construction ──────────────────────────────────────

assert_exact(
    'hash ref literal',
    sub { my $h = {a => 1, b => 2}; return $h },
    "\$VAR1 = sub {\n" .
    "  my \$h = {'a' => 1, 'b' => 2};\n" .
    "  return \$h;\n" .
    "};\n"
);

# ── Array ref construction ─────────────────────────────────────

assert_exact(
    'array ref literal',
    sub { my $a = [1, 2, 3]; return $a },
    "\$VAR1 = sub {\n" .
    "  my \$a = [1, 2, 3];\n" .
    "  return \$a;\n" .
    "};\n"
);

# ── Nested hash ref ────────────────────────────────────────────

assert_exact(
    'nested hash ref literal',
    sub { my $h = {a => {b => 1}}; return $h },
    "\$VAR1 = sub {\n" .
    "  my \$h = {'a' => {'b' => 1}};\n" .
    "  return \$h;\n" .
    "};\n"
);

# ── Hash element access ───────────────────────────────────────

assert_exact(
    'hash element access and assignment',
    sub { my %h; $h{a} = 1; $h{b} = $h{a} + 1; return $h{b} },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  \$h{'a'} = 1;\n" .
    "  \$h{'b'} = \$h{'a'} + 1;\n" .
    "  return \$h{'b'};\n" .
    "};\n"
);

# ── Hash ref deref chain ──────────────────────────────────────

assert_exact(
    'hash ref deref chain',
    sub { my $h = {a => {b => 1}}; return $h->{'a'}{'b'} },
    "\$VAR1 = sub {\n" .
    "  my \$h = {'a' => {'b' => 1}};\n" .
    "  return \$h->{'a'}{'b'};\n" .
    "};\n"
);

# ── exists and delete ─────────────────────────────────────────

assert_exact(
    'exists on hash element',
    sub { my %h; return exists $h{foo} },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return exists(\$h{'foo'});\n" .
    "};\n"
);

assert_exact(
    'delete hash element',
    sub { my %h; delete $h{foo}; return %h },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  delete(\$h{'foo'});\n" .
    "  return %h;\n" .
    "};\n"
);

# ── do block ───────────────────────────────────────────────────

assert_exact(
    'do block as rvalue',
    sub { my $x = do { $_[0] + 1 }; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = do {\n" .
    "    \$_[0] + 1;\n" .
    "  };\n" .
    "  return \$x;\n" .
    "};\n"
);

# ── keys and sort ─────────────────────────────────────────────

assert_exact(
    'keys on lexical hash',
    sub { my %h; return keys %h },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return keys(%h);\n" .
    "};\n"
);

assert_exact(
    'sort on args',
    sub { return sort @_ },
    "\$VAR1 = sub {\n" .
    "  return sort(\@_);\n" .
    "};\n"
);

# ── push ──────────────────────────────────────────────────────

assert_exact(
    'push onto array',
    sub { my @a; push @a, 1; return @a },
    "\$VAR1 = sub {\n" .
    "  my \@a;\n" .
    "  push(\@a, 1);\n" .
    "  return \@a;\n" .
    "};\n"
);

# ── join ──────────────────────────────────────────────────────

assert_exact(
    'join with separator',
    sub { return join(",", @_) },
    "\$VAR1 = sub {\n" .
    "  return join(',', \@_);\n" .
    "};\n"
);

# ── substr ────────────────────────────────────────────────────

assert_exact(
    'substr with 3 args',
    sub { return substr($_[0], 0, 5) },
    "\$VAR1 = sub {\n" .
    "  return substr(\$_[0], 0, 5);\n" .
    "};\n"
);

done_testing();
