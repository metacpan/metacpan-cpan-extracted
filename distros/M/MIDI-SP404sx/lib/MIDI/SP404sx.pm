package MIDI::SP404sx;
use strict;
use warnings;
use version; our $VERSION = version->declare("v1.0.0");

sub new {
    my $package = shift;
    my %args = @_;
    my $self = bless {}, $package;
    for my $property ( keys %args ) {
        if ( UNIVERSAL::can( $self, $property ) ) {
            $self->$property($args{$property});
        }
        else {
            die $property;
        }
    }
    return $self;
}

1;
