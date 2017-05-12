package Geo::Coordinates::Converter::Format::Milliseconds;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Format';

use POSIX;

sub name { 'milliseconds' }

sub detect {
    my($self, $point) = @_;

    return unless defined $point->lat && -324_000_000 < $point->lat && $point->lat < 324_000_000 && $point->lat =~ /^-?[0-9]+$/;
    return unless defined $point->lng && -648_000_000 < $point->lng && $point->lng < 648_000_000 && $point->lng =~ /^-?[0-9]+$/;

    return $self->name;
}

sub to {
    my($self, $point) = @_;

    $point->lat($point->lat / 360_0000);
    $point->lng($point->lng / 360_0000);

    $point;
}

sub from {
    my($self, $point) = @_;

    $point->lat($self->round($point->lat * 360_0000));
    $point->lng($self->round($point->lng * 360_0000));

    $point;
}

sub round {
    my($self, $val) = @_;
    ceil($val);
}

1;

