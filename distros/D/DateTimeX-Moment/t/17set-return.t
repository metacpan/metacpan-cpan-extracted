use strict;
use warnings;

use Test::More;

use DateTimeX::Moment;
use DateTimeX::Moment::Duration;

{
    my $dt = DateTimeX::Moment->new( year => 2008, month => 2, day => 28 );
    my $du = DateTimeX::Moment::Duration->new( years => 1 );

    my $p;

    $p = $dt->set( year => 1882 );
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "set() returns self" );

    if (eval { require DateTime::Duration; 1 }) {
        $p = $dt->set_time_zone('Australia/Sydney');
        is( DateTimeX::Moment->compare( $p, $dt ), 0, "set_time_zone() returns self" );
    }

    $p = $dt->add_duration($du);
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "add_duration() returns self" );

    $p = $dt->add( years => 2 );
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "add() returns self" );

    $p = $dt->subtract_duration($du);
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "subtract_duration() returns self" );

    $p = $dt->subtract( years => 3 );
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "subtract() returns self" );

    $p = $dt->truncate( to => 'day' );
    is( DateTimeX::Moment->compare( $p, $dt ), 0, "truncate() returns self" );

}

done_testing();
