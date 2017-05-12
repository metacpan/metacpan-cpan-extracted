package Enbld::Target::Attribute::URL;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::URL/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = shift;

            return $attributes->DownloadSite . $attributes->Filename;
        };

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'URL' isn't defined" ) );
}

1;
