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

__PACKAGE__->create_accessors( qw( device ) );

our $VERSION ='0.65';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub DESTROY { $_[0]->device( undef ); } 

1;
