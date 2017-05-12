package Enbld::Target::AttributeCollector;

use strict;
use warnings;

use Carp;

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub add {
    my ( $self, $name, $param ) = @_;

    if ( $self->{$name} ) {
        require Enbld::Exception;
        croak( Enbld::Exception->new( $name . " is already added" ) );
    }

    require Enbld::Target::Attribute;
    $self->{$name} = Enbld::Target::Attribute->new( $name, $param );
    $self->{$name}->link_to_collector( $self );

    return $self;
}

sub AUTOLOAD {
    my $self = shift;

    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;

    return $self->{$method}->to_value if ( exists $self->{$method} );

    require Enbld::Exception;
    croak( Enbld::Exception->new( "'$method' is invalid method" ) );
}

sub DESTROY {
    # do nothing
}

1;
