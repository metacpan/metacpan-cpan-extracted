#########################################################################################
# Package        HiPi::Interface::HTADCI2C
# Description:  compatibi9lty
# Created       Sun Dec 02 01:42:27 2012
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::HTADCI2C;

#########################################################################################

use strict;
use warnings;

use parent qw( HiPi::Interface::HobbyTronicsADC );

our $VERSION = '0.59';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

1;

__END__

