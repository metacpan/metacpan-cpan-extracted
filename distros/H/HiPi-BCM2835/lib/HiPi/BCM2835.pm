#########################################################################################
# Package        HiPi::BCM2835
# Description  : Wrapper for bcm2835 C library - Access to /dev/mem
# Created        Fri Nov 23 13:55:49 2012
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This work is free software; you can redistribute it and/or modify it 
#                under the terms of the GNU General Public License as published by the 
#                Free Software Foundation; either version 3 of the License, or any later 
#                version.
#########################################################################################

package HiPi::BCM2835;

#########################################################################################

use strict;
use warnings;
use threads::shared;
use parent qw( HiPi::Device );
use XSLoader;
use Carp;
use HiPi qw( :rpi :i2c );

our $VERSION ='0.64';

XSLoader::load('HiPi::BCM2835', $VERSION) if HiPi::is_raspberry_pi();

our $_memmapped : shared;

{
    lock $_memmapped;
    $_memmapped = 0;
}

sub bcm2835_init {
    lock $_memmapped;
    
    unless( $_memmapped ) {
        _hipi_bcm2835_init() or croak 'Failed to initialise libbcm2835';
        $_memmapped = 1;
    }
}

sub bcm2835_close {
    # only close in main thread which has tid of zero
    return if( $threads::threads && threads->tid );
    lock $_memmapped;
    if( $_memmapped ) {
        _hipi_bcm2835_close();
        $_memmapped = 0;
    }
}


END{
    bcm2835_close();
}

sub CLONE_SKIP {
    return 1;
}


require HiPi::BCM2835::Pin;

# Constants for libbcm2835

our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _register_exported_constants {
    my( $tag, @constants ) = @_;
    $EXPORT_TAGS{$tag} = \@constants;
    push( @EXPORT_OK, @constants);
}

# define HIGH / LOW at MyPi level as RPI_HIGH / RPI_LOW

use constant {
    BCM2835_CORE_CLK_HZ => 250000000,
    BCM2835_ST_CS       =>    0x0000,
    BCM2835_ST_CLO      =>    0x0004,
    BCM2835_ST_CHI      =>    0x0008,
};

_register_exported_constants( qw(
    clock
    BCM2835_CORE_CLK_HZ
    BCM2835_ST_CS 
    BCM2835_ST_CLO
    BCM2835_ST_CHI
    ) );

#-------------------------------------------------------
# Physical addresses for various peripheral regiser sets
#-------------------------------------------------------

sub BCM2835_GPIO_BASE  { bcm2835_gpio(); }
sub BCM2835_GPIO_PWM   { bcm2835_pwm();  }
sub BCM2835_CLOCK_BASE { bcm2835_clk();  }
sub BCM2835_GPIO_PADS  { bcm2835_pads(); }
sub BCM2835_SPI0_BASE  { bcm2835_spi0(); }
sub BCM2835_BSC0_BASE  { bcm2835_bsc0(); }
sub BCM2835_BSC1_BASE  { bcm2835_bsc1(); }
sub BCM2835_ST_BASE    { bcm2835_st();   }

_register_exported_constants( qw(
    registers
    BCM2835_ST_BASE
    BCM2835_GPIO_PADS
    BCM2835_CLOCK_BASE
    BCM2835_GPIO_BASE
    BCM2835_SPI0_BASE
    BCM2835_BSC0_BASE
    BCM2835_GPIO_PWM
    BCM2835_BSC1_BASE
    ) );

#-------------------------------------------------------
# Memory
#-------------------------------------------------------

use constant {
    BCM2835_PAGE_SIZE  => 4*1024,
    BCM2835_BLOCK_SIZE => 4*1024,
};

_register_exported_constants( qw(
    memory
    BCM2835_PAGE_SIZE
    BCM2835_BLOCK_SIZE
    ) );

#-----------------------------------------------------
# Defines for GPIO
# The BCM2835 has 54 GPIO pins.
#      BCM2835 data sheet, Page 90 onwards.
# GPIO register offsets from BCM2835_GPIO_BASE. Offsets into the GPIO Peripheral block in bytes per 6.1 Register View
#-----------------------------------------------------

use constant {
    BCM2835_GPFSEL0    => 0x0000, # GPIO Function Select 0
    BCM2835_GPFSEL1    => 0x0004, # GPIO Function Select 1
    BCM2835_GPFSEL2    => 0x0008, # GPIO Function Select 2
    BCM2835_GPFSEL3    => 0x000c, # GPIO Function Select 3
    BCM2835_GPFSEL4    => 0x0010, # GPIO Function Select 4
    BCM2835_GPFSEL5    => 0x0014, # GPIO Function Select 5
    BCM2835_GPSET0     => 0x001c, # GPIO Pin Output Set 0
    BCM2835_GPSET1     => 0x0020, # GPIO Pin Output Set 1
    BCM2835_GPCLR0     => 0x0028, # GPIO Pin Output Clear 0
    BCM2835_GPCLR1     => 0x002c, # GPIO Pin Output Clear 1
    BCM2835_GPLEV0     => 0x0034, # GPIO Pin Level 0
    BCM2835_GPLEV1     => 0x0038, # GPIO Pin Level 1
    BCM2835_GPEDS0     => 0x0040, # GPIO Pin Event Detect Status 0
    BCM2835_GPEDS1     => 0x0044, # GPIO Pin Event Detect Status 1
    BCM2835_GPREN0     => 0x004c, # GPIO Pin Rising Edge Detect Enable 0
    BCM2835_GPREN1     => 0x0050, # GPIO Pin Rising Edge Detect Enable 1
    BCM2835_GPFEN0     => 0x0058, # GPIO Pin Falling Edge Detect Enable 0
    BCM2835_GPFEN1     => 0x005c, # GPIO Pin Falling Edge Detect Enable 1
    BCM2835_GPHEN0     => 0x0064, # GPIO Pin High Detect Enable 0
    BCM2835_GPHEN1     => 0x0068, # GPIO Pin High Detect Enable 1
    BCM2835_GPLEN0     => 0x0070, # GPIO Pin Low Detect Enable 0
    BCM2835_GPLEN1     => 0x0074, # GPIO Pin Low Detect Enable 1
    BCM2835_GPAREN0    => 0x007c, # GPIO Pin Async. Rising Edge Detect 0
    BCM2835_GPAREN1    => 0x0080, # GPIO Pin Async. Rising Edge Detect 1
    BCM2835_GPAFEN0    => 0x0088, # GPIO Pin Async. Falling Edge Detect 0
    BCM2835_GPAFEN1    => 0x008c, # GPIO Pin Async. Falling Edge Detect 1
    BCM2835_GPPUD      => 0x0094, # GPIO Pin Pull-up/down Enable
    BCM2835_GPPUDCLK0  => 0x0098, # GPIO Pin Pull-up/down Enable Clock 0
    BCM2835_GPPUDCLK1  => 0x009c, # GPIO Pin Pull-up/down Enable Clock 1
    #-------------------------------------------------------
    # Port function select modes for bcm2845_gpio_fsel()
    #-------------------------------------------------------
    BCM2835_GPIO_FSEL_INPT  => 0, # Input
    BCM2835_GPIO_FSEL_OUTP  => 1, # Output
    BCM2835_GPIO_FSEL_ALT0  => 4, # Alternate function 0
    BCM2835_GPIO_FSEL_ALT1  => 5, # Alternate function 1
    BCM2835_GPIO_FSEL_ALT2  => 6, # Alternate function 2
    BCM2835_GPIO_FSEL_ALT3  => 7, # Alternate function 3
    BCM2835_GPIO_FSEL_ALT4  => 3, # Alternate function 4
    BCM2835_GPIO_FSEL_ALT5  => 2, # Alternate function 5
    BCM2835_GPIO_FSEL_MASK  => 7  # Function select bits mask
};

