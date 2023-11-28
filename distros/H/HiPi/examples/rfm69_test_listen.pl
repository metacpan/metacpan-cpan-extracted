#!/usr/bin/perl
use strict;
use warnings;

use HiPi 0.89;
use HiPi qw( :energenie :openthings :rpi :hrf69 :mcp23017 );
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
    sensor_key        => undef,
    autojoin          => 0,
    power             => 10,
};

GetOptions( $options,
    'high_power_module|h!',
    'reset_gpio|r:s',
    'device|d:s',
    'sensor_key|s:s',
    'autojoin|a!',
    'power|p:i',
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

# You need to define the SPI device you will be using and the
# cable select pin.
# The Energenie ENER314_RT board and the Adafruit RFM69HCW
# Radio Bonnet use SPI0, CE1
my $spidevice = $options->{device};

# automatically respond to join commands
# and toggle on / off any devices capable of Switch commands
# that join 
my $autojoin_enabled = $options->{autojoin};

# set output power ( for autojoin messages)

my $dbm = $options->{power};

# listen only for this sensor
my $limitsensor = $options->{sensor_key};

if ( $limitsensor && $limitsensor eq 'test' ) {
    $limitsensor = HiPi::RF::OpenThings->format_sensor_key(
        OPENTHINGS_MANUFACTURER_RASPBERRY, RFM69_TEST_PRODUCT, 1
    );
    
}

#############################################################

# This demo script will listen for OpenThings messages

our $VERSION ='0.89';

# keep a hash of switches we have 'registered'
# for use if autojoin is on
my $switch_states = {};

# registered devices we are waiting for confirmation - autojoin
my $pending_reg = {};

# autojoin toggle
my $switchtime = time() + 7;

my $rfmodule = HiPi::Interface::HopeRF69->new(
    high_power_module => $high_power_module,
    reset_gpio        => $reset_gpio,
    devicename        => $spidevice,
    transmit_dbm      => $dbm
);

print qq(\n\tPress Ctrl + C to stop\n);

while (1) {
    my $msg = $rfmodule->receive_hipi_message(
        'HiPi::RF::OpenThings::Message',
        {
            cryptseed => 1,
        }
    );
    my $messagefromswitch = 0;
    my $switchstate = 0;
    my $sensorkey = 'NOT KNOWN';
    if ( $msg ) {
        my $rssival = $rfmodule->read_register( RF69_REG_RSSIVALUE );
        ## Need to re-init the module to remove automatic adjustment controls
        ## and allow initial RSSI measurement. Only use for testing.
        $rfmodule->init_radio_module;
        
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

            print qq(\nMessage received $received\n);
            
            printf(qq(\tManufacturer ID: 0x%04x, Product ID: 0x%04x, Sensor ID: 0x%06x, Encrypt PIP: 0x%04x\n), $msg->manufacturer_id, $msg->product_id, $msg->sensor_id, $msg->encrypt_pip);
            printf(qq(\tSensor Key: %s\n), $msg->sensor_key);
            
            printf(qq(\tSignal: %.1f dBm\n), $rssival / - 2);
            
            my $productname = HiPi::RF::OpenThings->product_name($msg->manufacturer_id, $msg->product_id );
            my $manufacname = HiPi::RF::OpenThings->manufacturer_name($msg->manufacturer_id);
            print qq(\t$manufacname : $productname\n);
            
            my @joinrecords = ();
            
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
                    
                    ## newly joined devices
                    if ( $autojoin_enabled && $record->id == OPENTHINGS_PARAM_JOIN && $record->command ) {
                        push @joinrecords, $record;
                    } elsif( $autojoin_enabled && $record->id == OPENTHINGS_PARAM_SWITCH_STATE ) {
                        $messagefromswitch = 1;
                        $switchstate = $record->value;
                    }
                }
            }
            
            # toggling just joined switches when
            # autojoin is enabled
            if(exists($pending_reg->{$sensorkey})) {
                delete($pending_reg->{$sensorkey});
                # is this a switch we just registered
                if( $messagefromswitch ) {
                    $switch_states->{$sensorkey} = {
                        mid => $msg->manufacturer_id,
                        pid => $msg->product_id,
                        sid => $msg->sensor_id,
                        cryptseed => $msg->cryptseed,
                        state => $switchstate,
                    }
                }
            }
            
            # handle this record autojoin     
            for my $jreq( @joinrecords ) {
                
                delete($switch_states->{$sensorkey}) if exists ($switch_states->{$sensorkey});
                
                my $outmsg = HiPi::RF::OpenThings::Message->new(
                    cryptseed => $msg->cryptseed,
                    mid => $msg->manufacturer_id,
                    pid => $msg->product_id,
                    sid => $msg->sensor_id,
                );
                
                $outmsg->add_record(
                    id      => OPENTHINGS_PARAM_JOIN,
                    command => 0,
                    typeid  => OPENTHINGS_UINT,
                    value   => undef,
                );
                
                $outmsg->encode_buffer;
                $rfmodule->send_hipi_message( $outmsg );
                $outmsg->decode_buffer;
                
                if ( $outmsg->ok ) {
                    print qq(\n\n\tAccept join request sent decoded OK\n);
                    for my $record ( @{ $outmsg->records } ) {
                        printf(qq(\t%s = %s ( command bit %s)\n), $record->name, $record->value . ' ' . $record->units, $record->command || '0');
                    }
                    
                    $pending_reg->{$sensorkey} = 1;
                                        
                } else {
                    print qq(\n\n\tMessage Decoded With Errors\n);
                    while ( my $error = $outmsg->shift_error ) {
                        print qq(\tERROR: $error\n);
                    }
                }   
            }
            
            if ( $msg->product_id == RFM69_TEST_PRODUCT  && $msg->has_command ) {
                my $outmsg = HiPi::RF::OpenThings::Message->new(
                    cryptseed => $msg->cryptseed,
                    mid => $msg->manufacturer_id,
                    pid => $msg->product_id,
                    sid => 2,
                );
                
                for my $echo_record ( @{ $msg->records } ) {
                    $echo_record->command(0);
                    $outmsg->add_record($echo_record);
                }
                             
                $outmsg->add_record(
                    id      => RFM69_TEST_RSSI,
                    command => 0,
                    typeid  => OPENTHINGS_SINT_BP8,
                    value   => $rssival / - 2,
                );
                
                $outmsg->encode_buffer;
                $rfmodule->send_hipi_message( $outmsg );
                $outmsg->decode_buffer;
                
                if ( $outmsg->ok ) {
                    print qq(\n\n\tTest Response Sent Decoded OK\n);
                    for my $record ( @{ $outmsg->records } ) {
                        printf(qq(\t%s = %s ( command bit %s)\n), $record->name, $record->value . ' ' . $record->units, $record->command || '0');
                    }
                                        
                } else {
                    print qq(\n\n\tTest Response Decoded With Errors\n);
                    while ( my $error = $outmsg->shift_error ) {
                        print qq(\tERROR: $error\n);
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
    
    # process any switch states (autojoin enabled)
    if( $messagefromswitch && exists($switch_states->{$sensorkey}) ) {
        $switch_states->{$sensorkey}->{state} = $switchstate;
    }
    
    # send switch toggle messages every 7 seconds ( autojoin enabled )
    if( time > $switchtime) {
        for my $skey ( keys %$switch_states ) {
            my $switchmsg = HiPi::RF::OpenThings::Message->new(
                cryptseed => $switch_states->{$skey}->{cryptseed},
                mid => $switch_states->{$skey}->{mid},
                pid => $switch_states->{$skey}->{pid},
                sid => $switch_states->{$skey}->{sid},
            );
        
            my $newstate = ( $switch_states->{$skey}->{state} ) ? 0 : 1;
            
            $switchmsg->add_record(
                id      => OPENTHINGS_PARAM_SWITCH_STATE,
                command => 1,
                typeid  => OPENTHINGS_UINT,
                value   => $newstate,
            );
            
            
            $rfmodule->send_hipi_message( $switchmsg );
            
            print qq(\nSent switch message to sensor $skey to set state $newstate\n);
            
            my @powerdump = $rfmodule->dump_transmit_power_info;
            print qq(\t$_\n) for ( @powerdump );
            
            $switchmsg->decode_buffer;
                
            if ( $switchmsg->ok ) {
                for my $record ( @{ $switchmsg->records } ) {
                    printf(qq(\t%s = %s ( command bit %s)\n), $record->name, $record->value . $record->units, $record->command || '0');
                }
            }
        }
        
        $switchtime = time() + 7;
    }
    
    usleep( 10000 );
}

1;