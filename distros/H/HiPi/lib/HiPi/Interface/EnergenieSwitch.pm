#########################################################################################
# Package        HiPi::Interface::EnergenieSwitch
# Description:   Control Energenie OOK switches
# Copyright    : Copyright (c) 2013-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::EnergenieSwitch;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :energenie :rpi );
use Carp;

__PACKAGE__->create_accessors( qw( groupid backend repeat ) );

our $VERSION ='0.82';

# Switch Data
# $data = $switchmask->[$socketnum - 1]->[$offon];
# where $socketnum == 0 | 1 | 2 | 3 | 4 and $offon == 0|1;
# when  $socketnum == 0 then $offon is applied to all sockets

my $_switchdata = [
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
        groupid      => 0x6C6C6,
        device       => undef,
        devicename   => '/dev/spidev0.1',
        repeat       => ENERGENIE_TXOOK_REPEAT_RATE,
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
        } else {
            croak qq(Invalid backend $params{backend} specified);
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub pair_socket {
    my($self, $socket, $seconds) = @_;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^1|2|3|4$/;
    $seconds ||= 10;
    
    # broadcast for $seconds seconds;
    my $endtime = time() + $seconds;
    my $data = $_switchdata->[$socket]->[0]; # broadcast 'off' message for socket
    
    while ( $endtime >= time() ) {
        $self->device->switch_ook_socket( $self->groupid, $data, $self->repeat );
    }
    
    return;
}

sub switch_socket {
    my($self, $socket, $offon) = @_;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^0|1|2|3|4$/;
    $offon = ( $offon ) ? 1 : 0;
    my $data = $_switchdata->[$socket]->[$offon];
    $self->device->switch_ook_socket( $self->groupid, $data, $self->repeat );
    return;
}

# test what we actually send 
sub dump_message {
    my($self, $socket, $offon) = @_;
    croak(q(Method requires backend 'ENER314_RT')) if $self->backend !~ /^ENER314_RT|RF69HW$/;
    croak(qq(Invalid socket $socket)) unless $socket =~ /^0|1|2|3|4$/;
    $offon = ( $offon ) ? 1 : 0;
    my $data = $_switchdata->[$socket]->[$offon];
    my @tvals = $self->device->make_ook_message( $self->groupid, $data );
    
    # print preamble
    print sprintf("preamble : 0x%x, 0x%x, 0x%x, 0x%x\n", @tvals[0..3]);
    # print group id
    print sprintf("group id : 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x\n", @tvals[4..13]);
    # print data
    print sprintf("set data : 0x%x, 0x%x\n", @tvals[14..15]);
    return;
}

1;

__END__