_register_exported_constants( qw(
    function
    BCM2835_GPFSEL0
    BCM2835_GPFSEL1
    BCM2835_GPFSEL2
    BCM2835_GPFSEL3
    BCM2835_GPFSEL4
    BCM2835_GPFSEL5
    BCM2835_GPSET0
    BCM2835_GPSET1
    BCM2835_GPCLR0
    BCM2835_GPCLR1
    BCM2835_GPLEV0
    BCM2835_GPLEV1
    BCM2835_GPEDS0
    BCM2835_GPEDS1
    BCM2835_GPREN0
    BCM2835_GPREN1
    BCM2835_GPFEN0
    BCM2835_GPFEN1
    BCM2835_GPHEN0
    BCM2835_GPHEN1
    BCM2835_GPLEN0
    BCM2835_GPLEN1
    BCM2835_GPAREN0
    BCM2835_GPAREN1
    BCM2835_GPAFEN0
    BCM2835_GPAFEN1
    BCM2835_GPPUD
    BCM2835_GPPUDCLK0
    BCM2835_GPPUDCLK1
    
    BCM2835_GPIO_FSEL_INPT
    BCM2835_GPIO_FSEL_OUTP
    BCM2835_GPIO_FSEL_ALT0
    BCM2835_GPIO_FSEL_ALT1
    BCM2835_GPIO_FSEL_ALT2
    BCM2835_GPIO_FSEL_ALT3
    BCM2835_GPIO_FSEL_ALT4
    BCM2835_GPIO_FSEL_ALT5
    BCM2835_GPIO_FSEL_MASK
    ) );

#----------------------------------------------------------
# Pullup/Pulldown defines for bcm2845_gpio_pud()
#----------------------------------------------------------

use constant {
    BCM2835_GPIO_PUD_OFF   => 0,  # < Off ? disable pull-up/down
    BCM2835_GPIO_PUD_DOWN  => 1,  # < Enable Pull Down control
    BCM2835_GPIO_PUD_UP    => 2,   # < Enable Pull Up control
    BCM2835_GPIO_PUD_ERROR => 0x100,
};

_register_exported_constants( qw(
    pud
    BCM2835_GPIO_PUD_OFF
    BCM2835_GPIO_PUD_DOWN
    BCM2835_GPIO_PUD_UP
    BCM2835_GPIO_PUD_ERROR
    ) );

#----------------------------------------------------------
# Pad control register offsets from BCM2835_GPIO_PADS,
# control masks and groups
#----------------------------------------------------------

use constant {
    BCM2835_PADS_GPIO_0_27          => 0x002c,        #< Pad control register for pads 0 to 27
    BCM2835_PADS_GPIO_28_45         => 0x0030,        #< Pad control register for pads 28 to 45
    BCM2835_PADS_GPIO_46_53         => 0x0034,        #< Pad control register for pads 46 to 53
    BCM2835_PAD_PASSWRD             => (0x5A << 24),  #< Password to enable setting pad mask
    BCM2835_PAD_SLEW_RATE_UNLIMITED => 0x10,          #< Slew rate unlimited
    BCM2835_PAD_HYSTERESIS_ENABLED  => 0x08,          #< Hysteresis enabled
    BCM2835_PAD_DRIVE_2mA           => 0x00,          #< 2mA drive current
    BCM2835_PAD_DRIVE_4mA           => 0x01,          #< 4mA drive current
    BCM2835_PAD_DRIVE_6mA           => 0x02,          #< 6mA drive current
    BCM2835_PAD_DRIVE_8mA           => 0x03,          #< 8mA drive current
    BCM2835_PAD_DRIVE_10mA          => 0x04,          #< 10mA drive current
    BCM2835_PAD_DRIVE_12mA          => 0x05,          #< 12mA drive current
    BCM2835_PAD_DRIVE_14mA          => 0x06,          #< 14mA drive current
    BCM2835_PAD_DRIVE_16mA          => 0x07,          #< 16mA drive current
    BCM2835_PAD_GROUP_GPIO_0_27     => 0,             #< Pad group for GPIO pads 0 to 27
    BCM2835_PAD_GROUP_GPIO_28_45    => 1,             #< Pad group for GPIO pads 28 to 45
    BCM2835_PAD_GROUP_GPIO_46_53    => 2,             #< Pad group for GPIO pads 46 to 53

};

_register_exported_constants( qw(
    pads
    BCM2835_PADS_GPIO_0_27  
    BCM2835_PADS_GPIO_28_45
    BCM2835_PADS_GPIO_46_53  
    BCM2835_PAD_PASSWRD   
    BCM2835_PAD_SLEW_RATE_UNLIMITED
    BCM2835_PAD_HYSTERESIS_ENABLED 
    BCM2835_PAD_DRIVE_2mA 
    BCM2835_PAD_DRIVE_4mA 
    BCM2835_PAD_DRIVE_6mA 
    BCM2835_PAD_DRIVE_8mA 
    BCM2835_PAD_DRIVE_10mA 
    BCM2835_PAD_DRIVE_12mA 
    BCM2835_PAD_DRIVE_14mA 
    BCM2835_PAD_DRIVE_16mA 
    BCM2835_PAD_GROUP_GPIO_0_27 
    BCM2835_PAD_GROUP_GPIO_28_45 
    BCM2835_PAD_GROUP_GPIO_46_53 
    ) );

