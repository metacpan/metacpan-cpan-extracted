use strict;
use warnings;
use Test::More;
use DateTime;

use_ok( 'Diabetes::Glucose' );

my @pairs = ( 
    [ mgdl => 103 ],
    [ mgdl => 200 ],
    [ mmol => 5.6 ],
    [ mmol => 30.2 ],
    [ mgdl => 0 ],
    [ mmol => 0 ],
);


for my $pair ( @pairs ) { 
    my $dt = DateTime->now;
    my $d = new_ok( 'Diabetes::Glucose', [ 
            $pair->[0] => $pair->[1],
            comment => 'test comment',
            source => 'source 1',
            stamp => $dt
        ] );

    if( $pair->[0] eq 'mgdl' ) { 
        is( $d->mgdl, $pair->[1], "Stored the right mgdl value" );
        is( $d->mmol, $pair->[1] / 18.5, "Stored the right mmol number?" );
    }
    if( $pair->[0] eq 'mmol' ) { 
        is( $d->mmol, $pair->[1], "Stored the right mmol value" );
        is( $d->mgdl, $pair->[1] * 18.5, "Stored the right mgdl number?" );
    }
    is( $d->comment, 'test comment', 'Stored the right comment' );
    is( $d->source, 'source 1', 'stored the right source' );
    is( DateTime->compare( $dt, $d->stamp ), 0 , 'Got the right dt, right?' );
}

done_testing;
