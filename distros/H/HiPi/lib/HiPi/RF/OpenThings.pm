#########################################################################################
# Package        HiPi::RF::OpenThings
# Description  : OpenThings protocol element naming
# Copyright    : Copyright (c) 2017 - 2023 Mark Dootson
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
my $parameters = {};

our $VERSION ='0.89';

for my $manutemplate
(
    [ OPENTHINGS_MANUFACTURER_ENERGENIE, 'Energenie' ],
    [ OPENTHINGS_MANUFACTURER_HILDERBRAND, 'Hilderbrand' ],
    [ OPENTHINGS_MANUFACTURER_SENTEC, 'Sentec' ],
    [ OPENTHINGS_MANUFACTURER_RASPBERRY , 'Local Raspberry Project' ],
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

for my $paramtemplate
(
    [ OPENTHINGS_PARAM_ALARM             , 'Alarm', '' ],
    [ OPENTHINGS_PARAM_DEBUG_OUTPUT      , 'Debug Output', '' ],
    [ OPENTHINGS_PARAM_IDENTIFY          , 'Identify', '' ],
    [ OPENTHINGS_PARAM_SOURCE_SELECTOR   , 'Source Selector', '' ],
    [ OPENTHINGS_PARAM_WATER_DETECTOR    , 'Water Detector', '' ],
    [ OPENTHINGS_PARAM_GLASS_BREAKAGE    , 'Glass Breakage', '' ],
    [ OPENTHINGS_PARAM_CLOSURES          , 'Closures', '' ],
    [ OPENTHINGS_PARAM_DOOR_BELL         , 'Door Bell', '' ],
    [ OPENTHINGS_PARAM_ENERGY            , 'Energy', 'kWh' ],
    [ OPENTHINGS_PARAM_FALL_SENSOR       , 'Fall Sensor', '' ],
    [ OPENTHINGS_PARAM_GAS_VOLUME        , 'Gas Volume', 'm3' ],
    [ OPENTHINGS_PARAM_AIR_PRESSURE      , 'Air Pressure', 'mbar' ],
    [ OPENTHINGS_PARAM_ILLUMINANCE       , 'Illuminance', 'Lux' ],
    [ OPENTHINGS_PARAM_LEVEL             , 'Level', '' ],
    [ OPENTHINGS_PARAM_RAINFALL          , 'Rainfall', 'mm' ],
    [ OPENTHINGS_PARAM_APPARENT_POWER    , 'Apparent Power', 'VA' ],
    [ OPENTHINGS_PARAM_POWER_FACTOR      , 'Power Factor', '' ],
    [ OPENTHINGS_PARAM_REPORT_PERIOD     , 'Report Period', 's' ],
    [ OPENTHINGS_PARAM_SMOKE_DETECTOR    , 'Smoke Detector', '' ],
    [ OPENTHINGS_PARAM_TIME_AND_DATE     , 'Time and Date', 's' ],
    [ OPENTHINGS_PARAM_VIBRATION         , 'Vibration', '' ],
    [ OPENTHINGS_PARAM_WATER_VOLUME      , 'Water Volume', 'l' ],
    [ OPENTHINGS_PARAM_WIND_SPEED        , 'Wind Speed', 'm/s' ],
    [ OPENTHINGS_PARAM_GAS_PRESSURE      , 'Gas Pressure', 'Pa' ],
    [ OPENTHINGS_PARAM_BATTERY_LEVEL     , 'Battery Level', 'V' ],
    [ OPENTHINGS_PARAM_CO_DETECTOR       , 'Carbon Monoxide Detector', '' ],
    [ OPENTHINGS_PARAM_DOOR_SENSOR       , 'Door Sensor', '' ],
    [ OPENTHINGS_PARAM_EMERGENCY         , 'Emergency', '' ],
    [ OPENTHINGS_PARAM_FREQUENCY         , 'Frequency', 'Hz' ],
    [ OPENTHINGS_PARAM_GAS_FLOW_RATE     , 'Gas Flow Rate', 'm3/hr' ],
    [ OPENTHINGS_PARAM_RELATIVE_HUMIDITY , 'Relative Humidity', '%' ],
    [ OPENTHINGS_PARAM_CURRENT           , 'Current', 'A' ],
    [ OPENTHINGS_PARAM_JOIN              , 'Join', '' ],
    [ OPENTHINGS_PARAM_LIGHT_LEVEL       , 'Light Level', '' ],
    [ OPENTHINGS_PARAM_MOTION_DETECTOR   , 'Motion Detector', '' ],
    [ OPENTHINGS_PARAM_OCCUPANCY         , 'Occupancy', '' ],
    [ OPENTHINGS_PARAM_REAL_POWER        , 'Real Power', 'W' ],
    [ OPENTHINGS_PARAM_REACTIVE_POWER    , 'Reactive Power', 'VAR' ],
    [ OPENTHINGS_PARAM_ROTATION_SPEED    , 'Unknown - 114', '' ],
    [ OPENTHINGS_PARAM_SWITCH_STATE      , 'Switch State', '' ],
    [ OPENTHINGS_PARAM_TEMPERATURE       , 'Temperature', 'C' ],
    [ OPENTHINGS_PARAM_VOLTAGE           , 'Voltage', 'V' ],
    [ OPENTHINGS_PARAM_WATER_FLOW_RATE   , 'Water Flow Rate', 'l/hr' ],
    [ OPENTHINGS_PARAM_WATER_PRESSURE    , 'Water Pressure', 'Pa' ],
    [ OPENTHINGS_PARAM_PHASE_1_POWER     , 'Phase 1 Power', 'W' ],
    [ OPENTHINGS_PARAM_PHASE_2_POWER     , 'Phase 2 Power', 'W' ],
    [ OPENTHINGS_PARAM_PHASE_3_POWER     , 'Phase 3 Power', 'W' ],
    [ OPENTHINGS_PARAM_3_PHASE_TOTAL     , '3 Phase Total Power', 'W' ],
)
{
    __PACKAGE__->register_parameter( @$paramtemplate );
}

sub register_parameter {
    my($class, $paramid, $name, $units ) = @_;

    $paramid //= 0;
    if ($paramid !~ /^[0-9]+$/) {
        die q(Invalid parameter id. Needs number);
    }
    
    if ( $paramid == 0 ) {
        die q(Invalid zero parameter id);
    }
    
    $paramid &= 0x7F;
    
    if ( $paramid == 0 ) {
        die q(Invalid parameter id - must be less than 128);
    }
    
    if (exists($parameters->{$paramid})) {
        die sprintf(qq(Parameter id 0x%x already exists as %s), $paramid, $parameters->{$paramid}->{name});
    }
    
    $units ||= '';
    $name  ||= sprintf(q(Custom Parameter 0x%x), $paramid);
    $parameters->{$paramid} = { name => $name, units => $units};   
    
    return;
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
    
    if (exists( $parameters->{$param} )) {
        $name  = $parameters->{$param}->{name};
        $units = $parameters->{$param}->{units};
    }
    
    return ( wantarray ) ? ( $name, $units ) : $name;
}

sub record_type_name {
    my($class, $typeid) = @_;
    
    $typeid //= -1;
    
    if ( $typeid == OPENTHINGS_UINT ) {
        return 'Unsigned Integer';
    } elsif ( $typeid == OPENTHINGS_UINT_BP4 ) {
        return 'Unsigned Integer.4';
    } elsif ( $typeid == OPENTHINGS_UINT_BP8 ) {
        return 'Unsigned Integer.8';
    } elsif ( $typeid == OPENTHINGS_UINT_BP12 ) {
        return 'Unsigned Integer.12';
    } elsif ( $typeid == OPENTHINGS_UINT_BP16 ) {
        return 'Unsigned Integer.16';
    } elsif ( $typeid == OPENTHINGS_UINT_BP20 ) {
        return 'Unsigned Integer.20';
    } elsif ( $typeid == OPENTHINGS_UINT_BP24 ) {
        return 'Unsigned Integer.24';
    } elsif ( $typeid == OPENTHINGS_CHAR ) {
        return 'Character';
    } elsif ( $typeid == OPENTHINGS_SINT ) {
        return 'Signed Integer';
    } elsif ( $typeid == OPENTHINGS_SINT_BP8 ) {
        return 'Signed Integer.8';
    } elsif ( $typeid == OPENTHINGS_SINT_BP16 ) {
        return 'Signed Integer.16';
    } elsif ( $typeid == OPENTHINGS_SINT_BP24 ) {
        return 'Signed Integer.24';
    } elsif ( $typeid == OPENTHINGS_ENUMERATION ) {
        return 'Enumeration';
    } elsif ( $typeid == OPENTHINGS_FLOAT ) {
        return 'Float';
    } else {
        return 'Unknown';
    }
}

1;

__END__