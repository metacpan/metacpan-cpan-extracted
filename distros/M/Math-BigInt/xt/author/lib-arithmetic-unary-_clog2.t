# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 5181;

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

can_ok($LIB, '_clog2');

# ceil(log(x) / log(2))

sub clog2 {
    my $x = shift;
    my $y = int(log($x) / log(2));

    my $trial = 2 ** $y;
    return $y if $trial == $x;

    while ($trial > $x) {
        $y--;
        $trial = 2 ** $y;
    }

    while ($trial < $x) {
        $y++;
        $trial = 2 ** $y;
    }

    return $y;
}

my @data;

# Small numbers.

for (my $x = 1 ; $x <= 1022 ; ++ $x) {
    my $y = clog2($x);
    my $status = 2 ** $y == $x ? 1 : 0;
    push @data, [ $x, $y, $status ];
}

# Larger numbers.

my $b = $LIB -> _new(2);
for (my $y = 10 ; $y <= 100 ; $y++) {
    my $x    = $LIB -> _pow($LIB -> _copy($b), $LIB -> _new($y));
    my $x_up = $LIB -> _inc($LIB -> _copy($x));
    my $x_dn = $LIB -> _dec($LIB -> _copy($x));
    push @data, [ $LIB -> _str($x_dn), $y,     0 ]; # clog2(2**$y - 1) = $y
    push @data, [ $LIB -> _str($x),    $y,     1 ]; # clog2(2**$y)     = $y
    push @data, [ $LIB -> _str($x_up), $y + 1, 0 ]; # clog2(2**$y + 1) = $y + 1
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, $y, $got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\$got = $LIB->_clog2(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_clog2() in list context: $test", sub {

        unless (defined $out0) {
            plan tests => 1;

            is($got, $out0,
               "'$test' output arg has the right value");
            return;
        }

        plan tests => 5;

        is(ref($got), $REF,
           "'$test' output arg is a $REF");

        is($LIB->_check($got), 0,
           "'$test' output is valid");

        is($LIB->_str($got), $out0,
           "'$test' output arg has the right value");

        is(ref($x), $REF,
           "'$test' input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' input arg has the correct value");
    };
}

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0, $out1) = @{ $data[$i] };

    my ($x, $y, @got);

    my $test = qq|\$x = $LIB->_new("$in0"); |
             . qq|\@got = $LIB->_clog2(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_clog2() in list context: $test", sub {

        unless (defined $out0) {
            plan tests => 1;

            is($got[0], $out0,
               "'$test' output arg has the right value");
            return;
        }

        plan tests => 8;

        # Number of output arguments.

        cmp_ok(scalar(@got), '==', 2,
               "'$test' gives two output args");

        # First output argument.

        is(ref($got[0]), $REF,
           "'$test' first output arg is a $REF");

        is($LIB->_check($got[0]), 0,
           "'$test' first output is valid");

        is($LIB->_str($got[0]), $out0,
           "'$test' output arg has the right value");

        is(ref($x), $REF,
           "'$test' first input arg is still a $REF");

        ok($LIB->_str($x) eq $out0 || $LIB->_str($x) eq $in0,
           "'$test' first input arg has the correct value");

        # Second output argument.

        is(ref($got[1]), "",
           "'$test' second output arg is a scalar");

        is($got[1], $out1,
           "'$test' second output arg has the right value");
    };
}
