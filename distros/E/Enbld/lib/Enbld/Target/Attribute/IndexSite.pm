package Enbld::Target::Attribute::IndexSite;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::URL/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            return $self->{attributes}->DownloadSite;
        };

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'IndexSite' isn't defined" ) );
}

1;
