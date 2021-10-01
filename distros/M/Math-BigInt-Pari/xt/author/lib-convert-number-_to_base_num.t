# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 53;

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

can_ok($LIB, '_to_base_num');

# For simplicity, we use the same data in the test programs for _to_base_num() and
# _from_base_num().

my @data =
  (
   [ 0, 2, [ 0 ] ],
   [ 1, 2, [ 1 ] ],
   [ 2, 2, [ 1, 0 ] ],
   [ 3, 2, [ 1, 1, ] ],
   [ 4, 2, [ 1, 0, 0 ] ],

   [ 0, 10, [ 0 ] ],
   [ 1, 10, [ 1 ] ],
   [ 12, 10, [ 1, 2 ] ],
   [ 123, 10, [ 1, 2, 3 ] ],
   [ 1230, 10, [ 1, 2, 3, 0 ] ],

   [ "123456789", 100, [ 1, 23, 45, 67, 89 ] ],

   [ "1234567890" x 3,
     "987654321",
     [ "128", "142745769", "763888804", "574845669" ]],

   [ "1234567890" x 5,
     "987654321" x 3,
     [ "12499999874843750102814", "447551941015330718793208596" ]],
  );

# List context.

for (my $i = 0 ; $i <= $#data ; ++ $i) {
    my @in   = @{ $data[$i] };
    my $out0 = pop @in;

    my ($x, @got);

    # We test with the base given as a scalar and as a reference.

    for my $base_as_scalar (0, 1) {

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        $test .= $base_as_scalar ? qq| \$b = $in[1];|
                                 : qq| \$b = $LIB->_new("$in[1]");|;
        $test .= qq| \@got = $LIB->_to_base_num(\$x, \$b)|;

        $x = $LIB->_new($in[0]);
        $b = $base_as_scalar ? $in[1]
                             : $LIB->_new($in[1]);
        @got = $LIB->_to_base_num($x, $b);

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        subtest "_to_base_num() in list context: $test", sub {
            plan tests => 3 + 2 * @$out0,

            cmp_ok(scalar @got, '==', 1,
                   "'$test' gives one output arg");

            is(ref($got[0]), "ARRAY",
               "'$test' output arg is an ARRAY");

            is(scalar(@{ $got[0] }), scalar(@$out0),
               "'$test' output array has the right number of elements");

            for my $i (0 .. $#$out0) {
                my $ref = ref($got[0][$i]);
                ok($ref eq $REF || $ref eq $LIB,
                   "'$test' output: element $i is a $ref")
                  or diag(<<"EOF");
         got: $ref
    expected: $REF or $LIB
EOF
            }

            for my $i (0 .. $#$out0) {
                is($LIB->_str($got[0][$i]), $out0->[$i],
                   "'$test' output: element $i has the right value");
            }
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

        my $test = qq|\$x = $LIB->_new("$in[0]");|;
        $test .= $base_as_scalar ? qq| \$b = $in[1];|
                                 : qq| \$b = $LIB->_new("$in[1]");|;
        $test .= qq| \$got = $LIB->_to_base_num(\$x, \$b)|;

        $x = $LIB->_new($in[0]);
        $b = $base_as_scalar ? $in[1]
                             : $LIB->_new($in[1]);
        $got = $LIB->_to_base_num($x, $b);

        diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

        subtest "_to_base_num() in scalar context: $test", sub {
            plan tests => 2 + 2 * @$out0,

            is(ref($got), "ARRAY",
               "'$test' output arg is an ARRAY");

            is(scalar(@$got), scalar(@$out0),
               "'$test' output array has the right number of elements");

            for my $i (0 .. $#$out0) {
                my $ref = ref($got->[$i]);
                ok($ref eq $REF || $ref eq $LIB,
                   "'$test' output: element $i is a $ref")
                  or diag(<<"EOF");
         got: $ref
    expected: $REF or $LIB
EOF
            }

            for my $i (0 .. $#$out0) {
                is($LIB->_str($got->[$i]), $out0->[$i],
                   "'$test' output: element $i has the right value");
            }
        };
    }
}