#------------------------------------------------------------------------------------------------
# Here we define Raspberry Pin GPIO pins on P1 in terms of the underlying BCM GPIO pin numbers.
# These can be passed as a pin number to any function requiring a pin.
# Not all pins on the RPi 26 bin IDE plug are connected to GPIO pins
# and some can adopt an alternate function.
# RPi version 2 has some slightly different pinouts, and these are values RPI_V2_*.
# At bootup, pins 8 and 10 are set to UART0_TXD, UART0_RXD (ie the alt0 function) respectively
# When SPI0 is in use (ie after bcm2835_spi_begin()), pins 19, 21, 23, 24, 26 are dedicated to SPI
# and cant be controlled independently
#-------------------------------------------------------------------------------------------------

use constant {
    RPI_GPIO_P1_03        =>  0,  #  Version 1, Pin P1-03
    RPI_GPIO_P1_05        =>  1,  #  Version 1, Pin P1-05
    RPI_GPIO_P1_07        =>  4,  #  Version 1, Pin P1-07
    RPI_GPIO_P1_08        => 14,  #  Version 1, Pin P1-08, defaults to alt function 0 UART0_TXD
    RPI_GPIO_P1_10        => 15,  #  Version 1, Pin P1-10, defaults to alt function 0 UART0_RXD
    RPI_GPIO_P1_11        => 17,  #  Version 1, Pin P1-11
    RPI_GPIO_P1_12        => 18,  #  Version 1, Pin P1-12
    RPI_GPIO_P1_13        => 21,  #  Version 1, Pin P1-13
    RPI_GPIO_P1_15        => 22,  #  Version 1, Pin P1-15
    RPI_GPIO_P1_16        => 23,  #  Version 1, Pin P1-16
    RPI_GPIO_P1_18        => 24,  #  Version 1, Pin P1-18
    RPI_GPIO_P1_19        => 10,  #  Version 1, Pin P1-19, MOSI when SPI0 in use
    RPI_GPIO_P1_21        =>  9,  #  Version 1, Pin P1-21, MISO when SPI0 in use
    RPI_GPIO_P1_22        => 25,  #  Version 1, Pin P1-22
    RPI_GPIO_P1_23        => 11,  #  Version 1, Pin P1-23, CLK when SPI0 in use
    RPI_GPIO_P1_24        =>  8,  #  Version 1, Pin P1-24, CE0 when SPI0 in use
    RPI_GPIO_P1_26        =>  7,  #  Version 1, Pin P1-26, CE1 when SPI0 in use

    RPI_V2_GPIO_P1_03     =>  2,  #  Version 2, Pin P1-03
    RPI_V2_GPIO_P1_05     =>  3,  #  Version 2, Pin P1-05
    RPI_V2_GPIO_P1_07     =>  4,  #  Version 2, Pin P1-07
    RPI_V2_GPIO_P1_08     => 14,  #  Version 2, Pin P1-08, defaults to alt function 0 UART0_TXD
    RPI_V2_GPIO_P1_10     => 15,  #  Version 2, Pin P1-10, defaults to alt function 0 UART0_RXD
    RPI_V2_GPIO_P1_11     => 17,  #  Version 2, Pin P1-11
    RPI_V2_GPIO_P1_12     => 18,  #  Version 2, Pin P1-12
    RPI_V2_GPIO_P1_13     => 27,  #  Version 2, Pin P1-13
    RPI_V2_GPIO_P1_15     => 22,  #  Version 2, Pin P1-15
    RPI_V2_GPIO_P1_16     => 23,  #  Version 2, Pin P1-16
    RPI_V2_GPIO_P1_18     => 24,  #  Version 2, Pin P1-18
    RPI_V2_GPIO_P1_19     => 10,  #  Version 2, Pin P1-19, MOSI when SPI0 in use
    RPI_V2_GPIO_P1_21     =>  9,  #  Version 2, Pin P1-21, MISO when SPI0 in use
    RPI_V2_GPIO_P1_22     => 25,  #  Version 2, Pin P1-22
    RPI_V2_GPIO_P1_23     => 11,  #  Version 2, Pin P1-23, CLK when SPI0 in use
    RPI_V2_GPIO_P1_24     =>  8,  #  Version 2, Pin P1-24, CE0 when SPI0 in use
    RPI_V2_GPIO_P1_26     =>  7,  #  Version 2, Pin P1-26, CE1 when SPI0 in use
    
    RPI_V2_GPIO_P5_03     => 28,  #  Version 2, Pin P5-03
    RPI_V2_GPIO_P5_04     => 29,  #  Version 2, Pin P5-04
    RPI_V2_GPIO_P5_05     => 30,  #  Version 2, Pin P5-05
    RPI_V2_GPIO_P5_06     => 31,  #  Version 2, Pin P5-06
    
    RPI_BPLUS_GPIO_J8_03     =>  2, #  /*!< B+, Pin J8-03 */
    RPI_BPLUS_GPIO_J8_05     =>  3, #  /*!< B+, Pin J8-05 */
    RPI_BPLUS_GPIO_J8_07     =>  4, #  /*!< B+, Pin J8-07 */
    RPI_BPLUS_GPIO_J8_08     => 14, #  /*!< B+, Pin J8-08, defaults to alt function 0 UART0_TXD */
    RPI_BPLUS_GPIO_J8_10     => 15, #  /*!< B+, Pin J8-10, defaults to alt function 0 UART0_RXD */
    RPI_BPLUS_GPIO_J8_11     => 17, #  /*!< B+, Pin J8-11 */
    RPI_BPLUS_GPIO_J8_12     => 18, #  /*!< B+, Pin J8-12, can be PWM channel 0 in ALT FUN 5 */
    RPI_BPLUS_GPIO_J8_13     => 27, #  /*!< B+, Pin J8-13 */
    RPI_BPLUS_GPIO_J8_15     => 22, #  /*!< B+, Pin J8-15 */
    RPI_BPLUS_GPIO_J8_16     => 23, #  /*!< B+, Pin J8-16 */
    RPI_BPLUS_GPIO_J8_18     => 24, #  /*!< B+, Pin J8-18 */
    RPI_BPLUS_GPIO_J8_19     => 10, #  /*!< B+, Pin J8-19, MOSI when SPI0 in use */
    RPI_BPLUS_GPIO_J8_21     =>  9, #  /*!< B+, Pin J8-21, MISO when SPI0 in use */
    RPI_BPLUS_GPIO_J8_22     => 25, #  /*!< B+, Pin J8-22 */
    RPI_BPLUS_GPIO_J8_23     => 11, #  /*!< B+, Pin J8-23, CLK when SPI0 in use */
    RPI_BPLUS_GPIO_J8_24     =>  8, #  /*!< B+, Pin J8-24, CE0 when SPI0 in use */
    RPI_BPLUS_GPIO_J8_26     =>  7, #  /*!< B+, Pin J8-26, CE1 when SPI0 in use */
    RPI_BPLUS_GPIO_J8_29     =>  5, #/*!< B+, Pin J8-29,  */
    RPI_BPLUS_GPIO_J8_31     =>  6, #/*!< B+, Pin J8-31,  */
    RPI_BPLUS_GPIO_J8_32     =>  12, #/*!< B+, Pin J8-32,  */
    RPI_BPLUS_GPIO_J8_33     =>  13, #/*!< B+, Pin J8-33,  */
    RPI_BPLUS_GPIO_J8_35     =>  19, #/*!< B+, Pin J8-35,  */
    RPI_BPLUS_GPIO_J8_36     =>  16, #/*!< B+, Pin J8-36,  */
    RPI_BPLUS_GPIO_J8_37     =>  26, #/*!< B+, Pin J8-37,  */
    RPI_BPLUS_GPIO_J8_38     =>  20, #/*!< B+, Pin J8-38,  */
    RPI_BPLUS_GPIO_J8_40     =>  21, #/*!< B+, Pin J8-40,  
    
};

