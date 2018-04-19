#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 5385;

###############################################################################
# Read and load configuration file and backend library.

use Config::Tiny ();

my $config_file = 't/author-lib.ini';
my $config = Config::Tiny -> read('t/author-lib.ini')
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

use lib 't';
use Math::BigInt::Lib::TestUtil qw< randstr >;

can_ok($LIB, '_acmp');

# Generate test data.

my @data;

# Small integers.

for my $a (0 .. 10) {
    for my $b (0 .. 10) {
        push @data, [ $a, $b, $a <=> $b ];
    }
}

# Integers close to a power of ten.

for my $n (2 .. 26) {

    my $x = "9" x $n;                       # e.g.,  "9999"
    my $y = "1" . ("0" x $n);               # e.g., "10000"
    my $z = "1" . ("0" x ($n - 1)) . "1";   # e.g., "10001"
    push @data, [ $x, $x,  0 ];
    push @data, [ $x, $y, -1 ];
    push @data, [ $x, $z, -1 ];
    push @data, [ $y, $x,  1 ];
    push @data, [ $y, $y,  0 ];
    push @data, [ $y, $z, -1 ];
    push @data, [ $z, $x,  1 ];
    push @data, [ $z, $y,  1 ];
    push @data, [ $z, $z,  0 ];
}

# Random large integers.

for (1 .. 1000) {
    my $na  = 2 + int rand 35;      # number of digits in $a
    my $nb  = 2 + int rand 35;      # number of digits in $a
    my $a   = randstr($na, 10);     # generate $a
    my $b   = randstr($na, 10);     # generate $b
    my $cmp = length($a) <=> length($b) || $a cmp $b;
    push @data, [ $a, $b, $cmp ];
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in1"); |
             . qq|\@got = $LIB->_acmp(\$x, \$y);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_new() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, "==", 1,
               "'$test' one output arg");

        is(ref($got[0]), "",
           "'$test' output arg is a Perl scalar");

        is($got[0], $out0,
           "'$test' output arg has the right value");
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0) = @{ $data[$i] };

    my ($x, $y, $got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in1"); |
             . qq|\$got = $LIB->_acmp(\$x, \$y);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_new() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), "",
           "'$test' output arg is a Perl scalar");

        is($got, $out0,
           "'$test' output arg has the right value");
    };
}
