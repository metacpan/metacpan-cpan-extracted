# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check setminus, setunion operations

use Test;
BEGIN { plan tests => 3 };
use Graph::ModularDecomposition qw(setminus setunion);

#########################

sub test4 {
    my $a = ['a','b','c','d','e'];
    my $b = ['c','e','f'];
    ok join('', setminus( $a, $b )), 'abd';
    ok join('', setunion( $a, $b )), 'abcdef';
    ok join('', setunion( $b, $a )), 'abcdef';
}


test4;
