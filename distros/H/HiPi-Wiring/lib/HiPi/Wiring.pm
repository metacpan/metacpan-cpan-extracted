#########################################################################################
# Package       HiPi::Wiring
# Description:  Wrapper for wiringPi C library
# Copyright:    Copyright (c) 2012 - 2016 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wiring;

#########################################################################################

use strict;
use warnings;
use Exporter;
use base qw( Exporter );
use XSLoader;
use HiPi qw( :rpi );

our $VERSION ='0.61';

XSLoader::load('HiPi::Wiring', $VERSION) if HiPi::is_raspberry_pi();

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    WPI_NUM_PINS	=> 17,
    
    WPI_MODE_PINS	=>  0,
    WPI_MODE_GPIO       =>  1,
    WPI_MODE_GPIO_SYS   =>  2,
    WPI_MODE_PIFACE     =>  3,

    WPI_INPUT           =>  0,
    WPI_OUTPUT          =>  1,
    WPI_PWM_OUTPUT      =>  2,

    WPI_LOW             =>  0,
    WPI_HIGH            =>  1,

    WPI_PUD_OFF         =>  0,
    WPI_PUD_DOWN        =>  1,
    WPI_PUD_UP          =>  2,

    WPI_PWM_MODE_MS     =>  0,
    WPI_PWM_MODE_BAL    =>  1,
    
    WPI_NES_RIGHT	=> 0x01,
    WPI_NES_LEFT	=> 0x02,
    WPI_NES_DOWN	=> 0x04,
    WPI_NES_UP		=> 0x08,
    WPI_NES_START	=> 0x10,
    WPI_NES_SELECT	=> 0x20,
    WPI_NES_B		=> 0x40,
    WPI_NES_A		=> 0x80,
};

{
    my @const = qw(
        WPI_NUM_PINS WPI_MODE_PINS WPI_MODE_GPIO WPI_MODE_GPIO_SYS
        WPI_MODE_PIFACE WPI_INPUT WPI_OUTPUT WPI_PWM_OUTPUT WPI_LOW
        WPI_HIGH WPI_PUD_OFF WPI_PUD_DOWN WPI_PUD_UP WPI_PWM_MODE_MS
        WPI_PWM_MODE_BAL
        WPI_NES_RIGHT WPI_NES_LEFT WPI_NES_DOWN WPI_NES_UP
        WPI_NES_START WPI_NES_SELECT WPI_NES_B WPI_NES_A
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{wiring}  = \@const;
}

# Perl implemented functions

sub serialPrintf {
    my ($filedesc, $format, @args) = @_;
    
    my $buffer;
    
    if( @args ) {
        $buffer = sprintf($format, @args);
    } else {
        $buffer = $format;
    }
    
    HiPi::Wiring::serialPuts( $filedesc, $buffer );
    return undef;
}

sub lcdPrintf {
    my ($filedesc, $format, @args) = @_;
    
    my $buffer;
    
    if( @args ) {
        $buffer = sprintf($format, @args);
    } else {
        $buffer = $format;
    }
    
    HiPi::Wiring::lcdPuts( $filedesc, $buffer );
    return undef;
}

1;

=pod

=encoding UTF-8

=head1 NAME

HiPi::Wiring - Deprecated module to access wiringPi library for Raspberry Pi GPIO

=head1 DESCRIPTION

This module is deprecated and will no longer be updated.

To access the wiringPi library, use the RPi::WiringPi module instead

=head1 AUTHOR

Mark Dootson, C<< mdootson@cpan.org >>.

=head1 COPYRIGHT

Copyright (c) 2013 - 2017 Mark Dootson

=cut


__END__
