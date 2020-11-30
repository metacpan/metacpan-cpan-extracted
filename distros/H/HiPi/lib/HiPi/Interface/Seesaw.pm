#########################################################################################
# Package        HiPi::Interface::Seesaw
# Description  : Module for Adafruit seesaw breakouts
# Copyright    : Copyright (c) 2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Seesaw;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :rpi :seesaw);
use Carp;
use HiPi::RaspberryPi;
use HiPi::Device::I2C;

use constant {
    EEPROM_MAX_ADDRESS => 0x3E,
    EEPROM_I2C_ADDRESS => 0x3F,
};

my @initaccessors = ( qw(
                    _can_pwm_freq _pwm_width _version _datecode _productcode
                    _auto_flow_control
                    _pwm_ms_per_cycle_A _pwm_true_freq_A
                    _pwm_ms_per_cycle_B _pwm_true_freq_B
                    _options _hardware_id
                    _neopixel_pin _neopixel_colourmap _neopixel_bpp
                    _neopixel_col_byte_map _neopixel_brightness
                    _neopixel_buffer _neopixel_pixels 
                     ) );

__PACKAGE__->create_accessors( qw(  address devicename board delay pinmap ) );

__PACKAGE__->create_accessors( @initaccessors );

our $VERSION ='0.85';

