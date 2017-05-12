package Enbld::Target::Attribute::CommandInstall;

use strict;
use warnings;

use parent qw/Enbld::Target::AttributeExtension::Command/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {

        $self->{value} = $self->make_command . ' install';
        $self->{is_evaluated}++;

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    # empty string is valid.
    $self->{is_evaluated}++;
}

sub validate {
    my ( $self, $string ) = @_;

    # nothing check now.

    return $string;
}

1;
