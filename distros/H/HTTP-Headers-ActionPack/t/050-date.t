
#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::DateHeader');
}

sub test_date {
    my $h = shift;

    isa_ok($h, 'HTTP::Headers::ActionPack::DateHeader');

    is( $h->day, 'Mon', '... got the day');
    is( $h->month, 'Apr', '... got the month');
    is( $h->year, 2012, '... got the year');
    is( $h->hour, 14, '... got the hour');
    is( $h->minute, 14, '... got the minute');
    is( $h->second, 19, '... got the second');

    is( $h->as_string, 'Mon, 23 Apr 2012 14:14:19 GMT', '... got the expected string');
}

test_date(
    HTTP::Headers::ActionPack::DateHeader->new_from_string('Mon, 23 Apr 2012 14:14:19 GMT')
);

test_date(
    HTTP::Headers::ActionPack::DateHeader->new(
        scalar Time::Piece->gmtime( HTTP::Date::str2time( 'Mon, 23 Apr 2012 14:14:19 GMT' ) )
    )
);

done_testing;