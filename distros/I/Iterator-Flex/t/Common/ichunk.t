#! perl

use Test2::V0;
use Iterator::Flex::Common qw[ iseq  ];

my $iter = iseq( 12 )->ichunk( { capacity => 5 } );

for my $label ( 'initial', 'reset' ) {
    subtest $label => sub {
        is( $iter->next, [ 0 .. 4 ],   '1' );
        is( $iter->next, [ 5 .. 9 ],   '2' );
        is( $iter->next, [ 10 .. 12 ], '3' );
        ok( $iter->is_exhausted, 'exhausted' );
        $iter->reset;
    };
}


done_testing;
