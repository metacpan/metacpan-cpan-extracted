#########################################################################################
# Package        HiPi::Device
# Description  : Base class for /dev devices
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Device;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi qw( :rpi );
use Time::HiRes qw( usleep );
use Carp;

__PACKAGE__->create_accessors( qw( devicename ) );

our $VERSION ='0.81';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub delay {
    my($class, $millis) = @_;
    usleep( int($millis * 1000));
}

sub delayMicroseconds {
    my($class, $micros) = @_;
    usleep( int($micros) );
}

*HiPi::Device::sleep_milliseconds = \&delay;
*HiPi::Device::sleep_microseconds = \&delayMicroseconds;

sub modules_are_loaded {
    my $class = shift;
    my $modulesloaded = 0;
    my $moduleoptions  = $class->get_required_module_options();
    my @lsmod= qx(lsmod);
    if( $?) {
        carp q(unable to determine if modules are loaded for HiPi::Device);
    } else {
        my %modules = map { (split(/\s+/, $_))[0..1] } @lsmod;
        for my $optionlist ( @$moduleoptions ) {
            my $thislistgood = 1;
            for my $module ( @$optionlist ) {
                unless( exists($modules{$module}) ) {
                    $thislistgood = 0;
                    last;
                }
            }
            if( $thislistgood) {
                # we found an option where required 
                # modules are loaded so we are good
                $modulesloaded = 1;
            }
        }
    }
    return $modulesloaded;
}

sub get_required_module_options {
    return [ [ qw( override in derived class with module list ) ] ];
}

sub close { 1; }

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
    $self->close;
}

1;

__END__
