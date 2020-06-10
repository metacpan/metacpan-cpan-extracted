#########################################################################################
# Package        HiPi::Interface::MCP4DAC
# Description  : Control MCP4xxx Digital 2 Analog ICs
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP4DAC;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :spi :mcp4dac );
use HiPi::Device::SPI;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( bitsperword minvar ic devicename
                                   dualchannel canbuffer buffer gain
                                   writemask shiftvalue shiftbits ) );

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        ic           => MCP4902,
        buffer       => 0,
        gain         => 0,
        shiftvalue   => 0,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
        
    {
        my $ic = $params{ic};
        
        if( $ic & MCP_DAC_RESOLUTION_12 ) {
            $params{minvar} = 0;
            $params{shiftbits} = 0;
            $params{writemask} = 0b1111111111111111;
        } elsif( $ic & MCP_DAC_RESOLUTION_10 ) {
            $params{minvar} = 4;
            $params{shiftbits} = 2;
            $params{writemask} = 0b1111111111111100;
        } else {
            $params{minvar} = 16;
            $params{shiftbits} = 4;
            $params{writemask} = 0b1111111111110000;
        }
        
        if( $ic & MCP_DAC_CAN_BUFFER ) {
            $params{canbuffer} = 1;
        } else {
            $params{canbuffer} = 0;
        }
        
        if( $ic & MCP_DAC_DUAL_CHANNEL ) {
            $params{dualchannel} = 1;
        } else {
            $params{dualchannel} = 0;
        }
        
    }
    
    unless( defined($params{device}) ) {
        my $dev = HiPi::Device::SPI->new(
            speed        => $params{speed},
            bitsperword  => $params{bitsperword},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
        
        $params{device} = $dev;
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}


sub write {
    my($self, $value, $channelb) = @_;
    $channelb ||= 0;
    $channelb = 0 if !$self->dualchannel;
        
    my $output = ( $channelb ) ? MCP_DAC_CHANNEL_B : MCP_DAC_CHANNEL_A;
    $output += MCP_DAC_BUFFER if($self->canbuffer && $self->buffer);
    $output += ( $self->gain ) ? MCP_DAC_GAIN : MCP_DAC_NO_GAIN;
    $output += MCP_DAC_LIVE;
    
    # allow user to specify values 1-255 for 8 bit device etc
    
    if( $self->shiftvalue ) {
        $value <<= $self->shiftbits;
    }
    
    # mask the $value. If user specifies shiftvalue == true
    # and gives a value over 255 for an 8 bit device
    # confusing things will happen. We only want
    # 12 bits. If user gets it wrong then at least
    # all that happens is they get wrong voltage -
    # instead of potentially writing to wrong channel
    # or shutting the channel down if we shift a high value
    
    $value &= 0b111111111111;
    
    $value = $self->minvar if( $value > 0 && $value < $self->minvar );
    $value = 0 if $value < 0;
        
    $output += $value;
    $output &= $self->writemask;
    $self->device->transfer( $self->_fmt_val( $output ) );
}

sub _fmt_val {
    my($self, $val) = @_;
    pack('n', $val);
}

sub shutdown {
    my($self, $channelb) = @_;
    $channelb ||= 0;
    $channelb = 0 if !$self->dualchannel;
    my $output = ( $channelb ) ? MCP_DAC_CHANNEL_B : MCP_DAC_CHANNEL_A;
    $output += MCP_DAC_SHUTDOWN;
    $self->device->transfer( $self->_fmt_val( $output ) );
}

1;

__END__
