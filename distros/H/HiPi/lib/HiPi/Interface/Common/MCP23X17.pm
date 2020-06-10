#########################################################################################
# Package        HiPi::Interface::Common::MCP23X17
# Description  : Base module for MCP23S17 & MCP23X17
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Common::MCP23X17;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :rpi );
use Carp;

__PACKAGE__->create_accessors( qw( address devicename backend ) );

our $VERSION ='0.81';

our %_r_addr_map;

sub set_address_bank {
    my( $selforclass, $bank) = @_;
    if( $bank == 1 ) {
        $_r_addr_map{IODIRA}   = 0x00;
        $_r_addr_map{IPOLA}    = 0x01;
        $_r_addr_map{GPINTENA} = 0x02;
        $_r_addr_map{DEFVALA}  = 0x03;
        $_r_addr_map{INTCONA}  = 0x04;
        $_r_addr_map{IOCON}    = 0x05;
        $_r_addr_map{GPPUA}    = 0x06;
        $_r_addr_map{INTFA}    = 0x07;
        $_r_addr_map{INTCAPA}  = 0x08;
        $_r_addr_map{GPIOA}    = 0x09;
        $_r_addr_map{OLATA}    = 0x0A;
        $_r_addr_map{IODIRB}   = 0x10;
        $_r_addr_map{IPOLB}    = 0x11;
        $_r_addr_map{GPINTENB} = 0x12;
        $_r_addr_map{DEFVALB}  = 0x13;
        $_r_addr_map{INTCONB}  = 0x14;
        $_r_addr_map{GPPUB}    = 0x16;
        $_r_addr_map{INTFB}    = 0x17;
        $_r_addr_map{INTCAPB}  = 0x18;
        $_r_addr_map{GPIOB}    = 0x19;
        $_r_addr_map{OLATB}    = 0x1A;
    } else {
        $_r_addr_map{IODIRA}   = 0x00;
        $_r_addr_map{IODIRB}   = 0x01;
        $_r_addr_map{IPOLA}    = 0x02;
        $_r_addr_map{IPOLB}    = 0x03;
        $_r_addr_map{GPINTENA} = 0x04;
        $_r_addr_map{GPINTENB} = 0x05;
        $_r_addr_map{DEFVALA}  = 0x06;
        $_r_addr_map{DEFVALB}  = 0x07;
        $_r_addr_map{INTCONA}  = 0x08;
        $_r_addr_map{INTCONB}  = 0x09;
        $_r_addr_map{IOCON}    = 0x0A;
        $_r_addr_map{GPPUA}    = 0x0C;
        $_r_addr_map{GPPUB}    = 0x0D;
        $_r_addr_map{INTFA}    = 0x0E;
        $_r_addr_map{INTFB}    = 0x0F;
        $_r_addr_map{INTCAPA}  = 0x10;
        $_r_addr_map{INTCAPB}  = 0x11;
        $_r_addr_map{GPIOA}    = 0x12;
        $_r_addr_map{GPIOB}    = 0x13;
        $_r_addr_map{OLATA}    = 0x14;
        $_r_addr_map{OLATB}    = 0x15;
    }
}

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    my $bank = ( $params{bank} ) ? 1 : 0;
    $self->set_address_bank($bank);
    return $self;
}

sub get_register_address {
    my($self, $register) = @_;
    croak(qq(Register $register is not recognised)) unless( exists($_r_addr_map{$register}) );
    my $raddr = $_r_addr_map{$register};
    return $raddr;
}

sub read_register_bits {
    my($self, $register, $numbytes) = @_;
    my @bytes = $self->read_register_bytes($register, $numbytes);
    my @bits;
    while( defined(my $byte = shift @bytes )) {
        my $checkbits = 0b00000001;
        for( my $i = 0; $i < 8; $i++ ) {
            my $val = ( $byte & $checkbits ) ? 1 : 0;
            push( @bits, $val );
            $checkbits *= 2;
        }
    }
    return @bits;
}

sub read_register_bytes {
    my($self, $registername, $numbytes) = @_;
    $numbytes ||= 1;
    my $raddr = $self->get_register_address( $registername );
    my @vals = $self->do_read_register_bytes($raddr, $numbytes);
    # Check if address bank changed
    if( $registername eq 'IOCON' ) {
        my $bank = ( $vals[0] & 0b10000000 ) ? 1 : 0;
        $self->set_address_bank($bank);
    }
    return @vals;
}

sub write_register_bits {
    my($self, $registername, @bits) = @_;
    my $bitcount  = @bits;
    my $bytecount = $bitcount / 8;
    if( $bitcount % 8 ) {
        croak(qq(The number of bits $bitcount cannot be ordered into bytes));
    }
    my @bytes;
    while( $bytecount ) {
        my $byte = 0;
        for(my $i = 0; $i < 8; $i++ ) {
            my $bit = shift @bits;
            $byte += ( $bit << $i );   
        }
        push(@bytes, $byte);
        $bytecount --;
    }
    $self->write_register_bytes($registername,@bytes);
}

