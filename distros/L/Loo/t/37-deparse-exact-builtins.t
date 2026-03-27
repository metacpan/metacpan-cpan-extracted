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

assert_exact(
    'defined and length chain stays exact',
    sub { return defined($_[0]) && length($_[0]) > 0; },
    "\$VAR1 = sub {\n" .
    "  return defined(\$_[0]) && length(\$_[0]) > 0;\n" .
    "};\n"
);

assert_exact(
    'ref stays exact',
    sub { return ref($_[0]); },
    "\$VAR1 = sub {\n" .
    "  return ref(\$_[0]);\n" .
    "};\n"
);

assert_exact(
    'string builtin chain stays exact',
    sub { return uc(lc($_[0])); },
    "\$VAR1 = sub {\n" .
    "  return uc(lc(\$_[0]));\n" .
    "};\n"
);

assert_exact(
    'numeric builtin chain stays exact',
    sub { return sqrt(abs(int($_[0]))); },
    "\$VAR1 = sub {\n" .
    "  return sqrt(abs(int(\$_[0])));\n" .
    "};\n"
);

assert_exact(
    'chr/ord composition stays exact',
    sub { return chr(ord($_[0])); },
    "\$VAR1 = sub {\n" .
    "  return chr(ord(\$_[0]));\n" .
    "};\n"
);

assert_exact(
    'hex and oct arithmetic stays exact',
    sub { return hex($_[0]) + oct($_[1]); },
    "\$VAR1 = sub {\n" .
    "  return hex(\$_[0]) + oct(\$_[1]);\n" .
    "};\n"
);

assert_exact(
    'warn with variable stays exact',
    sub { warn $_[0]; },
    "\$VAR1 = sub {\n" .
    "  warn \$_[0];\n" .
    "};\n"
);

assert_exact(
    'deref return from scalar ref stays exact',
    sub { my $r = $_[0]; return $$r; },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \$\$r;\n" .
    "};\n"
);

assert_exact(
    'deref return from array ref stays exact',
    sub { my $r = $_[0]; return @$r; },
    "\$VAR1 = sub {\n" .
    "  my \$r = \$_[0];\n" .
    "  return \@\$r;\n" .
    "};\n"
);

assert_exact(
    'hash multideref chain stays exact',
    sub { my %h; return $h{'a'}{'b'}; },
    "\$VAR1 = sub {\n" .
    "  my %h;\n" .
    "  return \$h{'a'}{'b'};\n" .
    "};\n"
);

done_testing();
