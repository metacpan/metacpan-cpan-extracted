package Enbld::Target::Attribute::VersionForm;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::RegEx/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'VersionForm' isn't defined" ));
}

1;
