#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 137;

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

can_ok($LIB, '_check');

# Generate test data.

my @data;

push @data, ([ "$LIB->_zero()", 1 ],      # valid objects
             [ "$LIB->_one()",  1 ],
             [ "$LIB->_two()",  1 ],
             [ "$LIB->_ten()",  1 ]);

for (my $n = 0 ; $n <= 24 ; ++ $n) {
    push @data, [ qq|$LIB->_new("1| . ("0" x $n) . qq|")|, 1 ];
}

push @data, ([ "undef",         0 ],      # invalid objects
             [ "''",            0 ],
             [ "1",             0 ],
             [ "[]",            0 ],
             [ "{}",            0 ]);

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, @got);

    my $test = qq|\$x = $in0; |
             . qq|\@got = $LIB->_check(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_check() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, "==", 1,
               "'$test' gives one output arg");

        is(ref($got[0]), "",
           "'$test' output arg is a scalar");

        if ($out0) {                    # valid object
            ok(! $got[0], "'$test' output arg is false (object OK)")
              or diag("       got: $got[0]\n  expected: (something false)");
        } else {                        # invalid object
            ok($got[0], "'$test' output arg is true (object not OK)")
              or diag("       got: $got[0]\n  expected: (something true)");
        }
    };
}

# Scalar context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my ($in0, $out0) = @{ $data[$i] };

    my ($x, $got);

    my $test = qq|\$x = $in0; |
             . qq|\$got = $LIB->_check(\$x);|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "_check() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), "",
           "'$test' output arg is a scalar");

        if ($out0) {                    # valid object
            ok(! $got, "'$test' output arg is false (object OK)")
              or diag("       got: $got\n  expected: (something false)");
        } else {                        # invalid object
            ok($got, "'$test' output arg is true (object not OK)")
              or diag("       got: $got\n  expected: (something true)");
        }
    };
}
