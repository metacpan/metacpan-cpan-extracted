package Geo::Coordinates::Converter::Format::Degree;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Format';

our $DIGITS = 6;

sub name { 'degree' }

sub detect {
    my($self, $point) = @_;

    return unless defined $point->lat && $point->lat =~ /^[\-\+NS]?([0-9]{1,2}(?:\.[0-9]+))$/i;
    my $lat_nums = $1;
    return unless defined $point->lng && $point->lng =~ /^[\-\+WE]?([0-9]{1,3}(?:\.[0-9]+))$/i;
    my $lng_nums = $1;

    return unless -90  < $lat_nums && $lat_nums < 90 ;
    return unless -180 < $lng_nums && $lng_nums < 180;

    return $self->name;
}

sub round {
    my($self, $val) = @_;
    sprintf "%0${DIGITS}f", $val;
}

1;
