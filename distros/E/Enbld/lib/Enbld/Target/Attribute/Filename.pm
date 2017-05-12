package Enbld::Target::Attribute::Filename;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = shift;

            my $filename = $attributes->ArchiveName . "-";
            $filename .= $attributes->Version . '.' . $attributes->Extension;

            return $filename;
        };

        return $self;
    }

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'Filename' isn't defined" ) );
}

1;
