use strict;
use warnings;

use Test::More;

use DateTimeX::Moment;

{
    my $now   = DateTimeX::Moment->now;
    my $today = DateTimeX::Moment->today;

    is( $today->year,  $now->year,  'today->year' );
    is( $today->month, $now->month, 'today->month' );
    is( $today->day,   $now->day,   'today->day' );

    is( $today->hour,   0, 'today->hour' );
    is( $today->minute, 0, 'today->hour' );
    is( $today->second, 0, 'today->hour' );
}

done_testing();
