# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 593;

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

can_ok($LIB, '_digitsum');

use lib 't';
use Math::BigInt::Lib::TestUtil qw< randstr >;

# Generate test data.

my @data;

for (my $x = 0 ; $x <= 100 ; ++ $x) {
    my $str = sprintf "%u", $x;
    my @digits = $] >= 5.008 ? unpack "(a)*", $str
                             : split //, $str;
    my $sum = 0;
    $sum += $_ for @digits;
    push @data, [ $str, $sum ];
}

for (my $n = 4 ; $n <= 50 ; ++ $n) {
    my $str = randstr($n, 10);
    my @digits = $] >= 5.008 ? unpack "(a)*", $str
                             : split //, $str;
    my $sum = 0;
    $sum += $_ for @digits;
    push @data, [ $str, $sum ];
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\@got = $LIB->_digitsum(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_digitsum() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, "==", 1,
               "'$test' gives one output arg");

        is(ref($got[0]), $REF,
           "'$test' output arg is a $REF");

        is($LIB->_str($got[0]), $out0,
           "'$test' output arg has the right value");
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, $got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$got = $LIB->_digitsum(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_digitsum() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), $REF,
           "'$test' output arg is a $REF");

        is($LIB->_str($got), $out0,
           "'$test' output arg has the right value");
    };
}