_register_exported_constants( qw(
    pins
    RPI_GPIO_P1_03  
    RPI_GPIO_P1_05
    RPI_GPIO_P1_07
    RPI_GPIO_P1_08
    RPI_GPIO_P1_10
    RPI_GPIO_P1_11 
    RPI_GPIO_P1_12  
    RPI_GPIO_P1_13  
    RPI_GPIO_P1_15   
    RPI_GPIO_P1_16 
    RPI_GPIO_P1_18 
    RPI_GPIO_P1_19 
    RPI_GPIO_P1_21 
    RPI_GPIO_P1_22 
    RPI_GPIO_P1_23  
    RPI_GPIO_P1_24 
    RPI_GPIO_P1_26      
    RPI_V2_GPIO_P1_03  
    RPI_V2_GPIO_P1_05  
    RPI_V2_GPIO_P1_07  
    RPI_V2_GPIO_P1_08 
    RPI_V2_GPIO_P1_10
    RPI_V2_GPIO_P1_11 
    RPI_V2_GPIO_P1_12 
    RPI_V2_GPIO_P1_13 
    RPI_V2_GPIO_P1_15 
    RPI_V2_GPIO_P1_16 
    RPI_V2_GPIO_P1_18 
    RPI_V2_GPIO_P1_19 
    RPI_V2_GPIO_P1_21 
    RPI_V2_GPIO_P1_22 
    RPI_V2_GPIO_P1_23 
    RPI_V2_GPIO_P1_24 
    RPI_V2_GPIO_P1_26
    
    RPI_V2_GPIO_P5_03
    RPI_V2_GPIO_P5_04
    RPI_V2_GPIO_P5_05
    RPI_V2_GPIO_P5_06
    
    RPI_BPLUS_GPIO_J8_03
    RPI_BPLUS_GPIO_J8_05
    RPI_BPLUS_GPIO_J8_07
    RPI_BPLUS_GPIO_J8_08
    RPI_BPLUS_GPIO_J8_10
    RPI_BPLUS_GPIO_J8_11
    RPI_BPLUS_GPIO_J8_12
    RPI_BPLUS_GPIO_J8_13
    RPI_BPLUS_GPIO_J8_15
    RPI_BPLUS_GPIO_J8_16
    RPI_BPLUS_GPIO_J8_18
    RPI_BPLUS_GPIO_J8_19
    RPI_BPLUS_GPIO_J8_21
    RPI_BPLUS_GPIO_J8_22
    RPI_BPLUS_GPIO_J8_23
    RPI_BPLUS_GPIO_J8_24
    RPI_BPLUS_GPIO_J8_26
    RPI_BPLUS_GPIO_J8_29
    RPI_BPLUS_GPIO_J8_31
    RPI_BPLUS_GPIO_J8_32
    RPI_BPLUS_GPIO_J8_33
    RPI_BPLUS_GPIO_J8_35
    RPI_BPLUS_GPIO_J8_36
    RPI_BPLUS_GPIO_J8_37
    RPI_BPLUS_GPIO_J8_38
    RPI_BPLUS_GPIO_J8_40
    
    ) );


#---------------------------------------------------------------------------
# Defines for SPI
#---------------------------------------------------------------------------

