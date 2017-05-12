#!perl

use strict;
use warnings;

use Test::More tests => 6;

use ICal::Format::Natural qw(ical_format_natural);

use Data::ICal;
use DateTime::Format::ICal;

my $result;

# no date or summary
$result = ical_format_natural('foo');
error_ok($result);

# no date, with summary
$result = ical_format_natural('foo. summary');
error_ok($result);

# no summary
$result = ical_format_natural('Mar 31 1976 at 12:34.');
error_ok($result);

# correct date and summary
$result = ical_format_natural('Mar 31 1976 at 12:34. Lunch with Bob');
isa_ok( $result, 'Data::ICal' );
is( @{ $result->entries }[0]->property('summary')->[0]->value,
    'Lunch with Bob' );
my $time = DateTime::Format::ICal->parse_datetime(
    @{ $result->entries }[0]->property('dtstart')->[0]->value );
is( $time->datetime, '1976-03-31T12:34:00' );

# expects $r to be an error
sub error_ok {
    my $r = shift;
    like( $r, qr/^error/i, "$r is an error" );
}
