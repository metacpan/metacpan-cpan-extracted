#########################################################################################
# Package        HiPi::Interface::MCP3ADC
# Description  : Control MCP3xxx Analog 2 Digital ICs
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP3ADC;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi qw( :spi :mcp3adc );
use HiPi::Device::SPI;

__PACKAGE__->create_ro_accessors( qw( devicename hsb_mask max_channel ic devbits ) );

our $VERSION ='0.81';

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        ic           => MCP3008,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
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
    
    $params{max_channel} = ( $params{ic} >> 8 ) -1;
    $params{hsb_mask} = $params{ic} & 0xFF;
    $params{devbits} = ( $params{hsb_mask} == 0xF ) ? 12 : 10;
    
    my $self = $class->SUPER::new(%params);
    
    # MCP3xxx may need a dummy read on first use after boot
    # as the chip needs the CS line to transition low/hi at
    # least once if it is booted when CS is low
    
    $self->single_read(0);
    
    return $self;
}

sub read {
    my($self, $mode) = @_;
    
    my @buffers = ( $self->devbits == 12 )
        ? ( 4 + ( $mode >> 2 ), ( $mode & 0x3 ) << 6, 0 )  # 12 bit
        : ( 1, $mode << 4 , 0 );                           # 10 bit
    
    my @result = unpack('C3', $self->device->transfer( pack('C3', @buffers) ));
    return ( ($result[1] & $self->hsb_mask ) << 8 ) + $result[2];
}

sub single_read {
    my($self, $channel) = @_;
    $channel //= 0;
    die qq(bad channel number $channel) if( $channel < 0 || $channel > $self->max_channel);
    $channel &= 0x7;
    return $self->read( 8 + $channel );
}

sub diff_read {
    my($self, $channel) = @_;
    #channel must be below max channels
    die qq(bad channel number $channel) if($channel !~ /^\d$/ || $channel > $self->max_channel);
    return $self->read( $channel );
}

sub percent_read {
    my($self, $channel) = @_;
    my $raw = $self->single_read( $channel );
    return $raw if !$raw;
    my $div = ( $self->devbits == 12 ) ? 4095 : 1023;
    my $float = ( $raw / $div ) * 100;
    my $result = sprintf('%.0f', $float);
    return $result;
}

1;

__END__

