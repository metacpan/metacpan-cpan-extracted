#########################################################################################
# Package        HiPi::RF::OpenThings
# Description  : OpenThings protocol element naming
# Copyright    : Copyright (c) 2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::RF::OpenThings;

#########################################################################################

use strict;
use warnings;
use HiPi qw( :openthings :energenie );


my $products = {};
my $manufacturers = {};

our $VERSION ='0.81';

for my $manutemplate
(
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, 'Energenie' ],
    [ OPENTHINGS_MANUFACTURER_HILDERBRAND, 'Hilderbrand' ],
    [ OPENTHINGS_MANUFACTURER_SENTEC, 'Sentec' ],
    [ OPENTHINGS_MANUFACTURER_RASPBERRY , 'Raspberry Pi Projects' ],
)
{
    __PACKAGE__->register_manufacturer( @$manutemplate );
}

for my $prodtemplate
(
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO004, 'Mi|Home Monitor', 0 ],
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO005, 'Mi|Home Adapter Plus', 1 ],
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO006, 'Mi|Home Whole House Monitor', 0 ],
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO013, 'Mi|Home Heating Valve', 0 ],
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO032, 'Mi|Home Motion Sensor', 0 ],
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, ENERGENIE_PRODUCT_ID_MIHO033, 'Mi|Home Open Sensor', 0 ],
)
{
    __PACKAGE__->register_product( @$prodtemplate );
}


sub register_product {
    my($class, $manu, $product, $name, $canswitch ) = @_;
    $products->{$manu}->{$product} = { name => $name, switch => $canswitch };
}

sub register_manufacturer {
    my($class, $manu, $name ) = @_;
    $manufacturers->{$manu} = $name;
}

sub product_name {
    my($class, $manu, $product ) = @_;
    if(exists($products->{$manu}) && exists($products->{$manu}->{$product}) ) {
        return $products->{$manu}->{$product}->{name};
    }
    return 'Unknown Product ' . $class ->format_product_id( $product );
}

sub product_can_switch {
    my($class, $manu, $product ) = @_;
    if(exists($products->{$manu}) && exists($products->{$manu}->{$product}) ) {
        return $products->{$manu}->{$product}->{switch};
    }
    return 0;
}

sub manufacturer_name {
    my($class, $manu ) = @_;
    if(exists($manufacturers->{$manu})) {
        return $manufacturers->{$manu};
    }
    return 'Unknown Manufacturer ' . $class ->format_manufacturer_id( $manu );
}

sub format_sensor_key {
    my( $class, $mid, $pid, $sid ) = @_;
    my $key = sprintf(qq(%04X-%04X-%06X), $mid || 0, $pid || 0, $sid || 0);
    return $key;
}

sub format_manufacturer_id {
    my ($class, $id) = @_;
    return sprintf('0x%04X', $id);
}

sub format_product_id {
    my ($class, $id) = @_;
    return sprintf('0x%04X', $id);
}

sub format_sensor_id {
    my ($class, $id) = @_;
    return sprintf('0x%06X', $id);
}

