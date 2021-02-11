use strict;
use warnings;

use Test::More;
eval 'use Test::Memory::Usage';
plan skip_all => 'Test::Memory::Usage required for testing memory usage' if $@;

use_ok( 'List::Uniq', ':all' );

my $count = 1000;

EXPLICITLY_NOT_FLATTEN: {
    note("running $count times explicitly not flattening");

    my $flatten = 0;
    memory_usage_start();
    for ( 0 ... $count ) {
        my @list = ( (1 ... 2000),(1000 ... 3000) );
        my @uniq = uniq( { flatten => $flatten }, @list );
    }
    memory_usage_ok();
}

IMPLICITLY_FLATTEN: {
    note("running $count times implicitly flattening");

    my $flatten = undef;
    memory_usage_start();
    for ( 0 ... $count ) {
        my @list = ( (1 ... 2000),(1000 ... 3000) );
        my @uniq = uniq( { flatten => $flatten }, @list );
    }
    memory_usage_ok();
}

EXPLICITLY_FLATTEN: {
    note("running $count times explicitly flattening");

    my $flatten = 1;
    memory_usage_start();
    for ( 0 ... $count ) {
        my @list = ( (1 ... 2000),(1000 ... 3000) );
        my @uniq = uniq( { flatten => $flatten }, @list );
    }
    memory_usage_ok();
}

done_testing();