use constant {
    # GPIO register offsets from BCM2835_SPI0_BASE. 
    # Offsets into the SPI Peripheral block in bytes per 10.5 SPI Register Map
    BCM2835_SPI0_CS                 => 0x0000, #  SPI Master Control and Status
    BCM2835_SPI0_FIFO               => 0x0004, #  SPI Master TX and RX FIFOs
    BCM2835_SPI0_CLK                => 0x0008, #  SPI Master Clock Divider
    BCM2835_SPI0_DLEN               => 0x000c, #  SPI Master Data Length
    BCM2835_SPI0_LTOH               => 0x0010, #  SPI LOSSI mode TOH
    BCM2835_SPI0_DC                 => 0x0014, #  SPI DMA DREQ Controls

    # Register masks for SPI0_CS
    BCM2835_SPI0_CS_LEN_LONG        => 0x02000000, #  Enable Long data word in Lossi mode if DMA_LEN is set
    BCM2835_SPI0_CS_DMA_LEN         => 0x01000000, #  Enable DMA mode in Lossi mode
    BCM2835_SPI0_CS_CSPOL2          => 0x00800000, #  Chip Select 2 Polarity
    BCM2835_SPI0_CS_CSPOL1          => 0x00400000, #  Chip Select 1 Polarity
    BCM2835_SPI0_CS_CSPOL0          => 0x00200000, #  Chip Select 0 Polarity
    BCM2835_SPI0_CS_RXF             => 0x00100000, #  RXF - RX FIFO Full
    BCM2835_SPI0_CS_RXR             => 0x00080000, #  RXR RX FIFO needs Reading ( full)
    BCM2835_SPI0_CS_TXD             => 0x00040000, #  TXD TX FIFO can accept Data
    BCM2835_SPI0_CS_RXD             => 0x00020000, #  RXD RX FIFO contains Data
    BCM2835_SPI0_CS_DONE            => 0x00010000, #  Done transfer Done
    BCM2835_SPI0_CS_TE_EN           => 0x00008000, #  Unused
    BCM2835_SPI0_CS_LMONO           => 0x00004000, #  Unused
    BCM2835_SPI0_CS_LEN             => 0x00002000, #  LEN LoSSI enable
    BCM2835_SPI0_CS_REN             => 0x00001000, #  REN Read Enable
    BCM2835_SPI0_CS_ADCS            => 0x00000800, #  ADCS Automatically Deassert Chip Select
    BCM2835_SPI0_CS_INTR            => 0x00000400, #  INTR Interrupt on RXR
    BCM2835_SPI0_CS_INTD            => 0x00000200, #  INTD Interrupt on Done
    BCM2835_SPI0_CS_DMAEN           => 0x00000100, #  DMAEN DMA Enable
    BCM2835_SPI0_CS_TA              => 0x00000080, #  Transfer Active
    BCM2835_SPI0_CS_CSPOL           => 0x00000040, #  Chip Select Polarity
    BCM2835_SPI0_CS_CLEAR           => 0x00000030, #  Clear FIFO Clear RX and TX
    BCM2835_SPI0_CS_CLEAR_RX        => 0x00000020, #  Clear FIFO Clear RX 
    BCM2835_SPI0_CS_CLEAR_TX        => 0x00000010, #  Clear FIFO Clear TX 
    BCM2835_SPI0_CS_CPOL            => 0x00000008, #  Clock Polarity
    BCM2835_SPI0_CS_CPHA            => 0x00000004, #  Clock Phase
    BCM2835_SPI0_CS_CS              => 0x00000003, #  Chip Select

    # Specifies the SPI data bit ordering
    BCM2835_SPI_BIT_ORDER_LSBFIRST  => 0,  #  LSB First
    BCM2835_SPI_BIT_ORDER_MSBFIRST  => 1,   #  MSB First
    
    # Specify the SPI data mode
    BCM2835_SPI_MODE0 => 0,  #  CPOL = 0, CPHA = 0
    BCM2835_SPI_MODE1 => 1,  #  CPOL = 0, CPHA = 1
    BCM2835_SPI_MODE2 => 2,  #  CPOL = 1, CPHA = 0
    BCM2835_SPI_MODE3 => 3,  #  CPOL = 1, CPHA = 1
    
    # Specify the SPI chip select pin(s)
    BCM2835_SPI_CS0     => 0, #  Chip Select 0
    BCM2835_SPI_CS1     => 1, #  Chip Select 1
    BCM2835_SPI_CS2     => 2, #  Chip Select 2 (ie pins CS1 and CS2 are asserted)
    BCM2835_SPI_CS_NONE => 3, #  No CS, control it yourself
    
    # Specifies the divider used to generate the SPI clock from the system clock.
    # Figures below give the divider, clock period and clock frequency.
    BCM2835_SPI_CLOCK_DIVIDER_65536 => 0,       #  65536 = 256us = 4kHz
    BCM2835_SPI_CLOCK_DIVIDER_32768 => 32768,   #  32768 = 126us = 8kHz
    BCM2835_SPI_CLOCK_DIVIDER_16384 => 16384,   #  16384 = 64us = 15.625kHz
    BCM2835_SPI_CLOCK_DIVIDER_8192  => 8192,    #  8192 = 32us = 31.25kHz
    BCM2835_SPI_CLOCK_DIVIDER_4096  => 4096,    #  4096 = 16us = 62.5kHz
    BCM2835_SPI_CLOCK_DIVIDER_2048  => 2048,    #  2048 = 8us = 125kHz
    BCM2835_SPI_CLOCK_DIVIDER_1024  => 1024,    #  1024 = 4us = 250kHz
    BCM2835_SPI_CLOCK_DIVIDER_512   => 512,     #  512 = 2us = 500kHz
    BCM2835_SPI_CLOCK_DIVIDER_256   => 256,     #  256 = 1us = 1MHz
    BCM2835_SPI_CLOCK_DIVIDER_128   => 128,     #  128 = 500ns = = 2MHz
    BCM2835_SPI_CLOCK_DIVIDER_64    => 64,      #  64 = 250ns = 4MHz
    BCM2835_SPI_CLOCK_DIVIDER_32    => 32,      #  32 = 125ns = 8MHz
    BCM2835_SPI_CLOCK_DIVIDER_16    => 16,      #  16 = 50ns = 20MHz
    BCM2835_SPI_CLOCK_DIVIDER_8     => 8,       #  8 = 25ns = 40MHz
    BCM2835_SPI_CLOCK_DIVIDER_4     => 4,       #  4 = 12.5ns 80MHz
    BCM2835_SPI_CLOCK_DIVIDER_2     => 2,       #  2 = 6.25ns = 160MHz
    BCM2835_SPI_CLOCK_DIVIDER_1     => 1,       #  0 = 256us = 4kHz
    
};

_register_exported_constants( qw(
    spi
    BCM2835_SPI0_CS  
    BCM2835_SPI0_FIFO
    BCM2835_SPI0_CLK 
    BCM2835_SPI0_DLEN  
    BCM2835_SPI0_LTOH  
    BCM2835_SPI0_DC  
    BCM2835_SPI0_CS_LEN_LONG
    BCM2835_SPI0_CS_DMA_LEN
    BCM2835_SPI0_CS_CSPOL2 
    BCM2835_SPI0_CS_CSPOL1
    BCM2835_SPI0_CS_CSPOL0 
    BCM2835_SPI0_CS_RXF  
    BCM2835_SPI0_CS_RXR
    BCM2835_SPI0_CS_TXD 
    BCM2835_SPI0_CS_RXD 
    BCM2835_SPI0_CS_DONE 
    BCM2835_SPI0_CS_TE_EN 
    BCM2835_SPI0_CS_LMONO 
    BCM2835_SPI0_CS_LEN
    BCM2835_SPI0_CS_REN 
    BCM2835_SPI0_CS_ADCS 
    BCM2835_SPI0_CS_INTR 
    BCM2835_SPI0_CS_INTD
    BCM2835_SPI0_CS_DMAEN 
    BCM2835_SPI0_CS_TA 
    BCM2835_SPI0_CS_CSPOL 
    BCM2835_SPI0_CS_CLEAR 
    BCM2835_SPI0_CS_CLEAR_RX 
    BCM2835_SPI0_CS_CLEAR_TX
    BCM2835_SPI0_CS_CPOL 
    BCM2835_SPI0_CS_CPHA 
    BCM2835_SPI0_CS_CS 
    BCM2835_SPI_BIT_ORDER_LSBFIRST
    BCM2835_SPI_BIT_ORDER_MSBFIRST
    BCM2835_SPI_MODE0 
    BCM2835_SPI_MODE1
    BCM2835_SPI_MODE2
    BCM2835_SPI_MODE3 
    BCM2835_SPI_CS0 
    BCM2835_SPI_CS1 
    BCM2835_SPI_CS2 
    BCM2835_SPI_CS_NONE 
    BCM2835_SPI_CLOCK_DIVIDER_65536
    BCM2835_SPI_CLOCK_DIVIDER_32768 
    BCM2835_SPI_CLOCK_DIVIDER_16384
    BCM2835_SPI_CLOCK_DIVIDER_8192
    BCM2835_SPI_CLOCK_DIVIDER_4096 
    BCM2835_SPI_CLOCK_DIVIDER_2048 
    BCM2835_SPI_CLOCK_DIVIDER_1024
    BCM2835_SPI_CLOCK_DIVIDER_512 
    BCM2835_SPI_CLOCK_DIVIDER_256
    BCM2835_SPI_CLOCK_DIVIDER_128 
    BCM2835_SPI_CLOCK_DIVIDER_64
    BCM2835_SPI_CLOCK_DIVIDER_32 
    BCM2835_SPI_CLOCK_DIVIDER_16
    BCM2835_SPI_CLOCK_DIVIDER_8
    BCM2835_SPI_CLOCK_DIVIDER_4
    BCM2835_SPI_CLOCK_DIVIDER_2
    BCM2835_SPI_CLOCK_DIVIDER_1
    ) );

