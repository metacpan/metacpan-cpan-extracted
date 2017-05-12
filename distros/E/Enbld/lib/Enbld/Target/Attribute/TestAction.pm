package Enbld::Target::Attribute::TestAction;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Command/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{value} = 'check';
        $self->{is_evaluated}++;

        return $self;
    }

    if ( $param ) { 
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'TestAction' isn't defined" ) );
}

1;
