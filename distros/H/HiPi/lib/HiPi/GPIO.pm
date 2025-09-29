#########################################################################################
# Package        HiPi::GPIO
# Description  : Wrapper for GPIO
# Copyright    : Copyright (c) 2017-2023 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::GPIO;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use XSLoader;
use Carp;
use HiPi 0.80;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;

our $VERSION ='0.94';

__PACKAGE__->create_accessors( );

if ( HiPi::is_raspberry_pi() ) {
    if ( HiPi::RaspberryPi::has_rp1() ) {
        XSLoader::load('HiPi::GPIO::RP1', $VERSION);
    } else {
        XSLoader::load('HiPi::GPIO', $VERSION);
    }
}

my $xsok = ( HiPi::is_raspberry_pi() ) ? xs_initialise_gpio_block() : 0;
END { xs_release_gpio_block() if HiPi::is_raspberry_pi(); };

sub error_report {
    my ( $error ) = @_;
    carp qq($error);
}

sub ok { return $xsok; }

sub new {
    my ($class, %userparams) = @_;
    
    my %params = ( );
    
    foreach my $key( sort keys( %params ) ) {
        $params{$key} = $userparams{$key} if exists($userparams{$key});
    }
         
    my $self = $class->SUPER::new(%params);
   
    return $self;
}

sub get_pin {
    my( $class, $pinid ) = @_;
    require HiPi::GPIO::Pin;
    HiPi::GPIO::Pin->_open( pinid => $pinid );
}

sub pin_write {
    my($class, $gpio, $level) = @_;
    return xs_gpio_write( $gpio, $level );
}

sub pin_read {
    my($class, $gpio) = @_;
    return xs_gpio_read( $gpio );
}

sub set_pin_mode {
    my($class, $gpio, $mode) = @_;
    return xs_gpio_set_mode( $gpio, $mode );
}

sub get_pin_mode {
    my($class, $gpio ) = @_;
    return xs_gpio_get_mode( $gpio );
}

sub set_pin_pud {
    my($class, $gpio , $pud ) = @_;
    return xs_gpio_set_pud( $gpio, $pud);
}

sub get_pin_pud {
    my($class, $gpio ) = @_;
    return xs_gpio_get_pud( $gpio );
}

sub set_pin_schmitt {
    my($class, $gpio, $schmitt ) = @_;
    if ( HiPi::RaspberryPi::has_rp1() ) {
        return xs_gpio_set_schmitt( $gpio, $schmitt);
    } else {
        error_report('This Raspberry Pi does not support schmitt operations');
        return -1;
    }
}

sub get_pin_schmitt {
    my($class, $gpio ) = @_;
    if ( HiPi::RaspberryPi::has_rp1() ) {
        return xs_gpio_get_schmitt( $gpio );
    } else {
        error_report('This Raspberry Pi does not support schmitt operations');
        return -1;
    }
}

sub set_pin_slew {
    my($class, $gpio, $slew ) = @_;
    if ( HiPi::RaspberryPi::has_rp1() ) {
        return xs_gpio_set_slew( $gpio, $slew);
    } else {
        error_report('This Raspberry Pi does not support slew operations');
        return -1;
    }
}

sub get_pin_slew{
    my($class, $gpio ) = @_;
    if ( HiPi::RaspberryPi::has_rp1() ) {
        return xs_gpio_get_slew( $gpio );
    } else {
        error_report('This Raspberry Pi does not support slew operations');
        return -1;
    }
}

sub set_pin_activelow {
    my($class, $gpio, $alow ) = @_;
    warn q(HiPi::GPIO does not support active_low);
    return undef;
}

sub get_pin_activelow {
    my($class, $gpio ) = @_;
    warn q(HiPi::GPIO does not support active_low);
    return undef;
}

sub get_pin_interrupt_filepath {
    my($class, $gpio ) = @_;
    warn q(HiPi::GPIO does not support interrupts);
    return undef;
}

sub set_pin_interrupt {
    my($class, $gpio, $newedge ) = @_;
    warn q(HiPi::GPIO does not support interrupts);
    return undef;
}

sub get_pin_interrupt {
    my($class, $gpio ) = @_;
    warn q(HiPi::GPIO does not support interrupts);
    return undef;
}

sub get_pin_function {
    my($class, $gpio) = @_; 
    if ( HiPi::RaspberryPi::has_rp1() ) {
        my ( $funcname, $altnum ) = $class->_get_pin_function_rp1( $gpio );
        return ( wantarray ) ? ( $funcname, $altnum ) : $funcname;
    } else {
        my ( $funcname, $altnum ) = $class->_get_pin_function_bcm2835( $gpio );
        return ( wantarray ) ? ( $funcname, $altnum ) : $funcname;
    }
}

sub _get_pin_function_bcm2835 {
    my($class, $gpio) = @_;
    my $mode = $class->get_pin_mode( $gpio );
    
    my $funcname = 'UNKNOWN';
    my $altnum = undef;
    
    my $alt_function_names = HiPi::RaspberryPi::get_alt_function_names();
    
    if( $mode == -1 ) {
        $funcname = 'ERROR';
    } elsif( $mode == RPI_MODE_INPUT ) {
        $funcname = 'INPUT';
    } elsif( $mode == RPI_MODE_OUTPUT ) {
        $funcname = 'OUTPUT';
    } elsif( $mode == RPI_MODE_ALT0 ) {
        $funcname = $alt_function_names->[$gpio]->[0];
        $altnum = 0;
    } elsif( $mode == RPI_MODE_ALT1 ) {
        $funcname = $alt_function_names->[$gpio]->[1];
        $altnum = 1;
    } elsif( $mode == RPI_MODE_ALT2 ) {
        $funcname = $alt_function_names->[$gpio]->[2];
        $altnum = 2;
    } elsif( $mode == RPI_MODE_ALT3 ) {
        $funcname = $alt_function_names->[$gpio]->[3];
        $altnum = 3;
    } elsif( $mode == RPI_MODE_ALT4 ) {
        $funcname = $alt_function_names->[$gpio]->[4];
        $altnum = 4;
    } elsif( $mode == RPI_MODE_ALT5 ) {
        $funcname = $alt_function_names->[$gpio]->[5];
        $altnum = 5;
    } else {
        $funcname = 'ERROR';
    }
    
    return ( $funcname, $altnum );
}

sub _get_pin_function_rp1 {
    my($class, $gpio) = @_;
    
    my $funcname = xs_gpio_get_current_mode_name($gpio);
    
    return( $funcname, 0);
    
}

sub get_peripheral_base_address {
    return xs_gpio_get_peripheral_base_address();
}

# Aliases

*HiPi::GPIO::get_pin_level = \&pin_read;
*HiPi::GPIO::set_pin_level = \&pin_write;

1;

__END__
