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
    'complex multi-statement arithmetic stays exact',
    sub {
        my $x = $_[0];
        my $y = $_[1];
        my $sum = $x + $y;
        return $sum * 2;
    },
    "\$VAR1 = sub {\n" .
    "  my \$x = \$_[0];\n" .
    "  my \$y = \$_[1];\n" .
    "  my \$sum = \$x + \$y;\n" .
    "  return \$sum * 2;\n" .
    "};\n"
);

assert_exact(
    'precedence without parens stays exact',
    sub { return $_[0] + $_[1] * 2; },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] + \$_[1] * 2;\n" .
    "};\n"
);

assert_exact(
    'precedence with parens stays exact',
    sub { return ($_[0] + $_[1]) * 2; },
    "\$VAR1 = sub {\n" .
    "  return (\$_[0] + \$_[1]) * 2;\n" .
    "};\n"
);

assert_exact(
    'logical precedence chain stays exact',
    sub { return $_[0] && $_[1] || $_[2]; },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] && \$_[1] || \$_[2];\n" .
    "};\n"
);

assert_exact(
    'nested ternary is preserved',
    sub { return $_[0] > 0 ? 'pos' : $_[0] < 0 ? 'neg' : 'zero'; },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] > 0 ? 'pos' : \$_[0] < 0 ? 'neg' : 'zero';\n" .
    "};\n"
);

assert_exact(
    'regex bind subject is preserved',
    sub { return $_[0] =~ m/foo/; },
    "\$VAR1 = sub {\n" .
    "  return \$_[0] =~ m/foo/;\n" .
    "};\n"
);

assert_exact(
    'lexical array constant index stays exact',
    sub { my @x; return $x[2]; },
    "\$VAR1 = sub {\n" .
    "  my \@x;\n" .
    "  return \$x[2];\n" .
    "};\n"
);

assert_exact(
    'lexical array dynamic index stays exact',
    sub { my @x; my $i = 0; return $x[$i]; },
    "\$VAR1 = sub {\n" .
    "  my \@x;\n" .
    "  my \$i = 0;\n" .
    "  return \$x[\$i];\n" .
    "};\n"
);

done_testing();
