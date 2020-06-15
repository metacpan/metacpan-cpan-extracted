#########################################################################################
# Package        HiPi::Interface::Common::Weather
# Description  : Common weather utils
# Copyright    : Copyright (c) 2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Common::Weather;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );

our $VERSION ='0.82';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub sea_level_pressure {
    my( $class, $pressure, $altitude, $temperature, $gravity) = @_;
    $gravity ||= 9.81;   # acceleration due to gravity
    my $dgc    = 287.0; # dry gas constant
    
    # Po = ((P * 1000) * Math.exp((g*Zg)/(Rd *  (Tv_avg + 273.15))))/1000;
    
    my $result = (($pressure * 1000) * exp(($gravity * $altitude)/($dgc *  ($temperature + 273.15))))/1000;
    
    $result = sprintf("%.2f", $result);
    return $result;
}


1;

__END__


