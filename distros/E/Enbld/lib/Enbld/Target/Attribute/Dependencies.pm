package Enbld::Target::Attribute::Dependencies;

use strict;
use warnings;

use Carp;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ref( $param ) eq 'CODE' ) {
        $self->{callback} = $param;
        return $self;
    }

    # Usually, as for supporting a Dependencies, only OS X (darwin) is.
    # However, Enbld supports a Dependencies by the Code Reference
    # If You are and all the operating systems.
    $self->{value} = ( $^O eq 'darwin' ) ? $param : undef;

    $self->{is_evaluated}++;

    return $self;
}

sub validate {
    my ( $self, $value ) = @_;

    unless ( ref( $value ) eq 'ARRAY' ) {
        my $err = "Attribute 'Dependencies' isn't ARRAY reference";
        require Enbld::Exception;
        croak( Enbld::Exception->new( $err, $value ));
    }

    foreach my $string ( @{ $value } ) {
        $self->SUPER::validate( $string );
    }

    return $value;
}

sub to_value {
    my $self = shift;

    my $value = $self->evaluate;

    return [] if ( ! defined $value );

    $self->validate( $value );

    return $value;
}

1;
