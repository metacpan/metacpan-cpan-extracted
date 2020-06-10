#########################################################################################
# Package        HiPi::Interface
# Description  : Base class for interfaces
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use Time::HiRes qw( usleep );

__PACKAGE__->create_accessors( qw( device ) );

our $VERSION ='0.81';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub delay {
    my($class, $millis) = @_;
    usleep( int($millis * 1000) );
}

sub delayMicroseconds {
    my($class, $micros) = @_;
    usleep( int($micros) );
}

*HiPi::Interface::sleep_milliseconds = \&delay;
*HiPi::Interface::sleep_microseconds = \&delayMicroseconds;

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY;
    $self->device( undef );
} 

1;
