#########################################################################################
# Package        HiPi::RF::Message
# Description  : Generic protocol message
# Copyright    : Copyright (c) 2023 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::RF::Message;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );

our $VERSION ='0.89';

__PACKAGE__->create_accessors( qw(
    errorbuffer
    databuffer
    is_decoded
    is_encoded
));

sub new {
    my( $class, %params ) = @_;
    $params{errorbuffer}  = [];
    $params{databuffer} //= [];
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub push_error {
    my( $self, $error) = @_;
    if ( $error ) {
       push( @{ $self->errorbuffer }, $error );
    }
    return;
}

sub error {
    my $self = shift;
    return scalar @{ $self->errorbuffer };
}

sub shift_error {
    my $self = shift;
    my $rval = shift @{ $self->errorbuffer };
    return $rval;
}

sub inspect_buffer {
    my $self = shift;
    $self->push_error('Override inspect_buffer method in a derived class');
}

sub decode_buffer {
    my $self = shift;
    $self->push_error('Override decode_buffer method in a derived class');
}

sub encode_buffer {
    my $self = shift;
    $self->push_error('Override encode_buffer method in a derived class');
}

1;