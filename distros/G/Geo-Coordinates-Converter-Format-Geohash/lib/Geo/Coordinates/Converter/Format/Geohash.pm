package Geo::Coordinates::Converter::Format::Geohash;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Format';
our $VERSION = '0.05';

use Geo::Coordinates::Converter::Point::Geohash;
use Geohash;

sub name { 'geohash' }

sub new {
    my($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{geohash} = Geohash->new;
    $self;
}

sub detect {
    my($self, $point) = @_;
    return unless $point->isa('Geo::Coordinates::Converter::Point::Geohash');
    return unless $point->geohash =~ /\A[0-9bcdefghjkmnpqrstuvwxyz]+\z/i;
    return $self->name;
}

# geohash to lat/lng
sub to {
    my($self, $point) = @_;

    my($lat, $lng) = $self->{geohash}->decode($point->{geohash});
    $point->lat($lat);
    $point->lng($lng);
    $point->geohash(undef);

    $point;
}

# lat/lng to geohash
sub from {
    my($self, $point) = @_;

    # re-bless to geohash point package
    # because i want ->geohash method
    bless $point, 'Geo::Coordinates::Converter::Point::Geohash' unless $point->isa(__PACKAGE__);

    my $geohash = $self->{geohash}->encode($point->lat, $point->lng);
    $point->geohash($geohash);
    $point->lat(undef);
    $point->lng(undef);

    $point;
}

1;
__END__

=head1 NAME

Geo::Coordinates::Converter::Format::Geohash - Geohash support for Geo::Coordinates::Converter

=head1 SYNOPSIS

  use Geo::Coordinates::Converter;
  use Geo::Coordinates::Converter::Point::Geohash;

  Geo::Coordinates::Converter->add_default_formats('Geohash');
  my $geo = Geo::Coordinates::Converter->new(
      point => Geo::Coordinates::Converter::Point::Geohash->new({
          geohash => 'xn76gg',
      }),
  );
  $geo->format('dms');
  say $geo->lat; # 35.39.31.948
  say $geo->lon; # 139.44.26.162

lat/lng to geohash

  my $geo = Geo::Coordinates::Converter->new(
      lat => '35.658875', lng => '139.740601',
  );
  $geo->format('geohash');
  say $geo->point->geohash; # xn76ggs00006

=head1 DESCRIPTION

Geo::Coordinates::Converter::Format::Geohash is encodes and decodes geohash locations.

Geo::Coordinates::Converter::Format:Geohash uses L<Geohash> as a backend module.
You can easy choose of Pure-Perl implement or XS implement by L<Geohash>.

I attached L<Geo::Coordinates::Converter::Point::Geohash> which expanded L<Geo::Coordinates::Converter::Point>, and could treat geohash.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geohash>,
L<Geo::Coordinates::Converter::Point::Geohash>,
L<Geo::Coordinates::Converter>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
