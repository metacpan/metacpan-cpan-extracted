package Enbld::Target::Attribute::ArchiveName;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'ArchiveName' isn't defined" ) );
}

1;
