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

# ── Postfix for with simple statement ───────────────────────────

assert_exact(
    'postfix for with print',
    sub { print $_ for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    print \$_;\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'postfix for with range',
    sub { print $_ for (1..10) },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (1 .. 10) {\n" .
    "    print \$_;\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'postfix for with warn',
    sub { warn $_ for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    warn \$_;\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix for with && and do block ────────────────────────────

assert_exact(
    'and-do block in postfix for',
    sub { $_ == 5 && do { print "found" } for (0..100) },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (0 .. 100) {\n" .
    "    if (\$_ == 5) {\n" .
    "      print 'found';\n" .
    "    };\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'or-do block in postfix for',
    sub { $_ || do { print "zero" } for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    unless (\$_) {\n" .
    "      print 'zero';\n" .
    "    };\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'and-do with last in postfix for',
    sub { $_ eq "stop" && do { last } for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    if (\$_ eq 'stop') {\n" .
    "      last;\n" .
    "    };\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix for with && expression ──────────────────────────────

assert_exact(
    'and-print in postfix for',
    sub { $_ > 0 && print "pos" for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    \$_ > 0 && print 'pos';\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'defined-and-print in postfix for',
    sub { defined $_ && print $_ for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    defined(\$_) && print \$_;\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix for with builtins ──────────────────────────────────

assert_exact(
    'chomp in postfix for',
    sub { chomp $_ for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    chomp(\$_);\n" .
    "  }\n" .
    "};\n"
);

assert_exact(
    'chop in postfix for',
    sub { chop $_ for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    chop(\$_);\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix for with push ──────────────────────────────────────

assert_exact(
    'push in postfix for',
    sub { my @out; push @out, $_ * 2 for @_ },
    "\$VAR1 = sub {\n" .
    "  my \@out;\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    push(\@out, \$_ * 2);\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix for with next ──────────────────────────────────────

assert_exact(
    'next in postfix for',
    sub { next for @_ },
    "\$VAR1 = sub {\n" .
    ($] < 5.012 ? "  \n" : "") .
    "  for (\@_) {\n" .
    "    next;\n" .
    "  }\n" .
    "};\n"
);

# ── Postfix if/unless ──────────────────────────────────────────

assert_exact(
    'postfix if with print',
    sub { print "ok" if $_[0] },
    "\$VAR1 = sub {\n" .
    "  \$_[0] && print 'ok';\n" .
    "};\n"
);

assert_exact(
    'postfix unless with print',
    sub { print "ok" unless $_[0] },
    "\$VAR1 = sub {\n" .
    "  \$_[0] || print 'ok';\n" .
    "};\n"
);

assert_exact(
    'postfix if with die',
    sub { die "error" if $_[0] },
    "\$VAR1 = sub {\n" .
    "  \$_[0] && die 'error';\n" .
    "};\n"
);

# ── do block standalone ────────────────────────────────────────

assert_exact(
    'standalone do block',
    sub { do { print "hi" } },
    "\$VAR1 = sub {\n" .
    "  do {\n" .
    "    print 'hi';\n" .
    "  }\n" .
    "};\n"
);

done_testing();
