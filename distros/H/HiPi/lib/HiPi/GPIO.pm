#########################################################################################
# Package        HiPi::GPIO
# Description  : Wrapper for GPIO
# Copyright    : Copyright (c) 2017 Mark Dootson
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
use HiPi qw( :rpi );

our $VERSION ='0.79';

__PACKAGE__->create_accessors( );

XSLoader::load('HiPi::GPIO', $VERSION) if HiPi::is_raspberry_pi();

my $xsok = ( HiPi::is_raspberry_pi() ) ? xs_initialise_gpio_block() : 0;
END { xs_release_gpio_block() if HiPi::is_raspberry_pi(); };

use constant {
    GPEDS0   => 16,
    GPREN0   => 19,
    GPFEN0   => 22,
    GPHEN0   => 25,
    GPLEN0   => 28,
    GPAREN0  => 31,
    GPAFEN0  => 34,
};


my @_alt_function_names = (
    [qw( I2C0_SDA      SA5          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 0
    [qw( I2C0_SCL      SA4          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 1
    [qw( I2C1_SDA      SA3          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 2
    [qw( I2C1_SCL      SA2          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 3
    
    [qw( GPCLK0        SA1          ALT2   ALT3   ALT4        ARM_TDI ) ], # GPIO 4
    [qw( ALT0          ALT1         ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 5
    [qw( ALT0          ALT1         ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 6
    [qw( SPI0_CE1_N    SWE_N/SRW_N  ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 7
    
    [qw( SPI0_CE0_N    SD0          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 8
    [qw( SPI0_MISO     SD1          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 9
    [qw( SPI0_MOSI     SD2          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 10
    [qw( SPI0_SCLK     SD3          ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 11
    
    [qw( ALT0          ALT1         ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 12
    [qw( ALT0          ALT1         ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 13
    [qw( UART0_TXD     SD6          ALT2   ALT3   ALT4   UART1_TXD ) ], # GPIO 14
    [qw( UART0_RXD     SD7          ALT2   ALT3   ALT4   UART1_RXD ) ], # GPIO 15
    
    [qw( ALT0          ALT1         ALT2   ALT3   SPI1_CE2_N        ALT5 ) ], # GPIO 16
    [qw( ALT0          SD9          ALT2   UART0_RTS   SPI1_CE1_N  UART1_RTS ) ], # GPIO 17
    [qw( PCM_CLK       SD10         ALT2   BSCSL_SDA/MOSI   SPI1_CE0_N   PWM0 ) ], # GPIO 18
    [qw( ALT0          ALT1         ALT2   ALT3   SPI1_MISO        ALT5 ) ], # GPIO 19
    
    [qw( ALT0          ALT1         ALT2   ALT3   SPI1_MOSI        ALT5 ) ], # GPIO 20
    [qw( ALT0          ALT1         ALT2   ALT3   SPI1_SCLK        GPCLK1 ) ], # GPIO 21
    [qw( ALT0          SD14         ALT2   SD1_CLK   ARM_TRST ALT5 ) ], # GPIO 22
    [qw( ALT0          SD15         ALT2   SD1_CMD   ARM_RTCK ALT5 ) ], # GPIO 23
    
    [qw( ALT0          SD16         ALT2   SD1_DAT0  ARM_TDO  ALT5 ) ], # GPIO 24
    [qw( ALT0          SD17         ALT2   SD1_DAT1  ARM_TCK  ALT5 ) ], # GPIO 25
    [qw( ALT0          ALT1         ALT2   ALT3   ALT4        ALT5 ) ], # GPIO 26
    [qw( ALT0          ALT1         ALT2   SD1_DAT3  ARM_TMS  GPCLK1 ) ], # GPIO 27
    
    [qw( I2C0_SDA      SA5          PCM_CLK  ALT3   ALT4      ALT5 ) ], # GPIO 28
    [qw( I2C0_SCL      SA4          PCM_FS   ALT3   ALT4      ALT5 ) ], # GPIO 29
    [qw( ALT0          SA3          PCM_DIN  UART0_CTS   ALT4 UART1_CTS ) ], # GPIO 30
    [qw( ALT0          SA2          PCM_DOUT UART0_RTS   ALT4 UART1_RTS ) ], # GPIO 31
    
);

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
    my $mode = $class->get_pin_mode( $gpio );
    my $funcname = 'UNKNOWN';
    my $altnum = undef;
    if( $mode == -1 ) {
        $funcname = 'ERROR';
    } elsif( $mode == RPI_MODE_INPUT ) {
        $funcname = 'INPUT';
    } elsif( $mode == RPI_MODE_OUTPUT ) {
        $funcname = 'OUTPUT';
    } elsif( $mode == RPI_MODE_ALT0 ) {
        $funcname = $_alt_function_names[$gpio]->[0];
        $altnum = 0;
    } elsif( $mode == RPI_MODE_ALT1 ) {
        $funcname = $_alt_function_names[$gpio]->[1];
        $altnum = 1;
    } elsif( $mode == RPI_MODE_ALT2 ) {
        $funcname = $_alt_function_names[$gpio]->[2];
        $altnum = 2;
    } elsif( $mode == RPI_MODE_ALT3 ) {
        $funcname = $_alt_function_names[$gpio]->[3];
        $altnum = 3;
    } elsif( $mode == RPI_MODE_ALT4 ) {
        $funcname = $_alt_function_names[$gpio]->[4];
        $altnum = 4;
    } elsif( $mode == RPI_MODE_ALT5 ) {
        $funcname = $_alt_function_names[$gpio]->[5];
        $altnum = 5;
    } else {
        $funcname = 'ERROR';
    }
    
    return ( wantarray ) ? ( $funcname, $altnum ) : $funcname;
}

sub get_peripheral_base_address {
    return xs_gpio_get_peripheral_base_address();
}

## edge detect functions conflict with system

#sub get_pin_edge_detect {
#    my( $self, $gpio ) = @_;
#    return xs_gpio_read_edge_detect( $gpio );
#}
#
#sub clear_pin_edge_detect {
#    my( $self, $gpio ) = @_;
#    return xs_gpio_clear_edge_detect( $gpio );
#}
#
#sub set_rising_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPREN0(), $val);
#}
#
#sub get_rising_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPREN0());
#}
#
#sub set_falling_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPFEN0(), $val);
#}
#
#sub get_falling_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPFEN0());
#}
#
#sub set_high_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPHEN0(), $val);
#}
#
#sub get_high_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPHEN0());
#}
#
#sub set_low_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPLEN0(), $val);
#}
#
#sub get_low_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPLEN0());
#}
#
#sub set_async_rising_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPAREN0(), $val);
#}
#
#sub get_async_rising_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPAREN0());
#}
#
#sub set_async_falling_edge_detect {
#    my($class, $gpio, $val) = @_;
#    $val //= 0;
#    return xs_gpio_set_edge_detect( $gpio, GPAFEN0(), $val);
#}
#
#sub get_async_falling_edge_detect {
#    my($class, $gpio) = @_;
#    return xs_gpio_get_edge_detect( $gpio, GPAFEN0());
#}

# Aliases

*HiPi::GPIO::get_pin_level = \&pin_read;
*HiPi::GPIO::set_pin_level = \&pin_write;

1;

__END__
