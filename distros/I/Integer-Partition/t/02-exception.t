# 02-exception.t
#
# Test suite for Integer::Partition
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;
eval qq{use Test::Exception};
if( $@ ) {
    plan skip_all => 'Test::Exception is not installed';
}
else {
    plan tests => 5;
}

use Integer::Partition;

dies_ok( sub { Integer::Partition->new }, 'no input' );
dies_ok( sub { Integer::Partition->new(0) }, 'zero' );
dies_ok( sub { Integer::Partition->new(-999) }, 'negative' );
dies_ok( sub { Integer::Partition->new('abc') }, 'non-numeric' );
dies_ok( sub { Integer::Partition->new(12.34) }, 'decimal' );