#------------------------------------------------------------
# Defines for PWM
#------------------------------------------------------------

use constant {
    BCM2835_PWM_CONTROL     => 0,
    BCM2835_PWM_STATUS      => 1,
    BCM2835_PWM_DMAC        => 2,
    BCM2835_PWM0_RANGE      => 4,
    BCM2835_PWM0_DATA       => 5,
    BCM2835_PWM_FIF1        => 6,
    BCM2835_PWM1_RANGE      => 8,
    BCM2835_PWM1_DATA       => 9,

    BCM2835_PWMCLK_CNTL     => 40,
    BCM2835_PWMCLK_DIV      => 41,
    BCM2835_PWM_PASSWRD     => (0x5A << 24),
    
    BCM2835_PWM1_MS_MODE   => 0x8000, # Run in MS mode
    BCM2835_PWM1_USEFIFO   => 0x2000, # Data from FIFO
    BCM2835_PWM1_REVPOLAR  => 0x1000, # Reverse polarity
    BCM2835_PWM1_OFFSTATE  => 0x0800, # Ouput Off state
    BCM2835_PWM1_REPEATFF  => 0x0400, # Repeat last value if FIFO empty
    BCM2835_PWM1_SERIAL    => 0x0200, # Run in serial mode
    BCM2835_PWM1_ENABLE    => 0x0100, # Channel Enable

    BCM2835_PWM0_MS_MODE   => 0x0080, # Run in MS mode
    BCM2835_PWM0_USEFIFO   => 0x0020, # Data from FIFO
    BCM2835_PWM0_REVPOLAR  => 0x0010, # Reverse polarity
    BCM2835_PWM0_OFFSTATE  => 0x0008, # Ouput Off state
    BCM2835_PWM0_REPEATFF  => 0x0004, # Repeat last value if FIFO empty
    BCM2835_PWM0_SERIAL    => 0x0002, # Run in serial mode
    BCM2835_PWM0_ENABLE    => 0x0001, # Channel Enable
    
    BCM2835_PWM_CLOCK_DIVIDER_2048  => 2048, #   /*!< 2048 = 9.375kHz */
    BCM2835_PWM_CLOCK_DIVIDER_1024  => 1024, #     /*!< 1024 = 18.75kHz */
    BCM2835_PWM_CLOCK_DIVIDER_512   => 512, #      /*!< 512 = 37.5kHz */
    BCM2835_PWM_CLOCK_DIVIDER_256   => 256, #      /*!< 256 = 75kHz */
    BCM2835_PWM_CLOCK_DIVIDER_128   => 128, #      /*!< 128 = 150kHz */
    BCM2835_PWM_CLOCK_DIVIDER_64    => 64, #       /*!< 64 = 300kHz */
    BCM2835_PWM_CLOCK_DIVIDER_32    => 32, #       /*!< 32 = 600.0kHz */
    BCM2835_PWM_CLOCK_DIVIDER_16    => 16, #       /*!< 16 = 1.2MHz */
    BCM2835_PWM_CLOCK_DIVIDER_8     => 8, #        /*!< 8 = 2.4MHz */
    BCM2835_PWM_CLOCK_DIVIDER_4     => 4, #        /*!< 4 = 4.8MHz */
    BCM2835_PWM_CLOCK_DIVIDER_2     => 2, #        /*!< 2 = 9.6MHz, fastest you can get */
    BCM2835_PWM_CLOCK_DIVIDER_1     => 1, #        /*!< 1 = 4.6875kHz, same as divider 4096 */
    
};

_register_exported_constants( qw(
    pwm
    BCM2835_PWM_CONTROL
    BCM2835_PWM_STATUS
    BCM2835_PWM_DMAC
    BCM2835_PWM0_RANGE 
    BCM2835_PWM0_DATA
    BCM2835_PWM_FIF1
    BCM2835_PWM1_RANGE 
    BCM2835_PWM1_DATA 
    BCM2835_PWMCLK_CNTL
    BCM2835_PWMCLK_DIV
    BCM2835_PWM_PASSWRD
    BCM2835_PWM1_MS_MODE
    BCM2835_PWM1_USEFIFO
    BCM2835_PWM1_REVPOLAR
    BCM2835_PWM1_OFFSTATE
    BCM2835_PWM1_REPEATFF
    BCM2835_PWM1_SERIAL
    BCM2835_PWM1_ENABLE
    BCM2835_PWM0_MS_MODE
    BCM2835_PWM0_USEFIFO
    BCM2835_PWM0_REVPOLAR
    BCM2835_PWM0_OFFSTATE
    BCM2835_PWM0_REPEATFF
    BCM2835_PWM0_SERIAL
    BCM2835_PWM0_ENABLE
    
    BCM2835_PWM_CLOCK_DIVIDER_2048 
    BCM2835_PWM_CLOCK_DIVIDER_1024  
    BCM2835_PWM_CLOCK_DIVIDER_512  
    BCM2835_PWM_CLOCK_DIVIDER_256 
    BCM2835_PWM_CLOCK_DIVIDER_128  
    BCM2835_PWM_CLOCK_DIVIDER_64  
    BCM2835_PWM_CLOCK_DIVIDER_32  
    BCM2835_PWM_CLOCK_DIVIDER_16  
    BCM2835_PWM_CLOCK_DIVIDER_8  
    BCM2835_PWM_CLOCK_DIVIDER_4  
    BCM2835_PWM_CLOCK_DIVIDER_2 
    BCM2835_PWM_CLOCK_DIVIDER_1 
    
    ) );

