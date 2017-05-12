use strict;
use warnings;

use Test::More;

use DateTimeX::Moment;

unless (eval { require DateTime::Duration; 1 }) {
    plan skip_all => 'DateTime::Duration is required to test it';
}

my $badlt_rx = qr/Invalid local time|local time [0-9\-:T]+ does not exist/;

{
    eval {
        DateTimeX::Moment->new(
            year => 2003, month     => 4, day => 6,
            hour => 2,    time_zone => 'America/Chicago',
        );
    };

    like( $@, $badlt_rx, 'exception for invalid time' );

    eval {
        DateTimeX::Moment->new(
            year => 2003, month  => 4,  day    => 6,
            hour => 2,    minute => 59, second => 59,
            time_zone => 'America/Chicago',
        );
    };
    like( $@, $badlt_rx, 'exception for invalid time' );
}

{
    eval {
        DateTimeX::Moment->new(
            year => 2003, month  => 4,  day    => 6,
            hour => 1,    minute => 59, second => 59,
            time_zone => 'America/Chicago',
        );
    };
    ok( !$@, 'no exception for valid time' );

    my $dt = DateTimeX::Moment->new(
        year => 2003, month => 4, day => 5,
        hour => 2,
        time_zone => 'America/Chicago',
    );

    eval { $dt->add( days => 1 ) };
    like( $@, $badlt_rx, 'exception for invalid time produced via add' );
}

done_testing();
