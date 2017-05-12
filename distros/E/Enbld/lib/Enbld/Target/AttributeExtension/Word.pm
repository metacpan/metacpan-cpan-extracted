package Enbld::Target::AttributeExtension::Word;

use strict;
use warnings;

use parent qw/Enbld::Target::Attribute/;

use Carp;

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    if ( $string =~ /\s/ ) {
        my $type = ref( $self );
        $type =~ s/.*:://;
        require Enbld::Exception;
        croak( Enbld::Exception->new(
                    "Attribute '$type' includes space character", $string
                    ) );
    }

    return $string;
}

1;
