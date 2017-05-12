#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use ok 'File::Chunk::Iter';

for ( 2, 5 ) {
    my $i = 0;
    my $iter = File::Chunk::Iter->new(
        iter => sub {
            if ($i++ >= 3) {
                return undef;
            }
            else {
                return $i;
            }
        },
        look_ahead => $_,
    );

    ok( !$iter->is_last, "not the last");
    ok( !$iter->is_done, "not done");

    is($iter->at(0), 1);
    is($iter->at(1), 2);
    if ($_ > 2) {
        is($iter->at(2), 3);
        is($iter->at(3), undef);
    }

    is( $iter->next, 1 );
    is( $iter->next, 2 );

    ok( !$iter->is_done, "not done");
    ok( $iter->is_last, "however, the next call to next() will return the last item.");
    is( $iter->next, 3 );
    ok($iter->is_done, "is done");
    ok($iter->is_last, "is last is false, but really this is undefined");
    is( $iter->next, undef );
    is( $iter->next, undef );
}

done_testing;
