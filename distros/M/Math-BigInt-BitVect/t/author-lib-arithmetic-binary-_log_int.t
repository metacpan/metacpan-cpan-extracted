#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 22023;

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

can_ok($LIB, '_log_int');

my $scalar_util_ok = eval { require Scalar::Util; };
Scalar::Util -> import('refaddr') if $scalar_util_ok;

diag "Skipping some tests since Scalar::Util is not installed."
  unless $scalar_util_ok;

my @data;

# Small numbers.

for (my $x = 0; $x <= 1000 ; ++ $x) {
    for (my $y = 0; $y <= 10 ; ++ $y) {

        if ($x == 0 || $y <= 1) {
            push @data, [ $x, $y, undef, undef ];
            next;
        }

        my $z = int(log($x) / log($y));
        $z++ while $y ** $z < $x;
        $z-- while $y ** $z > $x;
        my $status = $y ** $z == $x ? 1 : 0;
        push @data, [ $x, $y, $z, $status ];
    }
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $out0, $out1) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in1"); |
             . qq|\@got = $LIB->_log_int(\$x, \$y);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_log_int() in list context: $test", sub {

        unless (defined $out0) {
            plan tests => 1;

            is($got[0], $out0,
               "'$test' output arg has the right value");
            return;
        }

        plan tests => $scalar_util_ok ? 11 : 10;

        # Number of input arguments.

        cmp_ok(scalar @got, '==', 2,
               "'$test' gives two output args");

        # First output argument.

        is(ref($got[0]), $REF,
           "'$test' first output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' first output is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' output arg has the right value");

        isnt(refaddr($got[0]), refaddr($y),
             "'$test' first output arg is not the second input arg")
          if $scalar_util_ok;

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        is(ref($y), $REF,
           "'$test' second input arg is still a $REF");

        is($LIB->_str($y), $in1,
           "'$test' second input arg is unmodified");

        # Second output argument.

        is(ref($got[1]), "",
           "'$test' second output arg is a scalar");

        is($got[1], $out1,
           "'$test' second output arg has the right value");
    };
}
