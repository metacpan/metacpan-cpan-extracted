package Geo::Coordinates::Converter::Format::ISO6709;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Format';

use POSIX;

use Geo::Coordinates::Converter::Format::Dms;

sub name { 'iso6709' }

sub detect {
    my($self, $point) = @_;
    return unless $point->isa('Geo::Coordinates::Converter::Point::ISO6709');
    return unless $point->iso6709 =~ m{\A[+-][0-9]+(?:\.[0-9]+)?[+-][0-9]+(?:\.[0-9]+)?(?:[+-][0-9]+(?:\.[0-9]+)?)?(?:CRS[_A-Z0-9]+)?/\z}i;
    return $self->name;
}

sub to {
    my($self, $point) = @_;

    if (my($lat_prefix, $lat, $lng_prefix, $lng, $height, $crs) = $point->iso6709 =~
            m{\A([+-])([0-9]{6}(?:\.[0-9]+)?)([+-])([0-9]{7}(?:\.[0-9]+)?)([+-][0-9]+(?:\.[0-9]+)?)?(?:CRS([_A-Z0-9]+))?/\z}i) {
        # dms
        my($lat_d, $lat_m, $lat_s) = $lat =~ /^(..)(..)(.+)$/;
        my($lng_d, $lng_m, $lng_s) = $lng =~ /^(...)(..)(.+)$/;

        $lat_prefix = '' unless $lat_prefix eq '-';
        $lng_prefix = '' unless $lng_prefix eq '-';
        $point->lat( $lat_prefix . ($lat_d + ($lat_m / 60) + ($lat_s / 3600)) );
        $point->lng( $lng_prefix . ($lng_d + ($lng_m / 60) + ($lng_s / 3600)) );
        $point->height($height + 0) if $height && $height != 0;
        $point->format('wgs84');
        return $point;
    }
    if (my($lat_prefix, $lat, $lng_prefix, $lng, $height, $crs) = $point->iso6709 =~
            m{\A([+-])([0-9]{4}(?:\.[0-9]+)?)([+-])([0-9]{5}(?:\.[0-9]+)?)([+-][0-9]+(?:\.[0-9]+)?)?(?:CRS([_A-Z0-9]+))?/\z}i) {
        # dm
        my($lat_d, $lat_m, $lat_f) = $lat =~ /^(..)(.+)(?:\.(.+))?$/;
        my($lng_d, $lng_m, $lng_f) = $lng =~ /^(...)(.+)(?:\.(.+))?$/;

        $lat_prefix = '' unless $lat_prefix eq '-';
        $lng_prefix = '' unless $lng_prefix eq '-';
        $lat_f ||= 0;
        $lng_f ||= 0;
        $lat_f = "0.$lat_f" * 1;
        $lng_f = "0.$lng_f" * 1;
        $point->lat( $lat_prefix . ($lat_d + ($lat_m / 60) + ($lat_f / 60)) );
        $point->lng( $lng_prefix . ($lng_d + ($lng_m / 60) + ($lng_f / 60)) );
        $point->height($height + 0) if $height && $height != 0;
        $point->format('wgs84');
        return $point;
    }
    if (my($lat_prefix, $lat, $lng_prefix, $lng, $height, $crs) = $point->iso6709 =~
            m{\A([+-])([0-9]{2}(?:\.[0-9]+)?)([+-])([0-9]{3}(?:\.[0-9]+)?)([+-][0-9]+(?:\.[0-9]+)?)?(?:CRS([_A-Z0-9]+))?/\z}i) {
        # degree

        $lat_prefix = '' unless $lat_prefix eq '-';
        $lng_prefix = '' unless $lng_prefix eq '-';
        $point->lat( $lat_prefix . $lat );
        $point->lng( $lng_prefix . $lng );
        $point->height($height + 0) if $height && $height != 0;
        $point->format('wgs84');
        return $point;
    }

    return $point;
}

sub from {
    my($self, $point) = @_;

    # re-bless to geohash point package
    # because i want ->geohash method
    bless $point, 'Geo::Coordinates::Converter::Point::ISO6709' unless $point->isa(__PACKAGE__);

    my $lat = $point->lat;
    my $lng = $point->lng;
    my $parts = 2;
    if ($point->format eq 'dms') {
        $point = Geo::Coordinates::Converter::Format::Dms->from($point);
        $lat = $point->lat;
        $lng = $point->lng;
        $parts = 4;
    }

    $lat = do {
        my @list = split /\./, $lat;
        $list[0] = sprintf '%02d', $list[0];
        $list[-1] = ".$list[-1]" if @list == $parts;
        unshift @list, ($list[0] >= 0 ? '+' : '');
        join '', @list;
    };
    $lng = do {
        my @list = split /\./, $lng;
        $list[0] = sprintf '%03d', $list[0];
        $list[-1] = ".$list[-1]" if @list == $parts;
        unshift @list, ($list[0] >= 0 ? '+' : '');
        join '', @list;
    };
    $lat =~ s/\.?0+$//;
    $lng =~ s/\.?0+$//;

    my $iso6709 = "$lat$lng";
    if ($point->height > 0) {
        $iso6709 .= '+' . $point->height;
    } elsif ($point->height < 0) {
        $iso6709 .= $point->height;
    }
    $point->iso6709("$iso6709/");
    $point->lat(undef);
    $point->lng(undef);
    $point->height(undef);

    $point;
}

1;

=head1 NAME

Geo::Coordinates::Converter::Format::ISO6709 - ISO6709 support for Geo::Coordinates::Converter

=head1 SYNOPSIS

  use Geo::Coordinates::Converter;
  use Geo::Coordinates::Converter::Point::ISO6709;

  my $geo = Geo::Coordinates::Converter->new(
      point => Geo::Coordinates::Converter::Point::ISO6709->new({
          iso6709 => '+35.36083+138.72750+3776CRSWGS_84/',
      }),
  );
  $geo->format('dms');
  say $geo->lat; # 35.21.38.988
  say $geo->lon; # 138.43.39.000
  say $geo->height; # 3776

lat/lng to ISO6709

  my $geo = Geo::Coordinates::Converter->new(
      lat => '35.360833', lng => '138.727500',
  );
  $geo->format('iso6709');
  say $geo->point->geohash; # +35.360833+138.7275/

=head1 DESCRIPTION

Geo::Coordinates::Converter::Format::ISO6709 is encodes and decodes ISO6709 format.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/ISO_6709>,
L<Geo::Coordinates::Converter::Point::ISO6709>,
L<Geo::Coordinates::Converter>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
