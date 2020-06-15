#########################################################################################
# Package        HiPi::Energenie
# Description:   Control Energenie devices
# Copyright    : Copyright (c) 2016-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Energenie;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :energenie :openthings :rpi );
use HiPi::RF::OpenThings::Message;
use UNIVERSAL::require;

use Carp;

__PACKAGE__->create_accessors( qw( backend ook_repeat can_rx ) );

our $VERSION ='0.82';

use constant {
    STATE_LISTEN                => 2,
    STATE_PROCESS_JOIN          => 3,
    STATE_PROCESS_SWITCH        => 4,
    STATE_PROCESS_QUERY         => 5,
};

# OOK Switch Data
# $data = $switchmask->[$socketnum - 1]->[$offon];
# where $socketnum == 0 | 1 | 2 | 3 | 4 and $offon == 0|1;
# when  $socketnum == 0 then $offon is applied to all sockets

my $_ook_switchdata = [
    [ 0b1100, 0b1101 ], # off / on all sockets
    [ 0b1110, 0b1111 ], # off / on  socket 1
    [ 0b0110, 0b0111 ], # off / on  socket 2
    [ 0b1010, 0b1011 ], # off / on  socket 3
    [ 0b0010, 0b0011 ], # off / on  socket 4
];

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        backend      => 'ENER314_RT',
        device       => undef,
        can_rx       => 1,
        devicename   => '/dev/spidev0.1',
        ook_repeat   => ENERGENIE_TXOOK_REPEAT_RATE,
        reset_gpio   => RPI_PIN_22,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        
        if ( $params{backend} eq 'ENER314_RT' ) {
            
            # Two way configurable board
            require HiPi::Energenie::ENER314_RT;
            my $dev = HiPi::Energenie::ENER314_RT->new(
                led_on      => 0,
                devicename  => $params{devicename},
                reset_gpio  => $params{reset_gpio},
            );
            $params{device} = $dev;
            
        } elsif( $params{backend} eq 'RF69HW' ) {
            # Two way high powered module
            require HiPi::Energenie::ENER314_RT;
            my $dev = HiPi::Energenie::ENER314_RT->new(
                led_on      => 0,
                devicename  => $params{devicename},
                reset_gpio  => $params{reset_gpio},
                rf_high_power => 1,
            );
            $params{device} = $dev;
            
        } elsif( $params{backend} eq 'ENER314' ) { 
            # simple 1 way single group board
            require HiPi::Energenie::ENER314;
            my $dev = HiPi::Energenie::ENER314->new();
            $params{device} = $dev;
            $params{can_rx} = 0,
        } else {
            croak qq(Invalid backend $params{backend} specified);
        }
    }
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub pair_socket {
    my($self, $group_id, $socket) = @_;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^1|2|3|4$/;
    my $data = $_ook_switchdata->[$socket]->[0]; # broadcast 'off' message for socket
    $self->device->switch_ook_socket( $group_id, $data, $self->ook_repeat );   
    return;
}

sub switch_socket {
    my($self, $group_id, $socket, $offon ) = @_;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^0|1|2|3|4$/;
    my $data = $_ook_switchdata->[$socket]->[$offon];
    $self->device->switch_ook_socket($group_id, $data, $self->ook_repeat );
    return;
}

# test what we actually send 
sub dump_message {
    my($self, $socket, $offon) = @_;
    croak(q(Method requires backend 'ENER314_RT' or 'RF69HW' )) if $self->backend !~ /^ENER314_RT|RF69HW$/;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^0|1|2|3|4$/;
    $offon = ( $offon ) ? 1 : 0;
    my $data = $_ook_switchdata->[$socket]->[$offon];
    my @tvals = $self->device->make_ook_message( $self->groupid, $data );
    
    # print preamble
    print sprintf("preamble : 0x%x, 0x%x, 0x%x, 0x%x\n", @tvals[0..3]);
    # print group id
    print sprintf("group id : 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x\n", @tvals[4..13]);
    # print data
    print sprintf("set data : 0x%x, 0x%x\n", @tvals[14..15]);
    return;
}

