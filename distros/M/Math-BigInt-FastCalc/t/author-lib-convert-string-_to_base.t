#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 23761;

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

can_ok($LIB, '_to_base');

my @data;

# Small numbers and other simple tests.

for (my $x = 0; $x <= 255 ; ++ $x) {
    push @data, [ $x,  2, sprintf("%b", $x) ];
    push @data, [ $x,  8, sprintf("%o", $x) ];
    push @data, [ $x, 10, sprintf("%d", $x) ];
    push @data, [ $x, 16, sprintf("%X", $x) ];
}

my $collseq = '0123456789' . 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                           . 'abcdefghijklmnopqrstuvwxyz';

for my $base (2 .. 62) {

    # Zero should be converted to zero, regardless of base and collation
    # sequence.

    push @data, [ "0", $base,           "0" ];
    push @data, [ "0", $base, $collseq, "0" ];

    # Increasing integer powers of the base, with a collation sequence of
    # "01..."  should give "1", "10", "100", "1000", ...

    for my $pow (0 .. 5) {
        push @data, [ $base ** $pow, $base,           '1' . ('0' x $pow) ];
        push @data, [ $base ** $pow, $base, $collseq, '1' . ('0' x $pow) ];
    }
}

#     "123" in base "10" is "123"
#   "10203" in base "100" is "123"
# "1002030" in base "1000" is "123"
# ...

for my $exp (1 .. 100) {
    my $sep  = "0" x ($exp - 1);
    my $x    = join($sep, "1", "2", "3");
    my $base =  "1" . ("0" x $exp);
    my $str  = "123";
    push @data, [ $x, $base, $collseq, $str ];
}

{
    my $collseq = '-|';
    for my $base (2 .. 255) {
        for my $pow (0 .. 3) {
            my $x   = $base ** $pow;
            my $str = '|' . ('-' x $pow);
            push @data, [ $x, $base, $collseq, $str ];
        }
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
    my @in   = @{ $data[$i] };
    my $out0 = pop @in;

    my ($x, @got);

    # We test with the base given as a scalar and as a reference. We also
    # accept test data with and without a collation sequence.

    for my $base_as_scalar (0, 1) {

        # To avoid integer overflow, don't test with a large, scalar base.

        next if $base_as_scalar && $in[1] > 1_000_000;

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        if ($base_as_scalar) {
            $test .= qq| \$b = $in[1];|;
        } else {
            $test .= qq| \$b = $LIB->_new("$in[1]");|;
        }
        $test .= qq| \@got = $LIB->_to_base(\$x, \$b|;
        $test .= qq|, "$in[2]"| if @in == 3;    # include collation sequence?
        $test .= qq|);|;

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        eval $test;
        is($@, "", "'$test' gives emtpy \$\@");

        subtest "_to_base() in list context: $test", sub {
            plan tests => 3,

            cmp_ok(scalar @got, '==', 1,
                   "'$test' gives one output arg");

            is(ref($got[0]), "",
               "'$test' output arg is a scalar");

            is($got[0], $out0,
               "'$test' output arg has the right value");
        };
    }
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my @in   = @{ $data[$i] };
    my $out0 = pop @in;

    my ($x, $got);

    # We test with the base given as a scalar and as a reference. We also
    # accept test data with and without a collation sequence.

    for my $base_as_scalar (0, 1) {

        # To avoid integer overflow, don't test with a large, scalar base.

        next if $base_as_scalar && $in[1] > 1_000_000;

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        if ($base_as_scalar) {
            $test .= qq| \$b = $in[1];|;
        } else {
            $test .= qq| \$b = $LIB->_new("$in[1]");|;
        }
        $test .= qq| \$got = $LIB->_to_base(\$x, \$b|;
        $test .= qq|, "$in[2]"| if @in == 3;    # include collation sequence?
        $test .= qq|);|;

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        eval $test;
        is($@, "", "'$test' gives emtpy \$\@");

        subtest "_to_base() in scalar context: $test", sub {
            plan tests => 2,

            is(ref($got), "",
               "'$test' output arg is a scalar");

            is($got, $out0,
               "'$test' output arg has the right value");
        };
    }
}
