package Enbld::Target::Attribute::DownloadSite;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::URL/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    require Enbld::Exception;
    croak( Enbld::Exception->new( "Attribute 'DownloadSite' isn't defined" ));
}

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    return $string if ( $string =~ /\/$/ );

    my $err = "Attribute 'DownloadSite' does not end with slash character";
    require Enbld::Exception;
    croak( Enbld::Exception->new( $err, $string ));
}

1;