#-------------------------------------------------------------
# Defines for I2C
#-------------------------------------------------------------

use constant {
    BCM2835_BSC_C                    => 0x0000,      # BSC Master Control
    BCM2835_BSC_S 		     => 0x0004,      # BSC Master Status
    BCM2835_BSC_DLEN		     => 0x0008,      # BSC Master Data Length
    BCM2835_BSC_A 		     => 0x000c,      # BSC Master Slave Address
    BCM2835_BSC_FIFO		     => 0x0010,      # BSC Master Data FIFO
    BCM2835_BSC_DIV		     => 0x0014,      # BSC Master Clock Divider
    BCM2835_BSC_DEL		     => 0x0018,      # BSC Master Data Delay
    BCM2835_BSC_CLKT		     => 0x001c,      # BSC Master Clock Stretch Timeout
    BCM2835_BSC_C_I2CEN 	     => 0x00008000,  # I2C Enable, 0 = disabled, 1 = enabled
    BCM2835_BSC_C_INTR 		     => 0x00000400,  # Interrupt on RX
    BCM2835_BSC_C_INTT 		     => 0x00000200,  # Interrupt on TX
    BCM2835_BSC_C_INTD 		     => 0x00000100,  # Interrupt on DONE
    BCM2835_BSC_C_ST 		     => 0x00000080,  # Start transfer, 1 = Start a new transfer
    BCM2835_BSC_C_CLEAR_1 	     => 0x00000020,  # Clear FIFO Clear
    BCM2835_BSC_C_CLEAR_2 	     => 0x00000010,  # Clear FIFO Clear
    BCM2835_BSC_C_READ 		     => 0x00000001,  #	Read transfer
    BCM2835_BSC_S_CLKT 		     => 0x00000200,  # Clock stretch timeout
    BCM2835_BSC_S_ERR 		     => 0x00000100,  # ACK error
    BCM2835_BSC_S_RXF 		     => 0x00000080,  # RXF FIFO full, 0 = FIFO is not full, 1 = FIFO is full
    BCM2835_BSC_S_TXE 		     => 0x00000040,  # TXE FIFO full, 0 = FIFO is not full, 1 = FIFO is full
    BCM2835_BSC_S_RXD 		     => 0x00000020,  # RXD FIFO contains data
    BCM2835_BSC_S_TXD 		     => 0x00000010,  # TXD FIFO can accept data
    BCM2835_BSC_S_RXR 		     => 0x00000008,  # RXR FIFO needs reading (full)
    BCM2835_BSC_S_TXW 		     => 0x00000004,  # TXW FIFO needs writing (full)
    BCM2835_BSC_S_DONE 		     => 0x00000002,  # Transfer DONE
    BCM2835_BSC_S_TA 		     => 0x00000001,  # Transfer Active
    BCM2835_BSC_FIFO_SIZE   	     =>	16,          # BSC FIFO size
    
    BCM2835_I2C_CLOCK_DIVIDER_2500   => 2500,      # 2500 = 10us = 100 kHz
    BCM2835_I2C_CLOCK_DIVIDER_626    => 626,       # 622 = 2.504us = 399.3610 kHz
    BCM2835_I2C_CLOCK_DIVIDER_150    => 150,       # 150 = 60ns = 1.666 MHz (default at reset)
    BCM2835_I2C_CLOCK_DIVIDER_148    => 148,       # 148 = 59ns = 1.689 MHz
    BCM2835_I2C_REASON_OK   	     => 0x00,      # Success
    BCM2835_I2C_REASON_ERROR_NACK    => 0x01,      # Received a NACK
    BCM2835_I2C_REASON_ERROR_CLKT    => 0x02,      # Received Clock Stretch Timeout
    BCM2835_I2C_REASON_ERROR_DATA    => 0x04,      # Not all data is sent / received
};

_register_exported_constants( qw(
    i2c
    BCM2835_BSC_C 
    BCM2835_BSC_S 
    BCM2835_BSC_DLEN
    BCM2835_BSC_A 
    BCM2835_BSC_FIFO
    BCM2835_BSC_DIV
    BCM2835_BSC_DEL
    BCM2835_BSC_CLKT
    BCM2835_BSC_C_I2CEN 
    BCM2835_BSC_C_INTR 
    BCM2835_BSC_C_INTT 
    BCM2835_BSC_C_INTD 
    BCM2835_BSC_C_ST 
    BCM2835_BSC_C_CLEAR_1
    BCM2835_BSC_C_CLEAR_2
    BCM2835_BSC_C_READ 
    BCM2835_BSC_S_CLKT
    BCM2835_BSC_S_ERR 
    BCM2835_BSC_S_RXF 
    BCM2835_BSC_S_TXE 
    BCM2835_BSC_S_RXD 
    BCM2835_BSC_S_TXD 
    BCM2835_BSC_S_RXR 
    BCM2835_BSC_S_TXW 
    BCM2835_BSC_S_DONE 
    BCM2835_BSC_S_TA 
    BCM2835_BSC_FIFO_SIZE
    BCM2835_I2C_CLOCK_DIVIDER_2500
    BCM2835_I2C_CLOCK_DIVIDER_626
    BCM2835_I2C_CLOCK_DIVIDER_150
    BCM2835_I2C_CLOCK_DIVIDER_148
    BCM2835_I2C_REASON_OK
    BCM2835_I2C_REASON_ERROR_NACK
    BCM2835_I2C_REASON_ERROR_CLKT
    BCM2835_I2C_REASON_ERROR_DATA
    ) );

#-----------------------------------------
# create OO method wrappers
#-----------------------------------------