sub new {
    my ($class, %userparams) = @_;
    
    my $pi = HiPi::RaspberryPi->new();
    
    my %params = (
        devicename   => ( $pi->board_type == RPI_BOARD_TYPE_1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        device       => undef,
        delay   => 500,
        reset   => 0,
        pinmap => {
            gpio => {
                9   => 1,
                10  => 1,
                11  => 1,
                14  => 1,
                15  => 1,
                24  => 1,
                25  => 1,  
            },
            adc => {
                2 => 0,
                3 => 1,
                4 => 2,
                # 5 => 3,
            },
            pwm => {
                #4 => 0,
                5 => 1,
                6 => 2,
                7 => 3,
            },
            irq => {
                8 => 1,
            },
        },
    );
    
    my $board = $userparams{board} || SEESAW_ATSAMD09;
    
    if ( $board == SEESAW_ATSAMD09 ) {
        $params{address} = 0x49,
    } else {
        croak q(Unsupported board. Supported board constants are SEESAW_ATSAMD09);
    }
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless(defined($params{device})) {
        $params{device} = HiPi::Device::I2C->new(
            address      => $params{address},
            devicename   => $params{devicename},
        );
    }
    
    my $resetrequested = $params{reset},
    
    my $self = $class->SUPER::new(%params);
    
    if( $resetrequested ) {
        $self->software_reset;
    } else {
        $self->_init;
    }
    
    return $self;
}

sub _init {
    my $self = shift;
    
    # set undefined properties
    for my $property( @initaccessors ) {
        $self->$property(undef);
    }
    
    my @vervals = $self->read_register(SEESAW_STATUS_BASE, SEESAW_STATUS_VERSION, 4, 8000);
    my $version = ($vervals[0] << 24) | ( $vervals[1] << 16 ) | ($vervals[2] << 8) | $vervals[3];
    my $productnum = $version >> 16;
    my $datecode = $version & 0xFFFF;
    my $year  = $datecode >> 9;
    my $month = ($datecode >> 5) & 0xF;
    my $day   = $datecode & 0x1F;
    my $datevalue = sprintf('%d%02d%02d', 2000 + $year, $month, $day);
    
    $self->_version($version);
    $self->_datecode($datevalue);
    $self->_productcode($productnum);
    
    # unset the options
    $self->_options(undef);
    $self->_hardware_id(undef);
    
    
    # There are two firmware versions that may be loaded on the seesaw as shipped
    #---------------------------------
    # date value 20171023
    #---------------------------------
    # This is the original version on all seesaw boards shipped before Sept 14, 2020
    # This firmware cannot effectively set PWM frequency, lacks auto flow control
    # and has a bug in the neopixel code for greater than 63 pixels
    #
    # firmware is https://github.com/adafruit/seesaw/releases/tag/1.0.1
    
    #---------------------------------
    # date value 20200831
    #---------------------------------
    # This is the official firmware loaded on boards shipped after Sept 14, 2020
    # which fixes the issues with PWM and Neopixels and has auto flow control
    #
    # I assume firmware is latest official release :
    # https://github.com/adafruit/seesaw/releases/tag/1.1.6
    
    # other firmware versions
    
    #---------------------------------
    # date value 20180109
    #---------------------------------
    # In response to the PWM frequency issue raised at https://github.com/adafruit/seesaw/issues/4
    # A compiled firmware was made available that has this date value.
    # It was never loaded on any seesaw as shipped but needed to be loaded by the user.
    # It fixed the PWM issue. It does not have auto flow control
    #
    # firmware from https://github.com/adafruit/seesaw/files/1616082/seesaw_new_firmware.zip
    # Probably built from master branch around that time
    
    #---------------------------------
    # date value 20190801
    #---------------------------------
    # For my own development with pre Sept 14, 2020 boards I built firmware from official release
    # https://github.com/adafruit/seesaw/releases/tag/1.1.6
    # This fixes the issues with PWM and Neopixels and has auto flow control

    if ($datevalue ge '20190801') {
        $self->_pwm_width(16);
        $self->_can_pwm_freq(1);
        $self->_auto_flow_control(1);
    } elsif ($datevalue ge '20180109') {
        $self->_pwm_width(16);
        $self->_can_pwm_freq(1);
        $self->_auto_flow_control(0);
    } else {
        $self->_pwm_width(8);
        $self->_can_pwm_freq(0);
        $self->_auto_flow_control(0);
    }
    return;
}

sub _check_pin_map {
    my($self, $map, @pins) = @_;
    my $badpins = '';
    my $pinmap = $self->pinmap;
    for my $pin( @pins ) {
        $pin ||= 0;
        if (!exists($pinmap->{$map}->{$pin})) {
            $badpins .= ', ' if $badpins;
            $badpins .= $pin;
        }
    }
    return $badpins;
}

sub _check_pin_map_interrupt {
    my($self,  @pins) = @_;
    my $badpins = '';
    my $pinmap = $self->pinmap;
    for my $pin( @pins ) {
        $pin ||= 0;
        if ( !exists($pinmap->{gpio}->{$pin}) &&
             !exists($pinmap->{adc}->{$pin}) ) {
            $badpins .= ', ' if $badpins;
            $badpins .= $pin;
        }
    }
}

sub _get_pin_mask {
    my ( $self, @pins ) = @_;
    my @cmdbytes = (0,0,0,0);
    for my $pin ( @pins ) {
        croak 'zero or undefined pin' unless( $pin );
        my $byte = 3 - int($pin / 8);
        my $bits = $pin % 8;
        $cmdbytes[$byte] |= ( 1 << $bits );
    }
    return @cmdbytes;
}

sub _map_pin_mask {
    my($self, $bytes, @pins) = @_;
    my @results = ();
    for my $pin ( @pins ) {
        croak 'zero or undefined pin' unless( $pin );
        my $byte = 3 - int($pin / 8);
        my $bits = $pin % 8;
        my $value = 1 << $bits;
        if ( $bytes->[$byte] & $value ) {
            push @results, 1;
        } else {
            push @results, 0;
        }
    }
    return @results;
}

sub read_register {
    my($self, $regbase, $regmember, $numbytes, $delay) = @_;
    $delay //= $self->delay;
    $self->device->i2c_write($regbase, $regmember);
    $self->sleep_microseconds( $delay );
    my @vals = $self->device->i2c_read( $numbytes );
    return @vals;
}

sub write_register {
    my($self, $regbase, $regmember, @bytes) = @_;
    $self->device->i2c_write($regbase, $regmember, @bytes);
}

sub get_version { return $_[0]->_version; }
    
sub get_date_code { return $_[0]->_datecode; }
   
sub get_product_code { return $_[0]->_productcode; }

sub get_hardware_id {
    my $self = shift;
    unless( $self->_hardware_id ) {
        my ( $hwid ) = $self->read_register( SEESAW_STATUS_BASE, SEESAW_STATUS_HW_ID, 1 );
        $self->_hardware_id( $hwid );
    }    
    return $self->_hardware_id;
}

sub get_options {
    my $self = shift;
    unless( $self->_options ) {
        my @vals = $self->read_register(SEESAW_STATUS_BASE, SEESAW_STATUS_OPTIONS, 4);
        my $opts = ($vals[0] << 24) | ($vals[1] << 16) | ($vals[2] << 8) | $vals[3];        
        $self->_options( $opts );
    }
    return $self->_options;
}

sub get_option_names {
    my $self = shift;
    
    my @optionnames = (
        undef,      # 0
        'GPIO',      # 1
        'UART0',     # 2
        'UART1',     # 3
        'UART2',     # 4
        'UART3',     # 5
        'UART4',     # 6
        'UART5',     # 7
        'PWM',       # 8
        'ADC',       # 9
        'DAC',       # A
        'INTERRUPT', # B
        'DAP',       # C
        'EEPROM',    # D
        'NEOPIXEL',  # E
        'TOUCH',     # F
    );
    
    my $opts = $self->get_options();
    
    my @strings = ();
    
    for (my $i = 0; $i < @optionnames; $i++) {
        my $string = $optionnames[$i];
        next if !defined($string);
        if( ($opts & ( 1 << $i ) ) > 0 ) {
            push @strings, $string;
        } elsif( $i == SEESAW_EEPROM_BASE ) {
            if (  $self->get_hardware_id == 0x55 ) {
                push @strings, $string;
            }
        }
    }
    
    return ( wantarray ) ? @strings : join(',', @strings);
}

sub software_reset {
    my $self = shift;
    $self->write_register(SEESAW_STATUS_BASE, SEESAW_STATUS_SWRST, 0xFF);
    $self->sleep_milliseconds($self->delay);
    $self->_init;
    return;
}

#----------------------------------------------------
# GPIO
#----------------------------------------------------

sub gpio_set_pin_mode {
    my($self, @pins) = @_;
    
    my $mode = pop @pins;
    
    if (my $badpins = $self->_check_pin_map('gpio', @pins) ) {
        croak 'Invalid pin numbers for gpio_set_pin_mode : ' . $badpins;
    }
    my @bytes = $self->_get_pin_mask( @pins );
    if ( $mode == SEESAW_OUTPUT) {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_DIRSET_BULK, @bytes);
    } elsif( $mode == SEESAW_INPUT) {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_DIRCLR_BULK, @bytes);
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_PULLENCLR , @bytes);
    } elsif( $mode == SEESAW_INPUT_PULLUP) {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_DIRCLR_BULK, @bytes);
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_PULLENSET , @bytes);
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_BULK_SET, @bytes);
    } elsif( $mode == SEESAW_INPUT_PULLDOWN) {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_DIRCLR_BULK, @bytes);
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_PULLENSET , @bytes);
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_BULK_CLR, @bytes);
    } else {
        croak 'Invalid mode for gpio_set_pin_mode';
    }
    $self->sleep_microseconds( $self->delay );
    return;
}

