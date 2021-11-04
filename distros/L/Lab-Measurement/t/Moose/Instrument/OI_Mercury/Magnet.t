#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/is_absolute_error is_float/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;

use File::Spec::Functions 'catfile';
use YAML::XS;

my $log_file = catfile(qw/t Moose Instrument OI_Mercury Magnet.yml/);

my $mercury = mock_instrument(
    type     => 'OI_Mercury::Magnet',
    log_file => $log_file,
);

isa_ok( $mercury, 'Lab::Moose::Instrument::OI_Mercury::Magnet' );

# get_catalogue
my $catalogue = $mercury->get_catalogue();
like( $catalogue, qr/DEV:GRP/, "get_catalogue" );

# # get_temperature,
# # at our setup it shows 813K ?!
# is_absolute_error( $mercury->get_temperature(), 500, 500, "get_temperature" );

# # get_he_level
# my $level = $mercury->get_he_level();
# ok( $level > 10, "get_he_level" );

# # get_he_level_resistance
# my $res = $mercury->get_he_level_resistance();
# ok( $res > 0, "get_he_level_resistance" );

# # get_n2_level
# ok( $mercury->get_n2_level() > 10, "get_n2_level" );

# # get_n2_level_frequency
# ok( $mercury->get_n2_level_frequency() > 0, "get_n2_level_frequency" );

# # get_n2_level_counter
# ok( $mercury->get_n2_level_counter() > 0, "get_n2_level_counter" );

# oim_get_current
my $current = $mercury->oim_get_current();
if ( abs($current) > 0.001 ) {
    die "need zero current for test";
}
is_absolute_error( $current, 0, 0.001, "oim_get_current" );

# oim_get_field
is_absolute_error( $mercury->oim_get_field(), 0, 0.001, "oim_get_field" );

is( $mercury->oim_set_heater( value => "ON" ), "ON", "oim_set_heater" );

# oim_get_heater
is( $mercury->oim_get_heater(), "ON", "oim_get_heater" );

# current sweeprate
is(
    $mercury->oim_set_current_sweeprate( value => 0.001 ), 0.001,
    "oim_set_current_sweeprate"
);

is_float(
    $mercury->oim_get_current_sweeprate(), 0.001,
    "oim_set_current_sweeprate"
);

# field sweeprate
is_absolute_error(
    $mercury->oim_set_field_sweeprate( value => 0.0015 ), 0.0015, 0.0001,
    "oim_set_field_sweeprate"
);

is_absolute_error(
    $mercury->oim_get_field_sweeprate(), 0.0015, 0.0001,
    "oim_get_field_sweeprate"
);

# activity

is(
    $mercury->oim_set_activity( value => 'HOLD' ), "HOLD",
    "oim_set_activity"
);

is( $mercury->oim_get_activity(), 'HOLD', "oim_get_activity" );

# current setpoint
is(
    $mercury->oim_set_current_setpoint( value => 0.0012 ), 0.0012,
    "oim_set_current_setpoint"
);

is_float(
    $mercury->oim_get_current_setpoint(), 0.0012,
    "oim_get_current_setpoint"
);

# field setpoint
is_absolute_error(
    $mercury->oim_set_field_setpoint( value => 0.0023 ), 0.0023, 0.0001,
    "oim_set_field_setpoint"
);
is_absolute_error(
    $mercury->oim_get_field_setpoint(), 0.0023, 0.0001,
    "oim_get_field_setpoint"
);

# fieldconstant
ok( $mercury->oim_get_fieldconstant() > 10, "oim_get_fieldconstant" );

done_testing();
