package Enbld::Target::Attribute::VersionList;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

require Enbld::Exception;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = shift;

            require Enbld::HTTP;
            my $html = Enbld::HTTP->get_html( $attributes->IndexSite );
            my $list = $html->parse_version(
                    $attributes->IndexParserForm,
                    $attributes->VersionForm
                    );

            return $list;
        };

        return $self;
    };

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    my $err = "Attribute 'VersionList' isn't defined";
    croak( Enbld::Exception->new( $err ));
}

sub validate {
    my ( $self, $value ) = @_;

    unless ( ref( $value ) eq 'ARRAY' ) {
        my $type = ref( $self );
        $type =~ s/.*:://;

        my $err = "Attribute 'VersionList' isn't ARRAY reference";
        croak( Enbld::Exception->new( $err, $value ));
    }

    if ( ! @{ $value } ) {
        my $err = "Attribute 'VersionList' is no version list";
        croak( Enbld::Exception->new( $err ));
    }

    foreach my $string ( @{ $value } ) {
        $self->SUPER::validate( $string );
    }

    return $value;
}

sub to_value {
    my $self = shift;

    my $value = $self->evaluate;

    $self->validate( $value );

    return $value;
}

1;