sub gpio_set_pin_value {
    my($self, @pins) = @_;
    my $value = pop @pins;
    if (my $badpins = $self->_check_pin_map('gpio', @pins) ) {
        croak 'Invalid pin numbers for gpio_set_pin_value : ' . $badpins;
    }
    my @bytes = $self->_get_pin_mask( @pins );
    if($value) {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_BULK_SET, @bytes);
    } else {
        $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_BULK_CLR, @bytes);
    }
}

sub gpio_get_pin_value {
    my($self, @pins) = @_;
    if (my $badpins = $self->_check_pin_map('gpio', @pins) ) {
        croak 'Invalid pin numbers for gpio_get_pin_value : ' . $badpins;
    }
    
    # get all pins
    my @bytes = $self->read_register(SEESAW_GPIO_BASE , SEESAW_GPIO_BULK, 4 );
    my @results = $self->_map_pin_mask(\@bytes, @pins );
    
    return wantarray ? @results : $results[0];
}

sub gpio_toggle_pin_value {
    my($self, @pins) = @_;
    if (my $badpins = $self->_check_pin_map('gpio', @pins) ) {
        croak 'Invalid pin numbers for gpio_toggle_pin_value : ' . $badpins;
    }
    my @bytes = $self->_get_pin_mask( @pins );
    $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_BULK_TOGGLE, @bytes);
    carp('toggle not working with seesaw SAMD09');
    return;
}

