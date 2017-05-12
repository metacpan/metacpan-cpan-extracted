package Geo::Coordinates::Converter::Datum;
use strict;
use warnings;

use Carp;
use String::CamelCase qw( camelize );
use Module::Load ();

use constant RADIAN => 4 * atan2(1, 1) / 180;

sub name { '' }
sub radius { 0 }
sub rate { 0 }
sub translation { +{ x => 0, y => 0, z => 0 } }

sub new {
    my($class, $args) = @_;
    $args = +{} unless defined $args;
    bless { %{ $args } }, $class;
}

sub load_datum {
    my($self, $datum) = @_;

    unless (ref $datum) {
        if ($datum =~ s/^\+//) {
            Module::Load::load($datum);
        } else {
            my $name = $datum;
            $datum = sprintf '%s::%s', ref $self, camelize($name);
            local $@;
            eval { Module::Load::load($datum) };
            if ($@ && ref $self ne __PACKAGE__) {
                $datum = sprintf '%s::%s', __PACKAGE__, camelize($name);
                Module::Load::load($datum);
            }
        }
        $datum = $datum->new;
    }
    $self->{datums}->{$datum->name} = $datum;
}

sub convert {
    my($self, $point, $datum) = @_;

    $self->load_datum($point->datum) unless $self->{datums}->{$point->datum};
    $self->load_datum($datum) unless $self->{datums}->{$datum};

    $self->{datums}->{$point->datum}->to_datum($point);
    $self->{datums}->{$datum}->datum_from($point);

    $point;
}

sub to_datum {
    my($self, $point) = @_;

    my $height = $point->height || 0;

    my $lat_sin = sin($point->lat * RADIAN);
    my $lat_cos = cos($point->lat * RADIAN);
    my $radius_rate = $self->radius / sqrt(1 - $self->rate * $lat_sin * $lat_sin);

    my $xy_base = ($radius_rate + $height) * $lat_cos;
    my $x = $xy_base * cos($point->lng * RADIAN);
    my $y = $xy_base * sin($point->lng * RADIAN);
    my $z = ($radius_rate * (1 - $self->rate) + $height) * $lat_sin;

    $point->lat($x + (-1 * $self->translation->{x}));
    $point->lng($y + (-1 * $self->translation->{y}));
    $point->height($z + (-1 * $self->translation->{z}));
    $point->datum('datum');

    $point;
}

sub datum_from {
    my($self, $point) = @_;

    my $x = $point->lat + $self->translation->{x};
    my $y = $point->lng + $self->translation->{y};
    my $z = $point->height + $self->translation->{z};

    my $rate_sqrt = sqrt(1 - $self->rate);

    my $xy_sqrt  = sqrt($x * $x + $y * $y);
    my $atan_base = atan2($z, $xy_sqrt * $rate_sqrt);
    my $atan_sin = sin($atan_base);
    my $atan_cos = cos($atan_base);
    my $lat = atan2($z + $self->rate * $self->radius / $rate_sqrt * $atan_sin * $atan_sin * $atan_sin,
                    $xy_sqrt - $self->rate * $self->radius * $atan_cos * $atan_cos * $atan_cos);
    my $lng = atan2($y, $x);

    my $lat_sin = sin($lat);
    my $radius_rate = $self->radius / sqrt(1 - $self->rate * ($lat_sin * $lat_sin));

    $point->height($xy_sqrt / cos($lat) - $radius_rate);
    $point->lat($lat / RADIAN);
    $point->lng($lng / RADIAN);
    $point->datum($self->name);

    $point;
}

1;

__END__

=head1 NAME

Geo::Coordinates::Converter::Datum - geo coordinates datum converter

=head1 DESCRIPTION

after it converts it into a three-dimensional orthogonalization coordinates,
the survey a land system has been converted.

when it dose not like this conversion algorithm, it is possible to rewrite
it by doing this package in use base and overwriting to_datum and datum_from.

as for these datums, the added thing is possible.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geo::Coordinates::Converter>,
L<Geo::Coordinates::Converter::Datum::Wgs84>, L<Geo::Coordinates::Converter::Datum::Tokyo>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
