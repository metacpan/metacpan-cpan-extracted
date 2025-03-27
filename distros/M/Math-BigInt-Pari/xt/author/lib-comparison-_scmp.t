# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 1765;

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

use lib 't';
use Math::BigInt::Lib::TestUtil qw< randstr >;

can_ok($LIB, '_scmp');

# Generate test data.

my @data;

# Small integers.

for my $a (-10 .. 10) {
    for my $b (-10 .. 10) {
        push @data, [ $a, $b, $a <=> $b ];
    }
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0) = @{ $data[$i] };

    my ($x, $y, @got);

    my $sgn_in0 = $in0 < 0 ? "-" : "+";
    my $abs_in0 = abs($in0);

    my $sgn_in1 = $in1 < 0 ? "-" : "+";
    my $abs_in1 = abs($in1);

    my $test = qq|\$x = $LIB->_new("$abs_in0"); |
             . qq|\$y = $LIB->_new("$abs_in1"); |
             . qq|\@got = $LIB->_scmp(\$x, "$sgn_in0", \$y, "$sgn_in1");|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_new() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar(@got), "==", 1,
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

    my $sgn_in0 = $in0 < 0 ? "-" : "+";
    my $abs_in0 = abs($in0);

    my $sgn_in1 = $in1 < 0 ? "-" : "+";
    my $abs_in1 = abs($in1);

    my $test = qq|\$x = $LIB->_new("$abs_in0"); |
             . qq|\$y = $LIB->_new("$abs_in1"); |
             . qq|\$got = $LIB->_scmp(\$x, "$sgn_in0", \$y, "$sgn_in1");|;

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
