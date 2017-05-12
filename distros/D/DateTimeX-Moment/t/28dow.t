use strict;
use warnings;

use Test::More;

use DateTimeX::Moment;

{
    my $dt = DateTimeX::Moment->new( year => 1 );

    is( $dt->year,        1, 'year is 1' );
    is( $dt->month,       1, 'month is 1' );
    is( $dt->day,         1, 'day is 1' );
    is( $dt->day_of_week, 1, 'day of week is 1' );
}

{
    my $dt = DateTimeX::Moment->new( year => 1, month => 12, day => 31 );

    is( $dt->year,        1,  'year is 1' );
    is( $dt->month,       12, 'month is 12' );
    is( $dt->day,         31, 'day is 31' );
    is( $dt->day_of_week, 1,  'day of week is 1' );
}

SKIP: {
    skip 'Time::Moment supports date in anno Domini omly', 4;
    my $dt = DateTimeX::Moment->new( year => -1 );

    is( $dt->year,        -1, 'year is -1' );
    is( $dt->month,       1,  'month is 1' );
    is( $dt->day,         1,  'day is 1' );
    is( $dt->day_of_week, 5,  'day of week is 5' );
}

{
    my $dt = DateTimeX::Moment->new( year => 2 );

    is( $dt->year,        2, 'year is 2' );
    is( $dt->month,       1, 'month is 1' );
    is( $dt->day,         1, 'day is 1' );
    is( $dt->day_of_week, 2, 'day of week is 2' );
}

done_testing();
