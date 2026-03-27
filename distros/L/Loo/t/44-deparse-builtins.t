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

# ── print/say/warn/die ─────────────────────────────────────────

assert_exact(
    'print with variable',
    sub { print $_[0] },
    "\$VAR1 = sub {\n" .
    "  print \$_[0];\n" .
    "};\n"
);

assert_exact(
    'warn with variable',
    sub { warn $_[0] },
    "\$VAR1 = sub {\n" .
    "  warn \$_[0];\n" .
    "};\n"
);

assert_exact(
    'die with string literal',
    sub { die "error" },
    "\$VAR1 = sub {\n" .
    "  die 'error';\n" .
    "};\n"
);

# ── String builtins ────────────────────────────────────────────

assert_exact(
    'uc builtin',
    sub { return uc($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return uc(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'lc builtin',
    sub { return lc($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return lc(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'ucfirst builtin',
    sub { return ucfirst($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return ucfirst(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'lcfirst builtin',
    sub { return lcfirst($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return lcfirst(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'nested string builtins',
    sub { return uc(lc($_[0])) },
    "\$VAR1 = sub {\n" .
    "  return uc(lc(\$_[0]));\n" .
    "};\n"
);

# ── Numeric builtins ──────────────────────────────────────────

assert_exact(
    'abs builtin',
    sub { return abs($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return abs(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'int builtin',
    sub { return int($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return int(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'sqrt builtin',
    sub { return sqrt($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return sqrt(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'nested numeric builtins',
    sub { return sqrt(abs(int($_[0]))) },
    "\$VAR1 = sub {\n" .
    "  return sqrt(abs(int(\$_[0])));\n" .
    "};\n"
);

# ── chr/ord ───────────────────────────────────────────────────

assert_exact(
    'chr/ord composition',
    sub { return chr(ord($_[0])) },
    "\$VAR1 = sub {\n" .
    "  return chr(ord(\$_[0]));\n" .
    "};\n"
);

# ── hex/oct ───────────────────────────────────────────────────

assert_exact(
    'hex and oct arithmetic',
    sub { return hex($_[0]) + oct($_[1]) },
    "\$VAR1 = sub {\n" .
    "  return hex(\$_[0]) + oct(\$_[1]);\n" .
    "};\n"
);

# ── defined/ref ───────────────────────────────────────────────

assert_exact(
    'defined check',
    sub { return defined($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return defined(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'ref check',
    sub { return ref($_[0]) },
    "\$VAR1 = sub {\n" .
    "  return ref(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'defined and length chain',
    sub { return defined($_[0]) && length($_[0]) > 0 },
    "\$VAR1 = sub {\n" .
    "  return defined(\$_[0]) && length(\$_[0]) > 0;\n" .
    "};\n"
);

# ── chomp ─────────────────────────────────────────────────────

assert_exact(
    'chomp on variable',
    sub { my $x = $_[0]; chomp $x; return $x },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  chomp(\$x);\n" .
    "  return \$x;\n" .
    "};\n"
);

# ── Array builtins ────────────────────────────────────────────

assert_exact(
    'push onto array',
    sub { my @a; push @a, 1; return @a },
    "\$VAR1 = sub {\n" .
    "  my \@a;\n" .
    "  push(\@a, 1);\n" .
    "  return \@a;\n" .
    "};\n"
);

assert_exact(
    'sort args',
    sub { return sort @_ },
    "\$VAR1 = sub {\n" .
    "  return sort(\@_);\n" .
    "};\n"
);

assert_exact(
    'keys on hash',
    sub { my %h; return keys %h },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return keys(%h);\n" .
    "};\n"
);

# ── join/substr ───────────────────────────────────────────────

assert_exact(
    'join with separator',
    sub { return join(",", @_) },
    "\$VAR1 = sub {\n" .
    "  return join(',', \@_);\n" .
    "};\n"
);

assert_exact(
    'substr 3 args',
    sub { return substr($_[0], 0, 5) },
    "\$VAR1 = sub {\n" .
    "  return substr(\$_[0], 0, 5);\n" .
    "};\n"
);

# ── exists/delete ─────────────────────────────────────────────

assert_exact(
    'exists on hash',
    sub { my %h; return exists $h{foo} },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return exists(\$h{'foo'});\n" .
    "};\n"
);

assert_exact(
    'delete from hash',
    sub { my %h; delete $h{foo}; return %h },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  delete(\$h{'foo'});\n" .
    "  return %h;\n" .
    "};\n"
);

# ── Regex ─────────────────────────────────────────────────────

assert_exact(
    'regex match with bind',
    sub { return $_[0] =~ m/foo/ },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] =~ m/foo/;\n" .
    "};\n"
);

assert_exact(
    'qr regex construction',
    sub { return qr/bar/ },
    "\$VAR1 = sub {\n" .
    "  return qr/bar/;\n" .
    "};\n"
);

done_testing();
