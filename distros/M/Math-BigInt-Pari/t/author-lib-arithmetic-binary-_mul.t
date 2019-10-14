#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 7541;

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

# Read the reference type(s) the library uses.

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

can_ok($LIB, '_mul');

my @data;

# Small numbers.

for (my $x = 0; $x <= 24 ; ++ $x) {
    for (my $y = 0; $y <= 24 ; ++ $y) {
        push @data, [ $x, $y, $x * $y ];
    }
}

# 9 * 11, 99 * 101, 999 * 1001, 9999 * 1001, ...

for (my $p = 1; $p <= 50 ; ++ $p) {
    my $x = "9" x $p;
    my $y = "1" . ("0" x ($p - 1)) . "1";
    my $z = "9" x (2 * $p);
    push @data, [ $x, $y, $z ];
}

# 9 * 9, 99 * 99, 999 * 999, 9999 * 9999, ...

for (my $p = 1; $p <= 50 ; ++ $p) {
    my $x = "9" x $p;
    my $z = "9" x ($p - 1) . "8" . "0" x ($p - 1) . "1";
    push @data, [ $x, $x, $z ];
}

# Powers of 10.

for (my $p = 0; $p <= 24 ; ++ $p) {
    for (my $q = 0; $q <= 24 ; ++ $q) {
        my $x = "1" . ("0" x $p);
        my $y = "1" . ("0" x $q);
        my $z = "1" . ("0" x ($p + $q));
        push @data, [ $x, $y, $z ];
    }
}

# Add data in data file.

(my $datafile = $0) =~ s/\.t/.dat/;
open DATAFILE, $datafile or die "$datafile: can't open file for reading: $!";
while (<DATAFILE>) {
    s/\s+\z//;
    next if /^#/ || ! /\S/;
    push @data, [ split /:/ ];
}
close DATAFILE or die "$datafile: can't close file after reading: $!";

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in1"); |
             . qq|\@got = $LIB->_mul(\$x, \$y);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_mul() in list context: $test", sub {
        plan tests => $scalar_util_ok ? 9 : 8;

        cmp_ok(scalar @got, '==', 1,
               "'$test' gives one output arg");

        is(ref($got[0]), $REF,
           "'$test' output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' output is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' output arg has the right value");

        isnt(refaddr($got[0]), refaddr($y),
             "'$test' output arg is not the second input arg")
          if $scalar_util_ok;

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        is(ref($y), $REF,
           "'$test' second input arg is still a $REF");

        is($LIB->_str($y), $in1,
           "'$test' second input arg is unmodified");
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0) = @{ $data[$i] };

    my ($x, $y, $got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in1"); |
             . qq|\$got = $LIB->_mul(\$x, \$y);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_mul() in scalar context: $test", sub {
        plan tests => $scalar_util_ok ? 8 : 7;

        is(ref($got), $REF,
           "'$test' output arg is a $REF");

        is($LIB->_check($got), 0,
           "'$test' output is valid");

        is($LIB->_str($got), $out0,
           "'$test' output arg has the right value");

        isnt(refaddr($got), refaddr($y),
             "'$test' output arg is not the second input arg")
          if $scalar_util_ok;

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        is(ref($y), $REF,
           "'$test' second input arg is still a $REF");

        is($LIB->_str($y), $in1,
           "'$test' second input arg is unmodified");
    };
}
