#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 20993;

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

can_ok($LIB, '_zeros');

use lib 't';
use Math::BigInt::Lib::TestUtil qw< randstr >;

my @data;

# Small numbers.

for (my $x = 0; $x <= 9 ; ++ $x) {
    push @data, [ $x, 0 ];
}

for (my $x = 10; $x <= 99 ; ++ $x) {
    push @data, [ $x, $x % 10 ? 0 : 1 ];
}

# Random numbers.

for (my $p = 0 ; $p <= 100 ; ++ $p) {
    for (my $q = 0 ; $q <= 50 ; ++ $q) {
        next if $p + $q < 2;                # small numbers done above
        my $in0  = randstr($p, 10)          # p digit number (base 10)
                 . (1 + int rand 9)         # ensure non-zero digit
                 . ("0" x $q);              # q zeros
        my $out0 = $q;
        push @data, [ $in0, $out0 ];
    }
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); | .
               qq|\@got = $LIB->_zeros(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_zeros() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, "==", 1,
               "'$test' gives one output arg");

        is(ref($got[0]), "",
           "output arg is a Perl scalar");

        cmp_ok($got[0], "==", $out0,
               "output arg has the right value");
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, $got);

    my $test = qq|\$x = $LIB->_new("$in0"); | .
               qq|\$got = $LIB->_zeros(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_zeros() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), "",
           "output arg is a Perl scalar");

        cmp_ok($got, "==", $out0,
               "output arg has the right value");
    };
}
