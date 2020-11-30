#!/usr/bin/perl

use strict;
use warnings;
use HiPi qw( :rpi :seesaw );

# call with seesaw hex address
# e.g. seesaw/interrupt.pl 0x49

my $pi_int_pin    = RPI_PIN_40;    # input pin on pi connected to seesaw irq pin 8
my $pi_out_pin    = RPI_PIN_38;    # output pin on pi connected to seesaw input pin 11
my $seesaw_in_pin = SEESAW_PA011;  # seesaw input pin - high / low will trigger interrupts

package HiPi::Example::Seesaw;
use HiPi qw( :seesaw :rpi );
use parent qw( HiPi::Interface::Seesaw );
use HiPi::GPIO;

__PACKAGE__->create_accessors( qw( exit_processed pi_int_pin pi_out_pin seesaw_in_pin rasp ) );

sub new {
    my ( $class, %params ) = @_;
    $params{rasp} = HiPi::GPIO->new;
    my $self = $class->SUPER::new( %params );
    HiPi->register_exit_method( $self, 'exit');
    return $self;
}

sub exit {
    my $self = shift;
    return if $self->exit_processed;
    print qq(\nExecution ending : cleaning up\n);
    $self->rasp->set_pin_mode(  $self->pi_int_pin, RPI_MODE_INPUT );
    $self->rasp->set_pin_pud(   $self->pi_int_pin, RPI_PUD_OFF );
    $self->rasp->set_pin_mode(  $self->pi_out_pin, RPI_MODE_INPUT );
    $self->software_reset;
    $self->exit_processed(1);
    return;
}

sub process {
    my $self = shift;
    
    print qq(Press CTRL + C to end\n);
       
    my $ppint = $self->pi_int_pin;
    my $ppout = $self->pi_out_pin;
    my $sppin = $self->seesaw_in_pin;
    
    # setup Raspberry Pins;
    $self->rasp->set_pin_mode(  $ppint, RPI_MODE_INPUT );
    $self->rasp->set_pin_pud(   $ppint, RPI_PUD_UP );
    $self->rasp->set_pin_mode(  $ppout, RPI_MODE_OUTPUT );
    $self->rasp->set_pin_level( $ppout, 0 );
    
    # setup Seesaw Pins
    $self->gpio_set_pin_mode(  $sppin, SEESAW_INPUT_PULLUP );
    $self->gpio_enable_interrupt( $sppin );
    $self->gpio_get_interrupt_flags( $sppin ); # clears interrupt state for all pins
    
    # let everything settle
    $self->sleep_microseconds( 1000 );
    
    my $counter = 0;
    while ( $counter > -1 ) {
        $counter ++;
        
        my $toggle = $counter % 2;
        
        # set our value
        $self->rasp->set_pin_level( $ppout, $toggle );
        
        # poll int pin and wait till interrupt set
        my $interrupt_confirmed = $self->poll_int_pin;
        
        unless( $interrupt_confirmed ) {
            # this would mean something went badly wrong
            # so exit everything
            warn qq(Interrupt flag for $sppin does not show as set in iteration $counter);
            return;
        }
                
        # wait for interrupt to be cleared
        # this happens after the IRQ pin on seesaw is
        # no longer pulled low
        
        while ( $interrupt_confirmed ) {
            ( $interrupt_confirmed ) = $self->gpio_get_interrupt_flags( $sppin );
            $self->sleep_microseconds( 500 );
        }
        
        unless( $counter % 100 ) {
            print qq($counter iterations completed successfully\n);
            print qq(Press CTRL + C to end\n);
        }   
    }
}

sub poll_int_pin {
    
    # poll the interrupt pin until it is pulled low by interrupt
    
    my $self = shift;
    my $intpin = $self->pi_int_pin;
    my $sppin = $self->seesaw_in_pin; 
    my $level = 1;
    
    while ( $level ) {
        $self->sleep_microseconds( 500 );
        $level = $self->rasp->get_pin_level( $intpin );
    }
    
    # this will clear ALL interrupt flags
    my ( $intvalue ) = $self->gpio_get_interrupt_flags( $sppin ); 
    return $intvalue;
}

package main;

my $seesawaddress = ( $ARGV[0] ) ?  hex($ARGV[0]) : 0x49;

my $dev = HiPi::Example::Seesaw->new(
    
    address       => $seesawaddress,
    reset         => 1,
    pi_int_pin    => $pi_int_pin,
    pi_out_pin    => $pi_out_pin,
    seesaw_in_pin => $seesaw_in_pin,
    
);

$dev->process;

1;

__END__
