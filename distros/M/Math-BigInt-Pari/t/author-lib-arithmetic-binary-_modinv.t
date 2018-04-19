#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 14523;

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

can_ok($LIB, '_modinv');

my @data;

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
    my ($in0, $in1, $out0, $out1, $out2, $out3) = @{ $data[$i] };

    my ($x, $m, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$m = $LIB->_new("$in1"); |
             . qq|\@got = $LIB->_modinv(\$x, \$m);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_modinv() in list context: $test", sub {
        if ($out0 eq "undef") {

            plan tests => 3;

            cmp_ok(scalar @got, "==", 2,
                   "'$test' gives two output args");

            is($got[0], undef,
               "'$test' first output arg is undef");

            is($got[1], undef,
               "'$test' second output arg is undef");

        } else {

            plan tests => $scalar_util_ok ? 7 : 6;

            cmp_ok(scalar @got, "==", 2,
                   "'$test' gives two output args");

            is(ref($got[0]), $REF,
               "'$test' first output arg is a $REF");

            is($LIB->_check($got[0]), 0,
               "'$test' first output arg is valid");

            isnt(refaddr($got[0]), refaddr($m),
                 "'$test' first output arg is not the second input arg")
              if $scalar_util_ok;

            is(ref($got[1]), "",
               "'$test' second output arg is a scalar");

            like($got[1], qr/^[+-]\z/,
               "'$test' second output arg is valid");

            my $got  = $got[1] . $LIB->_str($got[0]);   # prepend sign to value
            my $alt0 = $out1 . $out0;
            my $alt1 = $out3 . $out2;

            ok($got eq $alt0 || $got eq $alt1,
               "'$test' output args have the right value");
        }
    };
}
