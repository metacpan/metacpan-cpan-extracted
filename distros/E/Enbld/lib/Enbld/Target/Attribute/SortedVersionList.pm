package Enbld::Target::Attribute::SortedVersionList;

use strict;
use warnings;

use Carp;
use version;

use parent qw/Enbld::Target::AttributeExtension::Word/;

require Enbld::Exception;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ! defined $param ) {
        $self->{callback} = sub {
            my $attributes = shift;

            my $list = $attributes->VersionList;

            my @sorted = sort {
                version->declare( $a ) cmp version->declare( $b )
            } @{ $list };

            return \@sorted;
        };

        return $self;
    };

    if ( $param ) {
        $self->SUPER::initialize( $param );
        return $self;
    }

    my $err = "Attribute 'SortedVersionList' isn't defined";
    croak( Enbld::Exception->new( $err ));
}

sub validate {
    my ( $self, $value ) = @_;

    unless ( ref( $value ) eq 'ARRAY' ) {
        my $type = ref( $self );
        $type =~ s/.*:://;

        my $err = "Attribute 'SortedVersionList' isn't ARRAY reference";
        croak( Enbld::Exception->new( $err, $value ));
    }

    if ( ! @{ $value } ) {
        my $err = "Attribute 'SortedVersionList' is no version list";
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
