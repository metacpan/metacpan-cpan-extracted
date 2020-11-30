#!/usr/bin/perl

use strict;
use warnings;
use HiPi qw( :seesaw );

# call with seesaw hex address
# e.g. seesaw/pwm.pl 0x49

my $pwmpin     = SEESAW_PA05;
my $frequency  = 50;
my $pulsewidths = [ 1000, 1500, 2000 ];

package HiPi::Example::Seesaw;
use HiPi qw( :seesaw );
use parent qw( HiPi::Interface::Seesaw );

__PACKAGE__->create_accessors( qw( exit_processed pwmpin pwmfreq pulsewidths ) );

sub new {
    my ( $class, %params ) = @_;
    my $self = $class->SUPER::new( %params );
    HiPi->register_exit_method( $self, 'exit');
    return $self;
}

sub exit {
    my $self = shift;
    return if $self->exit_processed;
    print qq(\nExecution ending : cleaning up\n);
    $self->software_reset;
    $self->exit_processed(1);
    return;
}

sub process {
    my $self = shift;
    my $width = $self->pulsewidths->[0];
    printf(qq(Setting pin %s with frequency %s and pulse width %s us\n),
           $self->pwmpin, $self->pwmfreq, $width );
    
    my $realfreq  = $self->pwm_set_frequency($self->pwmpin, $self->pwmfreq );
    my $dutycycle = $self->pwm_set_pulse_width($self->pwmpin, $width );
    
    print qq(Real frequency produced by selected divider is $realfreq\n);
    print qq(Duty cycle calculated from pulse width $width is $dutycycle / 65535\n);
    
    print qq(\nPress CTRL + C to exit\n\n);
    
    STDOUT->autoflush(1); # so print '.' is flushed;
    
    while ( 1 ) {
        for ( my $i = scalar ( @{ $self->pulsewidths }) -1; $i >= 0; $i -- ) {
            sleep 5;
            $width = $self->pulsewidths->[$i];
            print qq(Setting pulse width to $width us\n);
            $dutycycle = $self->pwm_set_pulse_width($self->pwmpin, $width );
            print qq(Duty cycle is $dutycycle\n);
            print qq(Press CTRL + C to exit\n\n);
        }
    }
}

package main;

my $seesawaddress = ( $ARGV[0] ) ?  hex($ARGV[0]) : 0x49;

my $dev = HiPi::Example::Seesaw->new(
    
    address     => $seesawaddress,
    reset       => 1,
    pwmpin      => $pwmpin,
    pwmfreq     => $frequency,
    pulsewidths => $pulsewidths,
    
);

$dev->process;

1;

__END__
