package FLAT::Symbol;

use strict;
use Carp;

sub new {
    my ( $pkg, $label ) = @_;
    bless {
        LABEL  => $label,    #serialized representation
        OBJECT => $label,    #as object
        COUNT  => 1,
    }, $pkg;
}

sub _increment_count {
    my $self = shift;
    my $add  = $_[0] ? shift : 1;
    $self->{COUNT} += $add;
    return $self->{COUNT};
}

sub _decrement_count {
    my $self = shift;
    my $sub  = $_[0] ? shift : 1;
    $self->{COUNT} -= $sub;
    croak "Count less than 0!\n" if ( 0 > $self->{COUNT} );
    return $self->{COUNT};
}

sub get_count {
    my $self = shift;
    return $self->{COUNT};
}

sub as_string {
    return $_[0]->{LABEL};
}

1;
