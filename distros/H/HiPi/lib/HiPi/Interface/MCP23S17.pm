#########################################################################################
# Package        HiPi::Interface::MCP23S17
# Description  : Control MCP23S17 Port Extender via SPI
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP23S17;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::MCP23X17 );
use HiPi qw( :rpi :spi :mcp23S17 );
use HiPi::Device::SPI;
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

use constant {
    MCP_SPI_READ_MASK   => 0x41,
    MCP_SPI_WRITE_MASK  => 0x40,
};

sub new {
    my ($class, %userparams) = @_;
    
   my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        address      => 0,
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
    
    my $self = $class->SUPER::new(%params);
    
    # get current register address config so correct settings are loaded
    $self->read_register_bytes('IOCON');
    return $self;
}

sub do_write_register_bytes {
    my($self, $regaddress, @bytes) = @_;
    my $devaddr = MCP_SPI_WRITE_MASK + ( $self->address << 1 );
    $self->device->transfer( pack('C*', ( $devaddr, $regaddress, @bytes ) ) );
    return 1;
}

sub do_read_register_bytes {
    my($self, $regaddress, $numbytes) = @_;
    my @bufferbytes = ( (1) x $numbytes );
    my $packbytes = $numbytes + 2;
    my $format = 'C' . $packbytes;
    my $devaddr = MCP_SPI_READ_MASK + ( $self->address << 1 );
    my @vals = unpack($format, $self->device->transfer( pack($format, ( $devaddr, $regaddress, @bufferbytes )) ));
    # first 2 vals in return buffer are not part of returned data
    shift @vals; shift @vals;
    return @vals;
}


1;

__END__
