package Enbld::Target::Attribute::Prefix;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{value} = '--prefix=';
        $self->{is_evaluated}++;

        return $self;
    }

    if ( $param ) { 
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'Prefix' isn't defined" ) );
}

1;
