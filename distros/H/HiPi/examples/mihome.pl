#!/usr/bin/perl

# This demo script will listen for OpenThings messages
# If a device sends a 'Join' Message script will
# send back an acknowledgment.
# If the joined device has SWITCH_STATE, then
# script will toggle it on and off every 7 seconds.
# Run the script then press the button on your device
# to register / join that device

use strict;
use warnings;

use HiPi qw( :energenie :openthings );
use HiPi::Energenie::ENER314_RT;
use Time::HiRes qw( usleep );
use HiPi::RF::OpenThings::Message;
use HiPi::RF::OpenThings;

our $VERSION ='0.81';

my $handler = HiPi::Energenie::ENER314_RT->new( led_on => 0 );

# keep a hash of switches we have 'registered'
my $switch_states = {};

# registered devices we are waiting for confirmation
my $pending_reg = {};

my $switchtime = time() + 7;

while (1) {
    my $msg = $handler->receive_fsk_message( ENERGENIE_DEFAULT_CRYPTSEED );
    
    my $messagefromswitch = 0;
    my $switchstate = 0;
    my $sensorkey = 'NOT KNOWN';
    if ( $msg ) {
        $msg->decode_buffer unless $msg->is_decoded;
        
        if( $msg->ok ) {
            my $received = scalar(localtime($msg->epoch));
            print qq(\nMessage recieved $received\n);
            
            $sensorkey = $msg->sensor_key;
            
            printf(qq(\tManufacturer ID: 0x%04x, Product ID: 0x%04x, Sensor ID: 0x%06x, Encrypt PIP: 0x%04x\n), $msg->manufacturer_id, $msg->product_id, $msg->sensor_id, $msg->encrypt_pip);
            printf(qq(\tSensor Key: %s\n), $msg->sensor_key);
            if( $msg->manufacturer_id == ENERGENIE_MANUFACTURER_ID ) {
                my $productname = HiPi::RF::OpenThings->product_name($msg->manufacturer_id, $msg->product_id );
                print qq(\tEnergenie : $productname\n);
            }
            
            my @joinrecords = ();
            
            for my $record ( @{ $msg->records } ) {
                printf(qq(\t%s = %s ( command bit %s)\n), $record->name, $record->value . $record->units, $record->command || '0');
                if ( $record->id == OPENTHINGS_PARAM_JOIN && $record->command ) {
                    push @joinrecords, $record;
                } elsif( $record->id == OPENTHINGS_PARAM_SWITCH_STATE ) {
                    $messagefromswitch = 1;
                    $switchstate = $record->value;
                }
            }
            
            if(exists($pending_reg->{$sensorkey})) {
                delete($pending_reg->{$sensorkey});
                # is this a switch we just registered
                if( $messagefromswitch ) {
                    $switch_states->{$sensorkey} = {
                        mid => $msg->manufacturer_id,
                        pid => $msg->product_id,
                        sid => $msg->sensor_id,
                        state => $switchstate,
                    }
                }
            }
            
            for my $jreq( @joinrecords ) {
                
                delete($switch_states->{$sensorkey}) if exists ($switch_states->{$sensorkey});
                
                my $outmsg = HiPi::RF::OpenThings::Message->new(
                    cryptseed => ENERGENIE_DEFAULT_CRYPTSEED,
                    mid => $msg->manufacturer_id,
                    pid => $msg->product_id,
                    sid => $msg->sensor_id,
                    pip => $msg->encrypt_pip,
                );
                
                $outmsg->add_record(
                    id      => OPENTHINGS_PARAM_JOIN,
                    command => 0,
                    typeid  => OPENTHINGS_UINT,
                    value   => undef,
                );
                
                $outmsg->encode_buffer;
                $handler->send_fsk_message( $outmsg );
                $outmsg->decode_buffer;
                
                if ( $outmsg->ok ) {
                    print qq(\n\n\tMessage Sent Decoded OK\n);
                    for my $record ( @{ $outmsg->records } ) {
                        printf(qq(\t%s = %s ( command bit %s)\n), $record->name, $record->value . $record->units, $record->command || '0');
                    }
                    $pending_reg->{$sensorkey} = 1;
                } else {
                    print qq(\n\n\tMessage Decoded With Errors\n);
                    while ( my $error = $outmsg->shift_error ) {
                        print qq(\tERROR: $error\n);
                    }
                }   
            }
        } else {
            # ignore bad fifo content
            #while ( my $error = $msg->shift_error ) {
            #    print qq(\tERROR: $error\n);
            #}
        }
    }
    
    # process any switch states
    if( $messagefromswitch && exists($switch_states->{$sensorkey}) ) {
        $switch_states->{$sensorkey}->{state} = $switchstate;
    }
    
    # send switch messages every 7 seconds
    if( time > $switchtime) {
        for my $skey ( keys %$switch_states ) {
            my $switchmsg = HiPi::RF::OpenThings::Message->new(
                cryptseed => ENERGENIE_DEFAULT_CRYPTSEED,
                mid => $switch_states->{$skey}->{mid},
                pid => $switch_states->{$skey}->{pid},
                sid => $switch_states->{$skey}->{sid},
                pip => ENERGENIE_DEFAULT_CRYPTPIP,
            );
        
            my $newstate = ( $switch_states->{$skey}->{state} ) ? 0 : 1;
            
            $switchmsg->add_record(
                id      => OPENTHINGS_PARAM_SWITCH_STATE,
                command => 1,
                typeid  => OPENTHINGS_UINT,
                value   => $newstate,
            );
            
            
            $handler->send_fsk_message( $switchmsg );
            
            print qq(\nSent switch message to sensor $skey to set state $newstate\n);
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