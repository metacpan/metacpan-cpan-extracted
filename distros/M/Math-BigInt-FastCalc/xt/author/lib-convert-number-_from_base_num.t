#!perl

use strict;
use warnings;

use Test::More tests => 105;

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

can_ok($LIB, '_from_base_num');

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
    my @in   = ($data[$i][2], $data[$i][1]);
    my $out0 = $data[$i][0];

    my ($x, @got);

    # We test with the base given as a scalar and as a reference.

    for my $base_as_scalar (1, 0) {
        for my $elements_as_scalar (1, 0) {

            my $test = "\@got = $LIB->_from_base_num([";
            if ($elements_as_scalar) {
                $test .= join ", ", map qq|"$_"|, @{ $in[0] };
            } else {
                $test .= join ", ", map qq|$LIB->_new("$_")|, @{ $in[0] };
            }
            $test .= "], ";
            if ($base_as_scalar) {
                $test .= qq|"$in[1]"|;
            } else {
                $test .= qq|$LIB->_new("$in[1]")|;
            }
            $test .= ")";

            diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

            eval $test;
            is($@, "", "'$test' gives emtpy \$\@");

            subtest "_from_base_num() in list context: $test", sub {
                plan tests => 4,

                cmp_ok(scalar @got, '==', 1,
                       "'$test' gives one output arg");

                is(ref($got[0]), $REF,
                   "'$test' output arg is a $REF");

                is($LIB->_check($got[0]), 0,
                   "'$test' output is valid");

                is($LIB->_str($got[0]), $out0,
                   "'$test' output arg has the right value");
            };
        }
    }
}
