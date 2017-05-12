package Enbld::Target::AttributeExtension::URL;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub validate {
    my ( $self, $string ) = @_;

    $self->SUPER::validate( $string );

    my $pattern = q{s?https?://[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]+};

    if ( $string !~ /^$pattern$/ ) {
        my $type = ref( $self );
        $type =~ s/.*:://;
        require Enbld::Exception;
        croak( Enbld::Exception->new(
            "Attribute '$type' isn't valid URL string", $string
        ));
    }
}

1;