sub gpio_enable_interrupt {
    my($self, @pins) = @_;
    if (my $badpins = $self->_check_pin_map_interrupt( @pins ) ) {
        croak 'Invalid pin numbers for gpio interrupt : ' . $badpins;
    }
    my @bytes = $self->_get_pin_mask( @pins );
    $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_INTENSET, @bytes);
    $self->sleep_microseconds( $self->delay );
    return;
}

sub gpio_disable_interrupt {
    my($self, @pins) = @_;
    if (my $badpins = $self->_check_pin_map_interrupt( @pins ) ) {
        croak 'Invalid pin numbers for gpio interrupt : ' . $badpins;
    }
    my @bytes = $self->_get_pin_mask( @pins );
    $self->write_register(SEESAW_GPIO_BASE, SEESAW_GPIO_INTENCLR, @bytes);
    $self->sleep_microseconds( $self->delay );
    return;
}

sub gpio_get_interrupt_flags {
    my($self, @pins) = @_;
    if (my $badpins = $self->_check_pin_map_interrupt( @pins) ) {
        croak 'Invalid pin numbers for gpio_get_pin_interrupt : ' . $badpins;
    }
    
    # get all pins
    my @bytes = $self->read_register(SEESAW_GPIO_BASE , SEESAW_GPIO_INTFLAG, 4 );
    my @results = $self->_map_pin_mask(\@bytes, @pins );
    
    return wantarray ? @results : $results[0];
}

#-------------------------------------------------------
# NEOPIXEL
#-------------------------------------------------------

