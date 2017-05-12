#########################################################################################
# Package       HiPi::Wiring::Pin
# Description:  Pin
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wiring::Pin;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use HiPi qw( :rpi );

our $VERSION ='0.61';

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    my $self = $class->SUPER::_open(%params);
    return $self;
}

1;