sub write_register_bytes { 
    my($self, $registername, @bytes) = @_;
    my $raddr = $self->get_register_address( $registername );
    my $rval = $self->do_write_register_bytes($raddr, @bytes);
    # Check if address bank changed
    if( $registername eq 'IOCON' ) {
        my $bank = ( $bytes[0] & 0b10000000 ) ? 1 : 0;
        $self->set_address_bank($bank);
    }
    return $rval;
}

sub do_read_register_bytes {
    croak 'do_read_register_bytes must be overidden in a derived class';
}

sub do_write_register_bytes {
    croak 'do_write_register_bytes must be overidden in a derived class';
}

sub set_register_bit {
    my($self, $register, $bit, $val) = @_;
    croak qq(invalid bit or pin number $bit) unless $bit =~ /^[0-7]$/;
    my ( $byte ) = $self->read_register_bytes($register, 1);
    my $mask = 1 << $bit;
    $val = ( $val ) ? 1 << $bit : 0;
    $byte = ($byte & ~$mask) | $val;
    $self->write_register_bytes($register, $byte );
    return;
}

sub get_register_bit {
    my($self, $register, $bit) = @_;
    croak qq(invalid bit or pin number $bit) unless $bit =~ /^[0-7]$/;
    my ( $byte ) = $self->read_register_bytes($register, 1);
    my $mask = 1 << $bit;
    return ( $byte & $mask ) ? 1 : 0;
}

sub iocon_bank {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 7, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 7);
    }
    return $val;
}

sub iocon_mirror {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 6, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 6);
    }
    return $val;
}

sub iocon_seqop {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 5, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 5);
    }
    return $val;
}

sub iocon_disslw {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 4, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 4);
    }
    return $val;
}

sub iocon_haen {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 3, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 3);
    }
    return $val;
}

sub iocon_odr {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 2, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 2);
    }
    return $val;
}

sub iocon_intpol {
    my($self, $val) = @_;
    if (defined($val)) {
        $self->set_register_bit('IOCON', 1, $val);
    } else {
        $val = $self->get_register_bit('IOCON', 1);
    }
    return $val;
}

sub _set_any_register_bit {
    my($self, $portprefix, $port, $bit, $val) = @_;
    croak q(invalid GPIO port $port) if $port !~ /^[a-b]$/i;
    my $register = $portprefix . uc($port);
    $self->set_register_bit($register, $bit, $val);
    return;
}

sub _get_any_register_bit {
    my($self, $portprefix, $port, $bit) = @_;
    croak q(invalid GPIO port $port) if $port !~ /^[a-b]$/i;
    my $register = $portprefix . uc($port);
    return $self->get_register_bit($register, $bit);
}

sub _convert_portpin {
    my($self, $portpin) = @_;
    $portpin = uc($portpin);
    my( $port, $pin ) = ( $portpin =~ /^([AB])([0-7])$/ );
    if ($port && defined($pin)) {
        return ( $port, $pin);
    } else {
        croak qq(invalid pin value $portpin);
    }
}

sub _standard_bit_handler {
    my($self, $regbase, $portpin, $val) = @_;
    my( $port, $pin ) = $self->_convert_portpin( $portpin );
    if (defined($val)) {
        $self->_set_any_register_bit( $regbase, $port, $pin, $val );
    } else {
        $val = $self->_get_any_register_bit( $regbase, $port, $pin );
    }
    return $val;
}

# pin value has to read from GPIO but write to OLAT
# so do that all here

sub pin_value {
    my( $self, $portpin, $val) = @_;
    my( $port, $bit ) = $self->_convert_portpin( $portpin );
    
    my $readregister  = 'GPIO' . $port;
    my $writeregister = 'OLAT' . $port;
    
    my ( $byte ) = $self->read_register_bytes($readregister, 1);
    my $mask = 1 << $bit;
    my $returnval = ( $byte & $mask ) ? 1 : 0;
    
    if (defined($val)) {
        $val = ( $val ) ? 1 : 0;
        if ( $val != $returnval ) {
            $returnval = $val;
            $byte = ($byte & ~$mask) | ( $val << $bit );
            $self->write_register_bytes($writeregister, $byte );
        }
    }
    return $returnval;
}

sub pin_mode {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('IODIR', $portpin, $val );
}

sub pin_polarity {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('IPOL', $portpin, $val );
}

sub pin_interrupt_enable {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('GPINTEN', $portpin, $val );
}

sub pin_interrupt_default {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('DEFVAL', $portpin, $val );
}

sub pin_interrupt_control {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('INTCON', $portpin, $val );
}

sub pin_pull_up {
    my( $self, $portpin, $val) = @_;
    return $self->_standard_bit_handler('GPPU', $portpin, $val );
}

#sub pin_interrupt_flag {
#    my( $self, $portpin) = @_;
#    return $self->_standard_bit_handler('INTF', $portpin );
#}
#
#sub pin_interrupt_capture {
#    my( $self, $portpin) = @_;
#    return $self->_standard_bit_handler('INTCAP', $portpin );
#}


1;

__END__