sub set_neopixel {
    my($self, %userparams) = @_;
    
    my $checkpin = $userparams{pin} || 'MISSING';
    
    if (my $badpins = $self->_check_pin_map('gpio', $checkpin) ) {
        croak 'Invalid pin number for get_neopixel : ' . $badpins;
    }
    
    my %params = (
        pixels     => 1,
        colourmap  => SEESAW_NEOPIXEL_GRBW,
        speed      => SEESAW_NEOPIXEL_KHZ800,
        brightness => 5,
    );
    
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    if ($params{colormap}) {
        $params{colourmap} = $params{colormap};
    }
    
    if ( $params{colourmap} == SEESAW_NEOPIXEL_RGB ) {
        $params{bpp} = 3;
        $params{col_byte_map} = [ 0, 1, 2 ];
    } elsif($params{colourmap} == SEESAW_NEOPIXEL_GRB ) {
        $params{bpp} = 3;
        $params{col_byte_map} = [ 1, 0, 2 ];
    } elsif($params{colourmap} == SEESAW_NEOPIXEL_RGBW ) {
        $params{bpp} = 4;
        $params{col_byte_map} = [ 0, 1, 2, 3 ];
    } elsif($params{colourmap} == SEESAW_NEOPIXEL_GRBW ) {
        $params{bpp} = 4;
        $params{col_byte_map} = [ 1, 0, 2, 3 ];
    } else {
        croak 'no valid colourmap provided for neopixel';
    }
    
    my @buffer;
    
    #_neopixel_pin _neopixel_colourmap _neopixel_bpp
    #_neopixel_col_byte_map _neopixel_brightness
    #_neopixel_buffer
    
    for(my $i = 0; $i < $params{pixels}; $i++) {
        $buffer[$i] = [0,0,0,0,0];
    }
    
    $self->_neopixel_pixels( $params{pixels} );
    $self->_neopixel_pin( $params{pin} );
    $self->_neopixel_bpp( $params{bpp} );
    $self->_neopixel_col_byte_map( $params{col_byte_map} );
    $self->_neopixel_buffer( \@buffer );
    $self->_neopixel_brightness( $params{brightness} );
    
    # set pin
    $self->gpio_set_pin_mode($self->_neopixel_pin, SEESAW_OUTPUT);
    $self->write_register(SEESAW_NEOPIXEL_BASE, SEESAW_NEOPIXEL_PIN, $self->_neopixel_pin);
        
    # speed
    $self->write_register(SEESAW_NEOPIXEL_BASE, SEESAW_NEOPIXEL_SPEED, $params{speed} );
    
    # bufflen
    my $blen = 2 + ($self->_neopixel_pixels * $self->_neopixel_bpp);
    my $msb = ( $blen & 0xFF00 ) >> 8;
    my $lsb = $blen & 0xFF;
    $self->write_register(SEESAW_NEOPIXEL_BASE, SEESAW_NEOPIXEL_BUF_LENGTH, $msb, $lsb);
    
    return 1;
}

sub neopixel_show {
    my ($self ) = @_;
    return unless($self->_neopixel_pin);
    $self->_flush_neopixel_buffer();
    $self->write_register( SEESAW_NEOPIXEL_BASE, SEESAW_NEOPIXEL_SHOW );
    $self->sleep_microseconds($self->delay);
}

sub neopixel_clear {
    my ($self) = @_;
    my @colour = (0,0,0,0,0);
    for( my $i = 0; $i < $self->_neopixel_pixels; $i++ ) {
        $self->neopixel_set_pixel($i, @colour );
    }
    $self->neopixel_show();
}

sub neopixel_set_brightness {
    my($self, $newval) = @_;
    $newval = 0 if $newval < 0;
    $newval = 100 if $newval > 100;
    $self->_neopixel_brightness( $newval );
}

sub neopixel_set_pixel {
    my($self, $pixel, $r, $g, $b, $w, $l) = @_;
    if ($pixel < 0 || $pixel >= $self->_neopixel_pixels) {
        carp qq(invalid pixel number $pixel);
        return;
    }
    
    $w //= 0;
    $l //= $self->_neopixel_brightness;
    $l = 0 if $l < 0;
    $l = 100 if $l > 100;
    
    my @cols =  ( $r, $g, $b, $w );
    
    for ( @cols) {
        $_ = 0 if $_ < 0;
        $_ = 255 if $_ > 255;
    }
    
    for (my $i = 0; $i < $self->_neopixel_bpp; $i++ ) {
        my $map = $self->_neopixel_col_byte_map->[$i];
        $self->_neopixel_buffer->[$pixel]->[$i] = $cols[$map];
    }
    
    $self->_neopixel_buffer->[$pixel]->[-1] = $l;
}

sub _flush_neopixel_buffer {
    my ($self ) = @_;
    
    for (my $i = 0; $i < @{ $self->_neopixel_buffer }; $i ++) {
        my $pixel = $self->_neopixel_buffer->[$i];
        my $brightness = $pixel->[-1];
        my @bytes = ( 0,  ($i * $self->_neopixel_bpp) & 0xFF );
        for (my $i = 0; $i < $self->_neopixel_bpp; $i++) {
            my $val = $pixel->[$i];
            if ( $brightness < 100 ) {
                $val = int($val * $brightness / 100);
            }
            push @bytes, $val & 0xFF;
        }
        
        $self->write_register(SEESAW_NEOPIXEL_BASE, SEESAW_NEOPIXEL_BUF, @bytes);
    }
    
    return;
}