sub process_request {
    my( $self, %params ) = @_;
    
    croak q(Cannot receive and transmit using board ENER314) unless $self->can_rx;
    
    my $state = STATE_LISTEN;
    
    my $command      = $params{command}  || 'listen';
    my $timeout      = $params{timeout};
    $timeout //= 60;
    
    my $returnval = {
        success  => 0,
        data     => {},
        error    => 'unknown failure to process request',
    };
    
    my $waitkeys = {} ;
    
    if($timeout) {
        $timeout = time() + $timeout;
    }
    
    my $resendmessage;
    
    if( $command eq 'join' ) {
        $state = STATE_PROCESS_JOIN;
    }
    
    if( $command eq 'switch' ) {
        $state = STATE_PROCESS_SWITCH;
        
        my $switchvalue = $params{switch_state};
        my $sensorkey   = $params{sensor_key};
        
        $resendmessage = HiPi::RF::OpenThings::Message->new(
            cryptseed  => ENERGENIE_DEFAULT_CRYPTSEED,
            sensor_key => $sensorkey,
            pip        => ENERGENIE_DEFAULT_CRYPTPIP,
        );
        
        $resendmessage->add_record(
            id      => OPENTHINGS_PARAM_SWITCH_STATE,
            command => 1,
            typeid  => OPENTHINGS_UINT,
            value   => $switchvalue,
        );
        
        $waitkeys->{$sensorkey} = $switchvalue;
        
        $self->device->send_fsk_message( $resendmessage );
        
        $returnval->{success} = 0;
        $returnval->{error} = 'switch did not confirm status';
    }
    
    if( $command eq 'query' ) {
        $state = STATE_PROCESS_QUERY;
        $waitkeys->{$params{sensor_key}} = 1; 
        $returnval->{success} = 0;
        $returnval->{error} = 'the queried device did not confirm status';
    }
    
    my $continue = 1;
    
    while ( $continue ) {
        
        if( $timeout && $timeout < time() ) {
            $returnval->{success} = 0;
            $returnval->{error} ||= '';
            $returnval->{error} .= ' Timed Out';
            last;
        }
        
        my $msg = $self->device->receive_fsk_message( ENERGENIE_DEFAULT_CRYPTSEED );
        
        if ( $msg ) {
            
            $msg->decode_buffer unless $msg->is_decoded;
             
            if ( $msg->ok ) {
                
                my $sensorkey = $msg->sensor_key;
            
                # are we interested in this sensor key ? we'll look at everything for now    
            
                # handle states we are waiting for
                if( $state == STATE_PROCESS_JOIN && $msg->has_join_cmd ) {
                        
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
                    $self->device->send_fsk_message( $outmsg );
                    $returnval->{success} = 1;
                    $returnval->{data}  = $msg;
                    $returnval->{error} = '';
                    last;
                }
                
                elsif( $state == STATE_PROCESS_SWITCH && $msg->has_switch_state ) {
                    if(exists($waitkeys->{$sensorkey}) ) {
                        if( $waitkeys->{$sensorkey} == $msg->switch_state ) {
                            delete($waitkeys->{$sensorkey});
                            $returnval->{success} = 1;
                            $returnval->{data} = $msg;
                            $returnval->{error} = '';
                            last;
                        }
                    }
                }
                
                elsif( $state == STATE_PROCESS_QUERY ) {
                    if(exists($waitkeys->{$sensorkey})) {
                        delete($waitkeys->{$sensorkey});
                        $returnval->{success} = 1;
                        $returnval->{data} = $msg;
                        $returnval->{error} = '';
                        last;
                    }
                }
                
                # if we sent msg whilst target was broadcasting, it won't have
                # received it, so send it once again
                
                if( $resendmessage ) {
                    $self->device->send_fsk_message( $resendmessage );
                    $resendmessage = undef;
                }
                
            } else {
                # msg not ok - ignore it
            }
        }
        
        $self->delay( 10 );
    }
    
    return $returnval;
}

sub get_timestamp {
    my($self, $epoch) = @_;
    $epoch ||= time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($epoch);
    my $timestamp = sprintf('%u-%02u-%02u %02u:%02u:%02u',
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec      
    );
    return $timestamp;
}

1;

__END__