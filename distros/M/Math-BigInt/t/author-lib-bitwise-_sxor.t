#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author\n";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 69001;

###############################################################################
# Read and load configuration file and backend library.

use Config::Tiny;
use Scalar::Util qw< refaddr >;

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

can_ok($LIB, '_and');

my @data;

# Add data in data file.

(my $datafile = $0) =~ s/\.t/.dat/;
open DATAFILE, $datafile or die "$datafile: can't open file for reading: $!";
while (<DATAFILE>) {
    s/\s+\z//;
    next if /^#/ || ! /\S/;
    push @data, [ split /:/ ];
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $in1, $in2, $in3, $out0, $out1) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$y = $LIB->_new("$in2"); |
             . qq|\@got = $LIB->_sxor(\$x, "$in1", \$y, "$in3");|;

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    cmp_ok(scalar @got, '==', 2,
           "'$test' gives two output args");

    # First output arg.

    is(ref($got[0]), $REF,
       "'$test' first output arg is a $REF");

    is($LIB->_check($got[0]), 0,
       "'$test' first output arg is valid");

    is($LIB->_str($got[0]), $out0,
       "'$test' first output arg has the right value");

    isnt(refaddr($got[0]), refaddr($y),
         "'$test' first output arg is not the third input arg");

    is(ref($x), $REF,
       "'$test' first input arg is still a $REF");

    my $strx = $LIB->_str($x);
    if ($strx eq $in0 || $strx eq $out0) {
        pass("'$test' first input value is unmodified or equal" .
             " to the output value");
    } else {
        fail("'$test' first input value is unmodified or equal" .
             " to the output value");
        diag("         got: '", $strx, "'");
        if ($in0 eq $out0) {
            diag("    expected: '$in0' (first input and output value)");
        } else {
            diag("    expected: '$in0' (first input value) or '$out0'",
                 " (first output value)");
        }
    }

    # Second output arg.

    is(ref($got[1]), "",
       "'$test' second output arg is a scalar");

    is($got[1], $out1,
       "'$test' second output arg has the right value");

    # Other tests.

    is(ref($y), $REF,
       "'$test' third input arg is still a $REF");

    is($LIB->_str($y), $in2,
       "'$test' third input arg is unmodified");
}
