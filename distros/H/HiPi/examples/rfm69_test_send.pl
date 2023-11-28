#!/usr/bin/perl
use strict;
use warnings;

use HiPi 0.89;
use HiPi qw( :openthings :rpi :hrf69 :energenie :mcp23017 );
use Time::HiRes qw( usleep );
use HiPi::RF::OpenThings::Message;
use HiPi::RF::OpenThings;
use HiPi::Interface::HopeRF69;
use HiPi::Interface::MCP23017;
use Getopt::Long;

use constant {
    RFM69_TEST_OUTPUT_POWER => 0x1,
    RFM69_TEST_SPI_DEVICE   => 0x2,
    RFM69_TEST_SPI_CSS      => 0x3,
    RFM69_TEST_ITERATION    => 0x4,
    RFM69_TEST_RSSI         => 0x5,
    RFM69_TEST_PRODUCT      => 0x81,
};

HiPi::RF::OpenThings->register_parameter(RFM69_TEST_OUTPUT_POWER, 'Test Programmed Power', 'dBm');
HiPi::RF::OpenThings->register_parameter(RFM69_TEST_SPI_DEVICE, 'Test SPI Device', '');
HiPi::RF::OpenThings->register_parameter(RFM69_TEST_SPI_CSS, 'Test SPI CSS', '');
HiPi::RF::OpenThings->register_parameter(RFM69_TEST_ITERATION,  'Test Iteration', '');
HiPi::RF::OpenThings->register_parameter(RFM69_TEST_RSSI,  'Test RSSI', 'dBm');
HiPi::RF::OpenThings->register_product(
    OPENTHINGS_MANUFACTURER_RASPBERRY, RFM69_TEST_PRODUCT, 'RFM69 Test Messager', 0
);


my $options = {
    high_power_module => 0,
    reset_gpio        => RPI_PIN_22,
    device            => '/dev/spidev0.1',
    power             => 10,
    sensor_key        => undef,
    pa1_limit         => 10,
    command           => 0,
    send_frequency    => 5,
};

GetOptions( $options,
    'high_power_module|h:i',
    'reset_gpio|r:s',
    'power|p:i',
    'device|d:s',
    'sensor_key|s:s',
    'pa1_limit|l:i',
    'command|c!',
    'send_frequency|f:i',
);

my $mcp;

if ($options->{reset_gpio} eq 'code') {
    $mcp = HiPi::Interface::MCP23017->new(
        devicename => '/dev/i2c-1',
        address    => 0x20,
    );
    $mcp->pin_mode( MCP_PIN_A1, MCP23017_OUTPUT);
    $mcp->pin_value( MCP_PIN_A1, 0 );
    
    $options->{reset_gpio} = sub {
        my $value = shift;
        $mcp->pin_value( MCP_PIN_A1, $value );
    };
}

##############################################################
## settings
##############################################################

# do you have an RF69MHW / RF69MHCW high power module ?
my $high_power_module = $options->{high_power_module};

# You need to define which GPIO pin is connected to the module
# reset pin.
# For the Energenie ENER314_RT board and the Adafruit RFM69HCW
# Radio Bonnet, this is GPIO 25 / RPI_PIN_22
my $reset_gpio = $options->{reset_gpio};

# You need to definethe SPI device you will be using and the
# cable select pin.
# The Energenie ENER314_RT board and the Adafruit RFM69HCW
# Radio Bonnet use SPI0, CE1
my $spidevice = $options->{device};

# Set the limit for the maximum value to use PA1 alone
# on high powered module
my $pa1_limit = $options->{pa1_limit};

# Command listening sensor to respond
my $command_listener = $options->{command} ? 1 : 0;

# set the dBm programmed power
my $dbmin = $options->{power};

# frequency of test message send
my $send_frequency = $options->{send_frequency};
$send_frequency = 1 if $send_frequency < 1;
$send_frequency = 60 if $send_frequency > 60;

my $limitsensor = HiPi::RF::OpenThings->format_sensor_key(
    OPENTHINGS_MANUFACTURER_RASPBERRY, RFM69_TEST_PRODUCT, 2
);

#############################################################

# This demo script will listen for OpenThings messages

our $VERSION ='0.89';

my $rfmodule = HiPi::Interface::HopeRF69->new(
    high_power_module => $high_power_module,
    reset_gpio        => $reset_gpio,
    devicename        => $spidevice,
    transmit_dbm      => $dbmin,
    pa1_limit         => $pa1_limit,
);

my ( $spidevnumber, $spidevcss ) = ( $spidevice =~ /^[^0-9\.]+([0-9])\.([0-9])$/ );

my $power = $rfmodule->transmit_dbm;

