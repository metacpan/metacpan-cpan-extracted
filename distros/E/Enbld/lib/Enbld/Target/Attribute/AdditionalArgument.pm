package Enbld::Target::Attribute::AdditionalArgument;

use strict;
use warnings;

use parent qw/Enbld::Target::AttributeExtension::Command/;

sub initialize {
    my ( $self, $param ) = @_;

    if ( ref( $param ) eq 'CODE' ) {
        $self->{callback} = $param;
        return $self;
    }

    if ( defined $param ) {
        $self->{value} = $param;
        $self->{is_evaluated}++;

        return $self;
    }

    $self->{callback} = sub {
        my $attributes = shift;

        if ( $^O eq 'darwin' ) {
            return $attributes->DarwinArgument;
        }

        return $attributes->DefaultArgument;
    };

    return $self;
}


sub is_omitable {
    return 1;
}

1;
