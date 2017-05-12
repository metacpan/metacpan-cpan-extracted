package Enbld::Target::AttributeExtension::RegEx;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::Attribute/;

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    eval { "" =~ /$string/ };

    if ( $@ ) {
        my $type = ref( $self );
        $type =~ s/.*:://;

        require Enbld::Exception;
        croak( Enbld::Exception->new(
                "Attribute '$type' is NOT valid regular expression string",
                $string
                    ) );
    }

    return $string;
}

1;
