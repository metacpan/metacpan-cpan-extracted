# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 1801;

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

# Read the reference type the library uses.

our $REF = $config->{_}->{ref};

die "No reference type defined in file '$config_file'"
  unless defined $REF;
die "Invalid reference type '$REF' in file '$config_file'"
  unless $REF =~ /^[A-Za-z]\w*(::\w+)*\z/;

# Load the library.

eval "require $LIB";
die $@ if $@;

###############################################################################

my $scalar_util_ok = eval { require Scalar::Util; };
Scalar::Util -> import('refaddr') if $scalar_util_ok;

diag "Skipping some tests since Scalar::Util is not installed."
  unless $scalar_util_ok;

can_ok($LIB, '_sadd');

my @data;

# Simple numbers.

my @val = (0 .. 5);
for my $exp (1 .. 9) {
    push @val, 0 + "1e$exp";
}

for my $xa (@val) {
    for my $xs ('+', '-') {
        for my $ya (@val) {
            for my $ys ('+', '-') {
                my $x = $xs . $xa;
                my $y = $ys . $ya;
                my $z = $x + $y;
                my $zs = $z < 0 ? '-' : '+';
                my $za = abs($z);
                push @data, [ $xa, $xs, $ya, $ys, $za, $zs ];
            }
        }
    }
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $in2, $in3, $out0, $out1) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in2"); |
             . qq|\@got = $LIB->_sadd(\$x, "$in1", \$y, "$in3");|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_sadd() in list context: $test", sub {
        plan tests => 11;

        cmp_ok(scalar @got, '==', 2,
               "'$test' gives two output args");

        is(ref($got[0]), $REF,
           "'$test' first output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' first output arg is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' first output arg has the right value");

        is(ref($got[1]), '',
           "'$test' second output arg is a scalar");

        is($got[1], $out1,
           "'$test' second output arg has the right value");

      SKIP: {
            skip "Scalar::Util not available", 1 unless $scalar_util_ok;

            isnt(refaddr($got[0]), refaddr($y),
                 "'$test' output arg is not the second input arg");
        }

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        is(ref($y), $REF,
           "'$test' second input arg is still a $REF");

        is($LIB->_str($y), $in2,
           "'$test' second input arg is unmodified");
    };
}
