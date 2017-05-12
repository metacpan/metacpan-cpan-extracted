use strict;
use warnings;

use Test::More;

use DateTimeX::Moment;

my $dt1 = DateTimeX::Moment->new( year => 1970, hour => 1, nanosecond => 100 );

my $dt2 = DateTimeX::Moment->from_object( object => $dt1 );

is( $dt1->year,       1970, 'year is 1970' );
is( $dt1->hour,       1,    'hour is 1' );
is( $dt1->nanosecond, 100,  'nanosecond is 100' );

{
    my $t1 = DateTime::Calendar::_Test::WithoutTZ->new(
        rd_days => 1,
        rd_secs => 0
    );

    # Tests creating objects from other calendars (without time zones)
    my $t2 = DateTimeX::Moment->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Moment' );
    is(
        $t2->datetime, '0001-01-01T00:00:00',
        'convert from object without tz'
    );
    ok( $t2->time_zone->is_floating, 'time_zone is floating' );
}

if (eval { require DateTime::Duration; 1 }) {
    my $tz = DateTime::TimeZone->new( name => 'America/Chicago' );
    my $t1 = DateTime::Calendar::_Test::WithTZ->new(
        rd_days   => 2, rd_secs => 0,
        time_zone => $tz
    );

    # Tests creating objects from other calendars (with time zones)
    my $t2 = DateTimeX::Moment->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Moment' );
    is( $t2->time_zone->name, 'America/Chicago', 'time_zone is preserved' );
}

{
    my $tz = DateTime::TimeZone->new( name => 'UTC' );
    my $t1 = DateTime::Calendar::_Test::WithTZ->new(
        rd_days => 720258,
        rd_secs => 86400, time_zone => $tz
    );

    my $t2 = DateTimeX::Moment->from_object( object => $t1 );

    isa_ok( $t2, 'DateTimeX::Moment' );
}

done_testing();

# Set up two simple test packages

package DateTime::Calendar::_Test::WithoutTZ;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub utc_rd_values {
    return $_[0]{rd_days}, $_[0]{rd_secs}, 0;
}

sub __as_Time_Moment {
    my $self = shift;
    require Time::Moment;
    return Time::Moment->from_rd($self->{rd_days})->plus_seconds($self->{rd_secs});
}

package DateTime::Calendar::_Test::WithTZ;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub utc_rd_values {
    return $_[0]{rd_days}, $_[0]{rd_secs}, 0;
}

sub time_zone {
    return $_[0]{time_zone};
}

sub __as_Time_Moment {
    my $self = shift;
    require Time::Moment;
    return Time::Moment->from_rd($self->{rd_days})->plus_seconds($self->{rd_secs});
}
