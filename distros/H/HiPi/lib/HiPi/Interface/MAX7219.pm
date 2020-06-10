#########################################################################################
# Package        HiPi::Interface::MAX7219
# Description  : Interface to MAX7219 matrix LED driver
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MAX7219;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :max7219 );
use HiPi::Device::SPI;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( ) );

my $codefont = {
    '0' => 0b0000,
    '1' => 0b0001,
    '2' => 0b0010,
    '3' => 0b0011,
    '4' => 0b0100,
    '5' => 0b0101,
    '6' => 0b0110,
    '7' => 0b0111,
    '8' => 0b1000,
    '9' => 0b1001,
    '-' => 0b1010,
    'E' => 0b1011,
    'H' => 0b1100,
    'L' => 0b1101,
    'P' => 0b1110,
    ' ' => 0b1111,
};

sub _get_code_char {
    my $char = shift;
    return ( exists($codefont->{$char}) ) ? $codefont->{$char} : $codefont->{' '};
}

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => 9600000,  # 9.6 mhz
        delay        => 0,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless(defined($params{device})) {
        $params{device} = HiPi::Device::SPI->new(
            speed        => $params{speed},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    
    $self->set_display_test( 0 );
    
    return $self;
}

sub write_code_char {
    my($self, $matrix, $char, $flags, $cascade) = @_;
    $flags //= 0x00;
    $char  //= ' ';
    my $byte = _get_code_char( $char );
    
    if( $flags & MAX7219_FLAG_DECIMAL ) {
        $byte |= 0x80;
    }
    
    $self->send_segment_matrix( $matrix, $byte, $cascade );
    $self->sleep_milliseconds(10);
}

sub send_segment_matrix {
    # send data for single matrix
    my($self, $matrix, $byte, $cascade) = @_;
    return unless($matrix >= 0 && $matrix < 8 );
    my $reg = MAX7219_REG_DIGIT_0 + $matrix;
    $self->send_command( $reg, $byte, $cascade );
}

sub send_command {
    my($self, $register, $data, $cascade ) = @_;
    $cascade ||= 0;
    my @bytes = ( $register, $data );
    if( $cascade ) {
        for (my $i = 0; $i < $cascade; $i ++ ) {
            push( @bytes, MAX7219_REG_NOOP, 0x00 );
        }
    }
    $self->device->transfer_byte_array( @bytes );
    return;
}

sub send_raw_bytes {
    my($self, @bytes) = @_;
    $self->device->transfer_byte_array( @bytes );
    return;
}

sub set_decode_mode {
    my($self, $mode, $cascade ) = @_;
    # only covers all on or all off
    # see data sheet for mixed settings
    $mode = ( $mode ) ? 0xFF : 0x00;
    $self->send_command( MAX7219_REG_DECODE_MODE, $mode, $cascade );
    return;
}

sub set_intensity {
    my($self, $value, $cascade ) = @_;
    # value between 0 ( min ) and 15  ( max )
    $value &= 0xF; 
    $self->send_command( MAX7219_REG_INTENSITY, $value, $cascade );
    return;
}

sub set_scan_limit {
    my($self,  $value, $cascade ) = @_;
    # value between 0 and 7 - how many registers are scanned
    $value &= 0x7;
    $self->send_command( MAX7219_REG_SCAN_LIMIT, $value, $cascade );
    return;
}

sub shutdown {
    my($self, $cascade ) = @_;
    $self->send_command( MAX7219_REG_SHUTDOWN, 0x00, $cascade );
    return;
}

sub wake_up {
    my($self, $cascade ) = @_;
    $self->send_command( MAX7219_REG_SHUTDOWN, 0x01, $cascade );
    return;
}

sub set_display_test {
    my( $self, $testmode, $cascade ) = @_;
    $testmode = ( $testmode ) ? 0x01 : 0x00;
    $self->send_command( MAX7219_REG_TEST, $testmode, $cascade );
    $self->sleep_milliseconds(10);
}

1;

__END__