#---------------------------------------------------------
# ADC
#---------------------------------------------------------

sub adc_read {
    my($self, $pin) = @_;
    if (my $badpins = $self->_check_pin_map('adc', $pin) ) {
        croak 'Invalid pin number for adc_read : ' . $badpins;
    }
    
    my $adcreg = 0;
    
    if ($pin == SEESAW_PA02) {
        $adcreg = 0x07;
    } elsif($pin == SEESAW_PA03) {
        $adcreg = 0x08;
    } elsif($pin == SEESAW_PA04) {
        $adcreg = 0x09;
    #} elsif($pin == SEESAW_PA05) {
    #    $adcreg = 0x0A;
    } else {
        croak 'Invalid pin number for adc_read : ' . $pin;
    }
    $self->sleep_milliseconds(5) unless $self->_auto_flow_control;
    my($msb, $lsb) = $self->read_register( SEESAW_ADC_BASE, $adcreg, 2 );
    my $result = ($msb << 8) | $lsb;
    return $result & 0x3FF;
}

sub adc_read_v {
    my($self, $pin, $ref) = @_;
    $ref //= 3.3;
    my $tenbit = $self->adc_read($pin);    
    my $result = $tenbit / 1023 * $ref;
    return $result;
}

sub adc_read_percent {
    my($self, $pin) = @_;
    my $tenbit = $self->adc_read($pin);
    my $result = ($tenbit * 100) / 1023;
    return $result;
}

#---------------------------------------------------------
# EEPROM
#---------------------------------------------------------

sub eeprom_read {
    my($self, $address) = @_;
    if ( $address < 0 || $address > EEPROM_MAX_ADDRESS ) {
        carp sprintf(qq(invalid eeprom address 0x%X - must be in the range 0x00 to 0x3E), $address);
        return;
    }
    
    my( $val) = $self->read_register( SEESAW_EEPROM_BASE, $address, 1 );
    return $val;
}

sub eeprom_write {
    my($self, $address, @values) = @_;
    
    if ( $address < 0 || $address > EEPROM_MAX_ADDRESS ) {
        carp sprintf(qq(invalid eeprom address 0x%X - must be in the range 0x00 to 0x3E), $address);
        return;
    }
    
    my $numvalues = scalar @values;
    my $maxvalues = EEPROM_I2C_ADDRESS - $address;
    
    if ( $numvalues > $maxvalues) {
        carp q(Too many values for eeprom write would overwrite I2C address.);
        return 0;
    }
    
    $self->write_register( SEESAW_EEPROM_BASE, $address, @values );
    return $numvalues;
}

sub get_i2c_address {
    my($self) = @_;
    my( $i2c_address) = $self->read_register( SEESAW_EEPROM_BASE, EEPROM_I2C_ADDRESS, 1 );
    return $i2c_address;
}

sub set_i2c_address {
    my($self, $value) = @_;
    $self->write_register( SEESAW_EEPROM_BASE, EEPROM_I2C_ADDRESS, $value );
}

#---------------------------------------------------------
# PWM
#---------------------------------------------------------

sub get_pwm_width { return $_[0]->_pwm_width; }

sub pwm_can_set_frequency { return $_[0]->_can_pwm_freq; }

