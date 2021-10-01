# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3397;

###############################################################################
# Read and load configuration file and backend library.

use Config::Tiny ();

my $config_file = 'xt/author/lib.ini';
my $config = Config::Tiny -> read('xt/author/lib.ini')
  or die Config::Tiny -> errstr();

# Read the library to test.

our $LIB = $config->{_}->{lib};

die "No library defined in file '$config_file'"
  unless defined $LIB;
die "Invalid library name '$LIB' in file '$config_file'"
  unless $LIB =~ /^[A-Za-z]\w*(::\w+)*\z/;

# Load the library.

eval "require $LIB";
die $@ if $@;

###############################################################################

can_ok($LIB, "_num");

use lib "t";
use Math::BigInt::Lib::TestUtil qw< randstr >;

# Compute parameters for relative tolerance.
#
# $p is the precision, i.e., the number of bits in the mantissa/significand, as
# defined in IEEE754. $eps is the smallest number that, when subtracted from 1,
# gives a number smaller than 1.

my $p = 0;
my $eps = 1;
while (((1 + $eps) - 1) != 0) {
    $eps *= 0.5;
    $p++;
}
my $reltol = 100 * $eps;

# Generate test data.

my @data;

push @data, 0 .. 250;                   # small integers

for (my $n = 3 ; $n <= 300 ; ++ $n) {
    push @data, "1" . ("0" x $n);       # powers of 10
}

for (my $n = 1 ; $n <= 300 ; ++ $n) {
    push @data, randstr($n, 10);        # random big integers
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my $str = $data[$i];
    my $num = 0 + $str;

    my ($x, @got);

    my $test = qq|\$x = $LIB->_new("$str"); |
             . qq|\@got = $LIB->_num(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_num() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, "==", 1,
               "'$test' gives one output arg");

        is(ref($got[0]), "",
           "'$test' output arg is a Perl scalar");

        # If output does not use floating point notation, compare the
        # values exactly ...

        if ($got[0] =~ /^\d+\z/) {
            cmp_ok($got[0], "==", $num,
                   "'$test' output value is exactly right");
        }

        # ... otherwise compare them approximatly.

        else {
            my $text = "'$test' output value is correct within"
                     . " a relative error of $reltol";
            my $abserr = $got[0] - $num;
            my $relerr = $abserr / $num;
            if (abs($relerr) <= $reltol) {
                pass($text);
            } else {
                fail($text);
                diag(<<EOF);
          got: $got[0]
     expected: $num
    abs. err.: $abserr
    rel. err.: $relerr
    rel. tol.: $reltol
EOF
            }
        }
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my $str = $data[$i];
    my $num = 0 + $str;

    my ($x, $got);

    my $test = qq|\$x = $LIB->_new("$str"); |
             . qq|\$got = $LIB->_num(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_num() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), "",
           "'$test' output arg is a Perl scalar");

        # If output does not use floating point notation, compare the
        # values exactly ...

        if ($got =~ /^\d+\z/) {
            cmp_ok($got, "==", $num,
                   "'$test' output value is exactly right");
        }

        # ... otherwise compare them approximatly.

        else {
            my $text = "'$test' output value is correct within"
                     . " a relative error of $reltol";
            my $abserr = $got - $num;
            my $relerr = $abserr / $num;
            if (abs($relerr) <= $reltol) {
                pass($text);
            } else {
                fail($text);
                diag(<<EOF);
          got: $got
     expected: $num
    abs. err.: $abserr
    rel. err.: $relerr
    rel. tol.: $reltol
EOF
            }
        }
    };
}