sub parameter_map {
    my ($class, $param ) = @_;
    
    unless( defined( $param ) ) {
        my $undefname = 'Parameter Undefined';
        return ( wantarray ) ? ( $undefname, '' ) : $undefname;
    }
    
    my($name, $units) = ('Unknown - ' . $param, '');
    
    if ( $param == OPENTHINGS_PARAM_ALARM ) {
        $name = 'Alarm';
    } elsif( $param == OPENTHINGS_PARAM_DEBUG_OUTPUT ) {
        $name = 'Debug Output';
    } elsif( $param == OPENTHINGS_PARAM_IDENTIFY ) {
        $name = 'Identify';
    } elsif( $param == OPENTHINGS_PARAM_SOURCE_SELECTOR ) {
        $name = 'Source Selector';
    } elsif( $param == OPENTHINGS_PARAM_WATER_DETECTOR ) {
        $name = 'Water Detector';
    } elsif( $param == OPENTHINGS_PARAM_GLASS_BREAKAGE ) {
        $name = 'Glass Breakage';
    } elsif( $param == OPENTHINGS_PARAM_CLOSURES ) {
        $name = 'Closures';
    } elsif( $param == OPENTHINGS_PARAM_DOOR_BELL ) {
        $name = 'Door Bell';
    } elsif( $param == OPENTHINGS_PARAM_ENERGY ) {
        $name = 'Energy';
        $units = 'kWh'
    } elsif( $param == OPENTHINGS_PARAM_FALL_SENSOR ) {
        $name = 'Fall Sensor';
    } elsif( $param == OPENTHINGS_PARAM_GAS_VOLUME ) {
        $name = 'Gas Volume';
        $units = 'm3';
    } elsif( $param == OPENTHINGS_PARAM_AIR_PRESSURE ) {
        $name = 'Air Pressure';
        $units = 'mbar';
    } elsif( $param == OPENTHINGS_PARAM_ILLUMINANCE ) {
        $name = 'Illuminance';
        $units = 'Lux';
    } elsif( $param == OPENTHINGS_PARAM_LEVEL ) {
        $name = 'Level';
    } elsif( $param == OPENTHINGS_PARAM_RAINFALL ) {
        $name = 'Rainfall';
        $units = 'mm';
    } elsif( $param == OPENTHINGS_PARAM_APPARENT_POWER ) {
        $name = 'Apparent Power';
        $units = 'VA';
    } elsif( $param == OPENTHINGS_PARAM_POWER_FACTOR ) {
        $name = 'Power Factor';
    } elsif( $param == OPENTHINGS_PARAM_REPORT_PERIOD ) {
        $name = 'Report Period';
        $units = 's';
    } elsif( $param == OPENTHINGS_PARAM_SMOKE_DETECTOR ) {
        $name = 'Smoke Detector';
    } elsif( $param == OPENTHINGS_PARAM_TIME_AND_DATE ) {
        $name = 'Time and Date';
        $units = 's';
    } elsif( $param == OPENTHINGS_PARAM_VIBRATION ) {
        $name = 'Vibration';
    } elsif( $param == OPENTHINGS_PARAM_WATER_VOLUME ) {
        $name = 'Water Volume';
        $units = 'l';
    } elsif( $param == OPENTHINGS_PARAM_WIND_SPEED ) {
        $name = 'Wind Speed';
        $units = 'm/s';
    } elsif( $param == OPENTHINGS_PARAM_GAS_PRESSURE ) {
        $name = 'Gas Pressure';
        $units = 'Pa';
    } elsif( $param == OPENTHINGS_PARAM_BATTERY_LEVEL ) {
        $name = 'Battery Level';
        $units = 'V';
    } elsif( $param == OPENTHINGS_PARAM_CO_DETECTOR ) {
        $name = 'Carbon Monoxide Detector';
    } elsif( $param == OPENTHINGS_PARAM_DOOR_SENSOR ) {
        $name = 'Door Sensor';
    } elsif( $param == OPENTHINGS_PARAM_EMERGENCY ) {
        $name = 'Emergency';
    } elsif( $param == OPENTHINGS_PARAM_FREQUENCY ) {
        $name = 'Frequency';
        $units = 'Hz';
    } elsif( $param == OPENTHINGS_PARAM_GAS_FLOW_RATE ) {
        $name = 'Gas Flow Rate';
        $units = 'm3/hr';
    } elsif( $param == OPENTHINGS_PARAM_RELATIVE_HUMIDITY ) {
        $name = 'Relative Humidity';
        $units = '%';
    } elsif( $param == OPENTHINGS_PARAM_CURRENT ) {
        $name = 'Current';
        $units = 'A';
    } elsif( $param == OPENTHINGS_PARAM_JOIN ) {
        $name = 'Join';
    } elsif( $param == OPENTHINGS_PARAM_LIGHT_LEVEL ) {
        $name = 'Light Level';
    } elsif( $param == OPENTHINGS_PARAM_MOTION_DETECTOR ) {
        $name = 'Motion Detector';
    } elsif( $param == OPENTHINGS_PARAM_OCCUPANCY ) {
        $name = 'Occupancy';
    } elsif( $param == OPENTHINGS_PARAM_REAL_POWER ) {
        $name = 'Real Power';
        $units = 'W';
    } elsif( $param == OPENTHINGS_PARAM_REACTIVE_POWER ) {
        $name = 'Reactive Power';
        $units = 'VAR';
    } elsif( $param == OPENTHINGS_PARAM_SWITCH_STATE ) {
        $name = 'Switch State';
    } elsif( $param == OPENTHINGS_PARAM_TEMPERATURE ) {
        $name = 'Temperature';
        $units = 'C';
    } elsif( $param == OPENTHINGS_PARAM_VOLTAGE ) {
        $name = 'Voltage';
        $units = 'V';
    } elsif( $param == OPENTHINGS_PARAM_WATER_FLOW_RATE ) {
        $name = 'Water Flow Rate';
        $units = 'l/hr';
    } elsif( $param == OPENTHINGS_PARAM_WATER_PRESSURE ) {
        $name = 'Water Pressure';
        $units = 'Pa';
    } elsif( $param == OPENTHINGS_PARAM_PHASE_1_POWER ) {
        $name = 'Phase 1 Power';
        $units = 'W';
    } elsif( $param == OPENTHINGS_PARAM_PHASE_2_POWER ) {
        $name = 'Phase 2 Power';
        $units = 'W';
    } elsif( $param == OPENTHINGS_PARAM_PHASE_3_POWER ) {
        $name = 'Phase 3 Power';
        $units = 'W';
    } elsif( $param == OPENTHINGS_PARAM_3_PHASE_TOTAL ) {
        $name = '3 Phase Total Power';
        $units = 'W';
    } elsif( $param == OPENTHINGS_PARAM_TEST ) {
        $name = 'Test';
    }
    return ( wantarray ) ? ( $name, $units ) : $name;
}

1;

__END__