sub _get_pwm_reg_and_timer_for_pin {
    my($self, $pin) = @_;
    
    $pin //= 0; # prevent undef and ==
    
    my ( $pwmreg, $timer );
    
    if ($pin == SEESAW_PA07) {
        $pwmreg = 3;
        $timer = 'B';
    } elsif($pin == SEESAW_PA06) {
        $pwmreg = 2;
        $timer = 'B';
    } elsif($pin == SEESAW_PA05) {
        $pwmreg = 1;
        $timer = 'A';
    } elsif($pin == SEESAW_PA04) {
    #    $pwmreg = 0;
    #    $timer  = 'A';
    } else {
        croak 'Invalid pin number for PWM frequency : ' . $pin;
    }
    
    return ( $pwmreg, $timer );
}

sub pwm_set_frequency {
    my($self, $pin, $value ) = @_;
    
    # PWM pins 4 and 5 share a timer, and PWM pins 6 and 7 share a timer.
    
    if (my $badpins = $self->_check_pin_map('pwm', $pin) ) {
        croak 'Invalid pin number for pwm : ' . $badpins;
    }
    
    if ($value < 0 || $value > 800) {
        croak( 'Value for PWM frequency must be 0 to 720' );
    }
    
    my ( $pwmreg, $timer ) = $self->_get_pwm_reg_and_timer_for_pin( $pin );
            
    #uint8_t prescale = TC_CTRLA_PRESCALER_DIV256_Val;                       = 2.8125HZ
    #    if( freq > 500) prescale = TC_CTRLA_PRESCALER_DIV1_Val;             = 720HZ
    #    else if( freq > 250 ) prescale = TC_CTRLA_PRESCALER_DIV2_Val;       = 360HZ
    #    else if( freq > 140 ) prescale = TC_CTRLA_PRESCALER_DIV4_Val;       = 180HZ
    #    else if( freq > 75 ) prescale = TC_CTRLA_PRESCALER_DIV8_Val;        = 90HZ
    #    else if( freq > 25 ) prescale = TC_CTRLA_PRESCALER_DIV16_Val;       = 45HZ
    #    else if( freq > 7 ) prescale = TC_CTRLA_PRESCALER_DIV64_Val;        = 11.25HZ
    
    my ( $truefreq, $mspercycle );
    
    unless( $self->pwm_can_set_frequency ) {
        # record default frequencies
        $truefreq = 48000000 / ( ( 65535 + 1024 ) / 4 );
        $mspercycle = 1000000 / $truefreq;
        my $carp = 'Cannot set frequency with firmware dated ' . $self->get_date_code;
        $carp .= qq(\nFrequency is $truefreq HZ\nMicroseconds Per Cycle is $mspercycle us);
        carp $carp;
        if ( $timer eq 'A') {
            $self->_pwm_ms_per_cycle_A( $mspercycle );
            $self->_pwm_true_freq_A( $truefreq );
        } elsif ( $timer eq 'B') {
            $self->_pwm_ms_per_cycle_B( $mspercycle );
            $self->_pwm_true_freq_B( $truefreq );
        } else {
            croak 'unable to determine timer for pin';
        }
        return $truefreq;
    }
    
    my $psdivider = 256;
    if ( $value > 500 ) {
        $psdivider = 1;
    } elsif ( $value > 250 ) {
        $psdivider = 2;
    } elsif ( $value > 140 ) {
        $psdivider = 4;
    } elsif ( $value > 75 ) {
        $psdivider = 8;
    } elsif ( $value > 25 ) {
        $psdivider = 16;
    } elsif ( $value > 7 ) {
        $psdivider = 64;
    }
    
    $truefreq = 48000000 / ( $psdivider * ( 65535 + 1024 ) );
    $mspercycle = 1000000 / $truefreq;
        
    if ( $timer eq 'A') {
        $self->_pwm_ms_per_cycle_A( $mspercycle );
        $self->_pwm_true_freq_A( $truefreq );
    } elsif ( $timer eq 'B') {
        $self->_pwm_ms_per_cycle_B( $mspercycle );
        $self->_pwm_true_freq_B( $truefreq );
    } else {
        croak 'unable to determine timer for pin';
    }
        
    my $msb = ($value >> 8) & 0xFF;
    my $lsb = $value & 0xFF;
    
    $self->write_register(SEESAW_TIMER_BASE, SEESAW_TIMER_FREQ, $pwmreg, $msb, $lsb );
    
    return $truefreq;
}