my $iteration = 0;

my $send_test_time = time();

print qq(\n\tPress Ctrl + C to stop\n);

while (1) {
    my $msg = $rfmodule->receive_hipi_message(
        'HiPi::RF::OpenThings::Message',
        {
            cryptseed => 1,
        }
    );
    
    my $sensorkey = 'NOT KNOWN';
    if ( $msg ) {      
        my $manuid = $msg->mid || 0;
    
        if ( $manuid == OPENTHINGS_MANUFACTURER_ENERGENIE ) {
            $msg->cryptseed( ENERGENIE_DEFAULT_CRYPTSEED );
        } elsif( $manuid == OPENTHINGS_MANUFACTURER_RASPBERRY ) {
            $msg->cryptseed( OPENTHINGS_RASPBERRY_CRYPTSEED );
        } else {
            $msg->cryptseed( OPENTHINGS_DEFAULT_CRYPTSEED );
        }
        
        $msg->decode_buffer unless $msg->is_decoded;
        
        if( $msg->ok ) {
            $sensorkey = $msg->sensor_key;
            next if ( $limitsensor &&  $sensorkey ne $limitsensor);
            
            my $received = scalar(localtime($msg->epoch));

            print qq(\nResponse received $received\n);
            
            printf(qq(\tManufacturer ID: 0x%04x, Product ID: 0x%04x, Sensor ID: 0x%06x, Encrypt PIP: 0x%04x\n), $msg->manufacturer_id, $msg->product_id, $msg->sensor_id, $msg->encrypt_pip);
            printf(qq(\tSensor Key: %s\n), $msg->sensor_key);
            
            my $productname = HiPi::RF::OpenThings->product_name($msg->manufacturer_id, $msg->product_id );
            my $manufacname = HiPi::RF::OpenThings->manufacturer_name($msg->manufacturer_id);
            print qq(\t$manufacname : $productname\n);
            
            for my $record ( @{ $msg->records } ) {
                if ($record->typeid == OPENTHINGS_ENUMERATION ) {
                    printf(qq(\tEnumeration for %s ( command bit %s) : \n), $record->name, $record->command || '0' );
                    for my $enum ( $record->enumerated_values ) {
                        printf(qq(\t    %s : %s %s ( %s ) ( bytes %s )\n), $enum->enumeration_id, $enum->value, $record->units, $enum->typename, $enum->length );
                    }
                    
                } else {
                    my $typename = $record->typename;
                    
                    printf(qq(\t%s = %s ( command bit %s ) ( bytes %s )\n), $record->name, $record->value . ' ' . $record->units . qq( ( $typename )) , $record->command || '0', $record->length || 0);
                    if ($record->selector) {
                        printf(qq(\t    Source selector : 0b%b\n), $record->selector);
                    }
                }
            }
            
        } else {
            print qq(\n);
            while ( my $error = $msg->shift_error ) {
                print qq(INFORMATION : $error\n);
            }
        }
        print qq(\n\tPress Ctrl + C to stop\n);
    }
    
    # send test messages at set frequency
    if( time > $send_test_time ) {
        $iteration ++;
        my $message = HiPi::RF::OpenThings::Message->new(
            cryptseed  => OPENTHINGS_RASPBERRY_CRYPTSEED,
            mid        => OPENTHINGS_MANUFACTURER_RASPBERRY,
            pid        => RFM69_TEST_PRODUCT,
            sid        => 1,
        );
        
        $message->add_record(
            id      => RFM69_TEST_OUTPUT_POWER,
            command => $command_listener,
            typeid  => OPENTHINGS_SINT,
            value   => $power,
        );
        
        $message->add_record(
            id      => RFM69_TEST_SPI_DEVICE,
            command => 0,
            typeid  => OPENTHINGS_UINT,
            value   => $spidevnumber,
        );
        
        $message->add_record(
            id      => RFM69_TEST_SPI_CSS,
            command => 0,
            typeid  => OPENTHINGS_UINT,
            value   => $spidevcss,
        );
        
        $message->add_record(
            id      => RFM69_TEST_ITERATION,
            command => 0,
            typeid  => OPENTHINGS_UINT,
            value   => $iteration,
        );
        
        $message->encode_buffer;
        $rfmodule->send_hipi_message( $message );
        $message->decode_buffer;
        
        if ( $message->ok ) {
            print qq(\nTest message $iteration sent\n);
        } else {
            print qq(\n\n\tMessage Decoded With Errors\n);
            while ( my $error = $message->shift_error ) {
                print qq(\tERROR: $error\n);
            }
        }
        
        $send_test_time = time() + $send_frequency;
    }
    
    usleep( 10000 );
}

1;