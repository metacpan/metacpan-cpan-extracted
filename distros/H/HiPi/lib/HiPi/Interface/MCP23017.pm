#########################################################################################
# Package        HiPi::Interface::MCP23017
# Description:   Control MCP23017 Port Extender via I2C
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP23017;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::MCP23X17 );
use HiPi qw( :rpi :mcp23x17 );
use HiPi::RaspberryPi;
use Carp;

our $VERSION ='0.81';

# compatibility

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# legacy compat exports
{
    my @const = qw(
        MCP23S17_A0 MCP23S17_A1 MCP23S17_A2 MCP23S17_A3 MCP23S17_A4 MCP23S17_A5 MCP23S17_A6 MCP23S17_A7 
        MCP23S17_B0 MCP23S17_B1 MCP23S17_B2 MCP23S17_B3 MCP23S17_B4 MCP23S17_B5 MCP23S17_B6 MCP23S17_B7
        MCP23S17_BANK MCP23S17_MIRROR MCP23S17_SEQOP MCP23S17_DISSLW MCP23S17_HAEN MCP23S17_ODR MCP23S17_INTPOL
        MCP23S17_INPUT MCP23S17_OUTPUT MCP23S17_HIGH MCP23S17_LOW
        
        MCP23017_A0 MCP23017_A1 MCP23017_A2 MCP23017_A3 MCP23017_A4 MCP23017_A5 MCP23017_A6 MCP23017_A7 
        MCP23017_B0 MCP23017_B1 MCP23017_B2 MCP23017_B3 MCP23017_B4 MCP23017_B5 MCP23017_B6 MCP23017_B7
        MCP23017_BANK MCP23017_MIRROR MCP23017_SEQOP MCP23017_DISSLW MCP23017_HAEN MCP23017_ODR MCP23017_INTPOL
        MCP23017_INPUT MCP23017_OUTPUT MCP23017_HIGH MCP23017_LOW
    );
    
    my @constpins = qw(
        MCP_PIN_A0 MCP_PIN_A1 MCP_PIN_A2 MCP_PIN_A3 MCP_PIN_A4 MCP_PIN_A5 MCP_PIN_A6 MCP_PIN_A7
        MCP_PIN_B0 MCP_PIN_B1 MCP_PIN_B2 MCP_PIN_B3 MCP_PIN_B4 MCP_PIN_B5 MCP_PIN_B6 MCP_PIN_B7
    );
    
    push( @EXPORT_OK, @const, @constpins );
    $EXPORT_TAGS{mcp23017} = \@const;
    $EXPORT_TAGS{mcp23S17} = \@const;
    $EXPORT_TAGS{mcppin} = \@constpins;
}

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x20,
        device      => undef,
        backend     => 'smbus',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        if ( $params{backend} eq 'bcm2835' ) {
            require HiPi::BCM2835::I2C;
            $params{device} = HiPi::BCM2835::I2C->new(
                address    => $params{address},
                peripheral => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    # get current register address config so correct settings are loaded
    $self->read_register_bytes('IOCON');
    
    return $self;
}

sub do_write_register_bytes {
    my($self, $regaddress, @bytes) = @_;
    my $rval = $self->device->bus_write($regaddress, @bytes);
    return $rval;
}

sub do_read_register_bytes {
    my($self, $regaddress, $numbytes) = @_;
    my @vals = $self->device->bus_read($regaddress, $numbytes);
    return @vals;
}

1;

__END__
