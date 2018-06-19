#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use lib 'lib';

BEGIN {
    *CORE::GLOBAL::time = sub() {1437072205};
}

use Test::Most;
use InfluxDB::LineProtocol qw(data2line line2data);

my @faketime = ( 1437072205, 500681 );
{
    no warnings 'redefine';

    sub InfluxDB::LineProtocol::gettimeofday() {
        wantarray ? @faketime : join( '.', @faketime );
    }
};

is( InfluxDB::LineProtocol::ts_ns, '1437072205500681000', 'nanoseconds' );
is( InfluxDB::LineProtocol::ts_us, '1437072205500681',    'microsecond' );
is( InfluxDB::LineProtocol::ts_ms, '1437072205500',       'millisecond' );
is( InfluxDB::LineProtocol::ts_s,  '1437072205',          'seconds' );
is( InfluxDB::LineProtocol::ts_m,  '23951203',            'minutes' );
is( InfluxDB::LineProtocol::ts_h,  '399186',              'hours' );

{
    package TsDefault;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line));
    my $line = data2line( 'default', 1 );
    is( $line,
        'default value=1i 1437072205500681000',
        'line with default nanosecs'
    );
}

{
    package TsNano;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=ns));
    my $line = data2line( 'nano', 1 );
    is( $line, 'nano value=1i 1437072205500681000', 'line with nanosecs' );
}

{
    package TsMicro;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=us));
    my $line = data2line( 'micro', 1 );
    is( $line, 'micro value=1i 1437072205500681', 'line with microsecs' );
}

{
    package TsMilli;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=ms));
    my $line = data2line( 'milli', 1 );
    is( $line, 'milli value=1i 1437072205500', 'line with milliseconds' );
}

{
    package TsSec;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=s));
    my $line = data2line( 'sec', 1 );
    is( $line, 'sec value=1i 1437072205', 'line with seconds' );
}

{
    package TsMin;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=m));
    my $line = data2line( 'min', 1 );
    is( $line, 'min value=1i 23951203', 'line with minutes' );
}

{
    package TsHour;
    use Test::Most;
    InfluxDB::LineProtocol->import(qw(data2line precision=h));
    my $line = data2line( 'hour', 1 );
    is( $line, 'hour value=1i 399186', 'line with hours' );
}

package main;

done_testing();