sub pwm_get_frequency {
    my($self, $pin) = @_;
    
    if (my $badpins = $self->_check_pin_map('pwm', $pin) ) {
        croak 'Invalid pin number for pwm : ' . $badpins;
    }
    
    if (!$self->pwm_can_set_frequency) {
        #code
        my $truefreq = 48000000 / ( ( 65535 + 1024 ) / 4 );
        return $truefreq;
    }

    my ( $pwmreg, $timer ) = $self->_get_pwm_reg_and_timer_for_pin( $pin );
    
    my $frequency = 0;
    
    if ( $timer eq 'A') {
        $frequency = $self->_pwm_true_freq_A();
    } elsif ( $timer eq 'B') {
        $frequency = $self->_pwm_true_freq_B();
    }
    
    # return zero if we have not set frequency
    $frequency ||= 0;
        
    return $frequency;
}

sub pwm_get_micros_per_cycle {
    my($self, $pin) = @_;
    
    if (my $badpins = $self->_check_pin_map('pwm', $pin) ) {
        croak 'Invalid pin number for pwm : ' . $badpins;
    }
    
    my ( $pwmreg, $timer ) = $self->_get_pwm_reg_and_timer_for_pin( $pin );
    
    my $us = 0;
    
    if ( $timer eq 'A') {
        $us = $self->_pwm_ms_per_cycle_A();
    } elsif ( $timer eq 'B') {
        $us = $self->_pwm_ms_per_cycle_B();
    }
    
    return $us;
}

sub pwm_set_duty_cycle {
    my($self, $pin, $value) = @_;
    
    if (my $badpins = $self->_check_pin_map('pwm', $pin) ) {
        croak 'Invalid pin number for pwm : ' . $badpins;
    }
    
    $value &= 0xFFFF;
    
    if ($value > 65535) {
        $value = 65535;
    } elsif( $value < 0 ) {
        $value = 0;
    }
    
    my ( $pwmreg, $timer ) = $self->_get_pwm_reg_and_timer_for_pin( $pin );
    
    my $msb = ($value >> 8) & 0xFF;
    my $lsb = $value & 0xFF;
    
    if ( $self->get_pwm_width == 16 ) {   
        $self->write_register(SEESAW_TIMER_BASE, SEESAW_TIMER_PWM, $pwmreg, $msb, $lsb );
    } else {
        $self->write_register(SEESAW_TIMER_BASE, SEESAW_TIMER_PWM, $pwmreg, $msb );
    }
    return $value;
}

sub pwm_set_pulse_width {
    my( $self, $pin, $microseconds) = @_;
    
    if (my $badpins = $self->_check_pin_map('pwm', $pin) ) {
        croak 'Invalid pin number for pwm : ' . $badpins;
    }
    
    my $dutycycle;
    
    my ( $pwmreg, $timer ) = $self->_get_pwm_reg_and_timer_for_pin( $pin );
    
    if ( $timer eq 'A') {
        $dutycycle = int( 0.5 + (( 65535 / $self->_pwm_ms_per_cycle_A) * $microseconds));
    } elsif ( $timer eq 'B') {
        $dutycycle = int( 0.5 + (( 65535 / $self->_pwm_ms_per_cycle_B) * $microseconds));
    } else {
        croak 'unable to determine timer for pin';
    }
    
    if ($dutycycle > 65535) {
        $dutycycle = 65535;
    } elsif( $dutycycle < 0 ) {
        $dutycycle = 0;
    }
    
    my $rval = $self->pwm_set_duty_cycle($pin, $dutycycle );
    
    return $rval;
}

1;

__END__