{
    for my $method( qw(
        gpio_fget
        gpio_get_eds
        get_pin
        gpio_fget_name
        set_SPI0
        set_I2C0
        set_I2C1
        set_UART0
        set_UART1
        set_CTS0
        set_CTS1
        set_PWM0
        spi_transfern
        spi_transfernb
        spi_writenb
    ) ) {
        no strict 'refs';
        my $subkey  = __PACKAGE__  . qq(::$method);
        my $funckey = qq(hipi_$method);
        *{$subkey} = sub { shift; &$funckey( @_ ); };
    }
    
    for my $method( qw(
        peri_read
        peri_read_nb
        peri_write
        peri_write_nb
        peri_set_bits
        gpio_fsel
        gpio_set
        gpio_clr
        gpio_set_multi
        gpio_clr_multi
        gpio_lev
        gpio_eds
        gpio_set_eds
        gpio_eds_multi
        gpio_set_eds_multi
        gpio_ren
        gpio_clr_ren
        gpio_fen
        gpio_clr_fen
        gpio_hen
        gpio_clr_hen
        gpio_len
        gpio_clr_len
        gpio_aren
        gpio_clr_aren
        gpio_afen
        gpio_clr_afen
        gpio_pud
        gpio_pudclk
        gpio_pad
        gpio_set_pad
        delay
        delayMicroseconds
        gpio_write
        gpio_write_multi
        gpio_write_mask
        gpio_set_pud
        gpio_get_pud
        spi_begin
        spi_end
        spi_setBitOrder
        spi_setClockDivider
        spi_setDataMode
        spi_chipSelect
        spi_setChipSelectPolarity
        spi_transfer
        st_read
        st_delay
        
        peripherals
        gpio
        pwm
        clk
        pads
        spi0
        bsc0
        bsc1
        st
        peripherals_base
        uses_dmb
        
    ) ) {
        no strict 'refs';
        my $subkey  = __PACKAGE__  . qq(::$method);
        my $funckey = qq(bcm2835_$method);
        *{$subkey} = sub { shift; &$funckey( @_ ); };
    }
}

sub i2c_read {
    my($self, $numbytes) = @_;
    $numbytes ||= 1;
    my $buffer = chr(0) x $numbytes;
    bcm2835_i2c_read( $buffer, $numbytes );
    return $buffer;
}

our @_altnames = (
    
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


sub hipi_get_pin {
    HiPi::BCM2835::Pin->_open( pinid => $_[0] );
}

sub hipi_gpio_fget_name {
    my($pinid) = @_;
    return 'UNKNOWN' if $pinid < 0 || $pinid > 31;
    
    my $checkval = hipi_gpio_fget( $pinid );
    
    if ( $checkval == BCM2835_GPIO_FSEL_INPT()) {
        return 'INPUT';
    } elsif ( $checkval == BCM2835_GPIO_FSEL_OUTP()) {
        return 'OUTPUT';
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT0()) {
        return $_altnames[$pinid]->[0];
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT1()) {
        return $_altnames[$pinid]->[1];
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT2()) {
        return $_altnames[$pinid]->[2];
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT3()) {
        return $_altnames[$pinid]->[3];
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT4()) {
        return $_altnames[$pinid]->[4];
    } elsif ( $checkval == BCM2835_GPIO_FSEL_ALT5()) {
        return $_altnames[$pinid]->[5];
    }
}

sub new {
    my($class, %params) = @_;
    $params{devicename} = '/dev/mem';
    my $self = $class->SUPER::new(%params);
    bcm2835_init();
    return $self;
}

sub hipi_set_SPI0 {
    if($_[0]) {
        bcm2835_spi_begin();
    } else {
        bcm2835_spi_end();
    }
}

sub hipi_set_I2C0 {
    my($on) = @_;
    
    my $retval = 0;
    
    my @pins = ( I2C1_SDA,  I2C1_SCL );
    
    if( $on ) {
        if(RPI_BOARD_REVISION > 1) {
            # we must disable the S5 pin 0 & 1 ALT0 function
            for my $gpio (  0, 1 ) {
                my $currentmode = hipi_gpio_fget($gpio);
                if( $currentmode != BCM2835_GPIO_FSEL_INPT()) {
                    bcm2835_gpio_fsel($gpio, BCM2835_GPIO_FSEL_INPT());
                }
            }
        }
        
        $retval = bcm2835_hipi_i2c_begin( RPI_BOARD_REVISION );
        
    } else {
        
        if( RPI_BOARD_REVISION > 1) {
            # we must enable the S5 pin 0 & 1 ALT0 function
            for my $gpio (  0, 1 ) {
                my $currentmode = hipi_gpio_fget($gpio);
                if( $currentmode != BCM2835_GPIO_FSEL_ALT0()) {
                    bcm2835_gpio_fsel($gpio, BCM2835_GPIO_FSEL_ALT0());
                }
            }
        }
        
        $retval = bcm2835_hipi_i2c_end( RPI_BOARD_REVISION );
    }
    
    return $retval;
}

sub hipi_set_I2C1 {
    my($on) = @_;
    
    my $retval = 0;
    
    return $retval if RPI_BOARD_REVISION == 1;

    if( $on ) {
        $retval = bcm2835_hipi_i2c_begin( RPI_BOARD_REVISION );
    } else {
        $retval = bcm2835_hipi_i2c_end( RPI_BOARD_REVISION );
    }
    
    return $retval;
}

sub hipi_set_UART0 {
    my($on) = @_;
    my @pins = ( RPI_V2_GPIO_P1_08(),  RPI_V2_GPIO_P1_10() );
    
    if( $on ) {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_ALT0());
        }
    } else {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_INPT());
        }
    }
}

sub hipi_set_CTS0 {
    my($on) = @_;
    
    my @pins = ( RPI_V2_GPIO_P5_05(),  RPI_V2_GPIO_P5_06() );
    
    if( $on ) {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_ALT3());
        }
    } else {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_INPT());
        }
    }
}

sub hipi_set_UART1 {
    my($on) = @_;
    my @pins = ( RPI_V2_GPIO_P1_08(),  RPI_V2_GPIO_P1_10() );
    
    if( $on ) {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_ALT5());
        }
    } else {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_INPT());
        }
    }
}

sub hipi_set_CTS1 {
    my($on) = @_;
    
    my @pins = ( RPI_V2_GPIO_P5_05(),  RPI_V2_GPIO_P5_06() );
    
    if( $on ) {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_ALT5());
        }
    } else {
        for my $pin ( @pins ) {
            bcm2835_gpio_fsel($pin, BCM2835_GPIO_FSEL_INPT());
        }
    }
}

sub hipi_set_PWM0 {
    my($on) = @_;
        
    if( $on ) {
        bcm2835_gpio_fsel(RPI_V2_GPIO_P1_12(), BCM2835_GPIO_FSEL_ALT5());
    } else {
        bcm2835_gpio_fsel(RPI_V2_GPIO_P1_12(), BCM2835_GPIO_FSEL_INPT());
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

HiPi::BCM2835 - Modules for Raspberry Pi GPIO

=head1 DESCRIPTION

This is a deprecated module providing access to the bcm2835 library for HiPi Perl modules.

Documentation and details are available at

http://raspberry.znix.com

=head1 AUTHOR

Mark Dootson, C<< mdootson@cpan.org >>.

=head1 COPYRIGHT

Copyright (c) 2013 - 2017 Mark Dootson

=cut

__END__
