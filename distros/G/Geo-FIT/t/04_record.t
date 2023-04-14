# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 13;
use Geo::FIT;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

$o->file( 't/10004793344_ACTIVITY.fit' );

# a few defaults: may change some of these later but picking the same value as in fit2tcx.pl
$o->use_gmtime(1);
$o->numeric_date_time(0);
$o->semicircles_to_degree(1);
$o->without_unit(1);
$o->mps_to_kph(0);

my @must = ('Time');
my $include_creator = 1;

# expected values
my $j = 0;
my @expect_time = qw( 2022-11-19T22:10:21Z 2022-11-19T22:10:30Z );
my @expect_lat  = qw( 45.3913221 45.3913397 );
my @expect_lon  = qw( -75.7397311 -75.7397672 );
my @expect_altitude = qw( 75.4 75.4 );
my @expect_distance = qw( 0.00 3.26 );
my @expect_speed    = qw( 0.000 1.484 );

# tests are run via callbacks (many copied from fit2tcx.pl)

my $cb_record = sub {
    my ($obj, $desc, $v, $memo) = @_;
    my (%tp, $lat, $lon, $speed, $watts);

    $tp{Time} = $obj->named_type_value($desc->{t_timestamp}, $v->[$desc->{i_timestamp}]);
    $memo->{id} = $tp{Time} if !defined $memo->{id};

    # $desc->{i_timestamp} shows it is at index 1 and $desc->{t_timestamp} says it's a date_time
    is( $tp{Time}, $expect_time[$j],   "   test named_type_value() -- timestamp");

    $lat = $obj->value_processed($v->[$desc->{i_position_lat}], $desc->{a_position_lat})
        if defined $desc->{i_position_lat} && $v->[$desc->{i_position_lat}] != $desc->{I_position_lat};

    $lon = $obj->value_processed($v->[$desc->{i_position_long}], $desc->{a_position_long})
        if defined $desc->{i_position_long} && $v->[$desc->{i_position_long}] != $desc->{I_position_long};

    is( $lat, $expect_lat[$j],  "   test value_processed() -- latitude");
    is( $lon, $expect_lon[$j],  "   test value_processed() -- longitude");

    if (defined $desc->{i_enhanced_altitude} && $v->[$desc->{i_enhanced_altitude}] != $desc->{I_enhanced_altitude}) {
        $tp{AltitudeMeters} = $obj->value_processed($v->[$desc->{i_enhanced_altitude}], $desc->{a_enhanced_altitude})
    } elsif (defined $desc->{i_altitude} && $v->[$desc->{i_altitude}] != $desc->{I_altitude}) {
        $tp{AltitudeMeters} = $obj->value_processed($v->[$desc->{i_altitude}], $desc->{a_altitude})
    }
    is( $tp{AltitudeMeters}, $expect_altitude[$j],  "   test value_processed() -- altitude");

    $tp{DistanceMeters} = $obj->value_processed($v->[$desc->{i_distance}], $desc->{a_distance})
        if defined $desc->{i_distance} && $v->[$desc->{i_distance}] != $desc->{I_distance};

    is( $tp{DistanceMeters}, $expect_distance[$j],  "   test value_processed() -- distance");

    if (defined $desc->{i_enhanced_speed} && $v->[$desc->{i_enhanced_speed}] != $desc->{I_enhanced_speed}) {
        $speed = $obj->value_processed($v->[$desc->{i_enhanced_speed}], $desc->{a_enhanced_speed})
    } elsif (defined $desc->{i_speed} && $v->[$desc->{i_speed}] != $desc->{I_speed}) {
        $speed = $obj->value_processed($v->[$desc->{i_speed}], $desc->{a_speed})
    }

    if (defined $speed || defined $watts) {
        my %tpx;
        $tpx{Speed} = $speed if defined $speed;
        $tpx{Watts} = $watts if defined $watts;
        $tp{Extensions} = +{'TPX' => \%tpx};
        is( $tpx{Speed}, $expect_speed[$j],  "   test value_processed() -- speed");
    }

    my $miss;
    for my $k (@must) {
        defined $tp{$k} or ++$miss
    }
    push @{$memo->{tpv}}, \%tp if !$miss;
    ++$j;
    1
    };

my $memo = { 'tpv' => [], 'trackv' => [], 'lapv' => [], 'av' => [] };
# TODO: need to define what these keys are (what does v stand for, value?)
# add a breakpoint at 636 of fit2tcx.pl and x $memo (a stands for activity)
$o->data_message_callback_by_name('record', $cb_record, $memo) or die $o->error;

#
# A - test value_processed() and named_type_value() with the above callbacks

my (@header_things, $ret_val);

$o->open or die $o->error;
@header_things = $o->fetch_header;

($j, $ret_val) = (0, undef);

while ( my $ret = $o->fetch ) {
    # we are testing with callbacks, so not much to do here
    last if $j==2
}
$o->close();

print "so debugger doesn't exit\n";

