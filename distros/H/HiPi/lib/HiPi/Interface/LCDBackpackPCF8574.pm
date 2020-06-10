#########################################################################################
# Package        HiPi::Interface::LCDBackpackPCF8574
# Description  : PCF8574 Backpack LCD Controller
# Copyright    : Copyright (c) 2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::LCDBackpackPCF8574;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::Common::HD44780 );
use Carp;
use HiPi qw( :rpi :lcd :i2c );
use HiPi::RaspberryPi;
use HiPi::Interface::PCF8574;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw( address devicename backend _backlight ) );

use constant {
    LCD_CLEARDISPLAY => 0x01,
    LCD_RETURNHOME => 0x02,
    LCD_ENTRYMODESET => 0x04,
    LCD_DISPLAYCONTROL => 0x08,
    LCD_CURSORSHIFT => 0x10,
    LCD_FUNCTIONSET => 0x20,
    LCD_SETCGRAMADDR => 0x40,
    LCD_SETDDRAMADDR => 0x80,

    ##  for display entry mode
    LCD_ENTRYRIGHT => 0x00,
    LCD_ENTRYLEFT => 0x02,
    LCD_ENTRYSHIFTINCREMENT => 0x01,
    LCD_ENTRYSHIFTDECREMENT => 0x00,

    ##  for display on/off control
    LCD_DISPLAYON => 0x04,
    LCD_DISPLAYOFF => 0x00,
    LCD_CURSORON => 0x02,
    LCD_CURSOROFF => 0x00,
    LCD_BLINKON => 0x01,
    LCD_BLINKOFF => 0x00,

    ##  for display/cursor shift
    LCD_DISPLAYMOVE => 0x08,
    LCD_CURSORMOVE => 0x00,
    LCD_MOVERIGHT => 0x04,
    LCD_MOVELEFT => 0x00,

    ##  for function set
    LCD_8BITMODE => 0x10,
    LCD_4BITMODE => 0x00,
    LCD_2LINE => 0x08,
    LCD_1LINE => 0x00,
    LCD_5x10DOTS => 0x04,
    LCD_5x8DOTS => 0x00,
    
    ##
    SEND_MODE_CMD  => 0,
    SEND_MODE_DATA => 1,
    SEND_ENABLE    => 4,
    SEND_DISABLE   => 0,
    SEND_BACKLIGHT => 8,
};

sub new {
    my( $class, %userparams)  = @_;
    	
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        # LCD
        width            =>  undef,
        lines            =>  undef,
        backlightcontrol =>  1,
        device           =>  undef,
        positionmap      =>  undef,
        serialbuffermode =>  0,
        
        # i2c params
        address           => 0x3F,
	    devicename    => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        backend       => 'i2c',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
	
    unless( defined($params{device}) ) {
        $params{device} = HiPi::Interface::PCF8574->new(
            devicename   => $params{devicename},
            address      => $params{address},
            backend      => $params{backend},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub send_text {
    my($self, $text) = @_;
    for my $p ( split(//, $text) ) {
        $self->_send_data( ord($p) );
    }
}

sub send_command {
    my($self, $command) = @_;
    my $lsb = $command & 0x0F;
    my $msb = ( $command >> 4 ) & 0x0F;
    $self->_write_command_part($msb);
    $self->_write_command_part($lsb);
}

sub _send_data {
    my($self, $data) = @_;
    my $lsb = $data & 0x0F;
    my $msb = ( $data >> 4 ) & 0x0F;
    $self->_write_data_part($msb);
    $self->_write_data_part($lsb);
}

sub backlight {
    my($self, $brightness) = @_;
    
    $brightness = 0 if $brightness < 0;
    $brightness = 100 if $brightness > 100;
    
    # $brightness = 0 to 100
    # we translate to 0 - 250
    
    return unless $self->backlightcontrol;
    
    my $bset = int( 2.5 * $brightness);
    $self->_backlight( $bset );
    $self->_write_to_bus(0x00, SEND_MODE_DATA, SEND_DISABLE );
}

sub update_baudrate {
    my $self = shift;
    # not handled
    return;
}

sub update_geometry {
    my $self = shift;
    # not handled
    return;
}

sub _write_command_part {
    my($self, $data) = @_;
    $self->_write_to_bus( $data, SEND_MODE_CMD, SEND_ENABLE );
    $self->delayMicroseconds(1);
    $self->_write_to_bus( $data, SEND_MODE_CMD, SEND_DISABLE );
    $self->delayMicroseconds(40);
}

sub _write_data_part {
    my($self, $data) = @_;
    $self->_write_to_bus( $data, SEND_MODE_DATA, SEND_ENABLE );
    $self->delayMicroseconds(1);
    $self->_write_to_bus( $data, SEND_MODE_DATA, SEND_DISABLE );
    $self->delayMicroseconds(40);
}

sub _write_to_bus {
    my($self, $data, $mode, $onoff) = @_;
    my $byte = $data << 4;
    $byte |= ( $mode & 1 );
    $byte |= SEND_ENABLE if $onoff;
    $byte |= SEND_BACKLIGHT if $self->_backlight;
    $self->device->write_byte( $byte ); 
}

sub init_display {
    my $self = shift;
    
    $self->_write_to_bus(0, 0, 0);
    $self->delay(50); 
    
    # put the LCD into 4 bit mode according to the hitachi HD44780 datasheet figure 26, pg 47
    $self->_write_command_part(0x03);
    $self->delayMicroseconds(4500); 
    $self->_write_command_part(0x03);
    $self->delayMicroseconds(4500); 
    $self->_write_command_part(0x03);
    $self->delayMicroseconds(150); 
    $self->_write_command_part(0x02);
    
    $self->send_command( HD44780_CURSOR_OFF );
}

1;

__END__
