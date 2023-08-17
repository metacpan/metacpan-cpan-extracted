package Geo::Location::TimeZoneFinder;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.001;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::TimeZoneFinder - Map geographic coordinates to time zone names

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Geo::Location::TimeZoneFinder;

  my $finder = Geo::Location::TimeZoneFinder->new(
    file_base => 'combined-shapefile');
  my @time_zones = $finder->time_zones_at(lat => $lat, lon => $lon);

=head1 DESCRIPTION

A Perl module that maps geographic coordinates to time zone names, such as
"Asia/Shanghai".  The module uses database files that are published by the
Timezone Boundary Builder project.

=head1 SUBROUTINES/METHODS

=head2 new

  my $finder = Geo::Location::TimeZoneFinder->new(
    file_base => 'combined-shapefile');

The "file_base" parameter is the base path name for your database files.  The
extensions F<.dbf> and F<.shp> will be added to the base path name.

Returns a new object.  Dies on invalid parameters and file read errors.

=head2 time_zones_at

  my @time_zones =
    $finder->time_zones_at(latitude => $lat, longitude => $lon);
  my $time_zone = $finder->time_zones_at(lat => $lat, lon => $lon);

Returns the names of the time zones at the coordinates given by the named
parameters "latitude" und "longitude".  In scalar context, only one name is
returned.

The parameters "latitude" und "longitude" can be abbreviated to "lat" and
"lon".  The latitude and longitude must be in the ranges -90 to 90 and -180 to
180, respectively.

Dies on invalid parameters and file read errors.

The time zone names correspond to the names in the IANA time zone database,
which is used by most Unix systems.

There is usually one time zone in a location, but there are disputed areas
with multiple time zones as well as locations on boundaries, such as the North
Pole at latitude 90° and the International Date Line at longitude 180°.

=head2 time_zone_at

  my $time_zone = $finder->time_zone_at(lat => $lat, lon => $lon);

An alias for C<time_zones_at> that always returns a single value.

=head2 index

  for my $shape (@{$finder->index}) {
    my ($x_min, $y_min, $x_max, $y_max) = @{$shape->{bounding_box}};
    my $file_offset = $shape->{file_offset};
    my $time_zone   = $shape->{time_zone};
  }

Returns the internal index that is used to look up boundaries in the shape
file.

=head1 DIAGNOSTICS

=over

=item B<< The "file_base" parameter is mandatory >>

The constructor was called without a filename base.

=item B<< The "latitude" parameter is mandatory >>

No "latitude" parameter was given.

=item B<< The "longitude" parameter is mandatory >>

No "longitude" parameter was given.

=item B<< The "latitude" parameter N is not a number between -90 and 90 >>

The latitude must be a number between -90 and 90.

=item B<< The "longitude" parameter N is not a number between -180 and 180 >>

The longitude must be a number between -180 and 180.

=item B<< Error opening "FILE" >>

A file cannot be opened.

=item B<< Error reading "FILE" >>

A file cannot be read.

=item B<< Cannot set file position to N in "FILE" >>

The position in a file cannot be set.

=item B<< Expected N records, got M in "FILE" >>

The number of records does not match the information in the file's header or
the number of records in another file.

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the file F<timezones.shapefile.zip> from
L<https://github.com/evansiroky/timezone-boundary-builder>.  The zip archive
must be extracted to a directory.

=head1 INCOMPATIBILITIES

None.

=head1 EXAMPLES

Most Unix systems accept time zone names in the environment variable C<TZ>.

  use Geo::Location::TimeZoneFinder;

  my $finder = Geo::Location::TimeZoneFinder->new(
    file_base => 'combined-shapefile');

  my $tz   = $finder->time_zone_at(lat => 39.916, lon => 116.383);
  my @time = do { local $ENV{TZ} = ":$tz"; localtime };

Speed up repeated lookups by using a cache.

  use Geo::Location::TimeZoneFinder;
  use Mojo::Cache;

  my $cache  = Mojo::Cache->new;
  my $finder = Geo::Location::TimeZoneFinder->new(
    file_base => 'combined-shapefile');

  sub time_zone_at {
    my %args = @_;

    my $lat = $args{lat};
    my $lon = $args{lon};
    my $key = "$lat,$lon";
    my $tz  = $cache->get($key);
    if (!defined $tz) {
      $tz = $finder->time_zone_at(lat => $lat, lon => $lon);
      $cache->set($key, $tz);
    }
    return $tz;
  }

=head1 BUGS AND LIMITATIONS

This module uses the point-in-polygon algorithm described in [1], which is
very accurate but "cannot solve the problem of instability that can result
from the comparison operations of floating-point numbers".

[1] Jianqiang Hao, Jianzhi Sun, Yi Chen, Qiang Cai, and Li Tan. "Optimal
Reliable Point-in-Polygon Test and Differential Coding Boolean Operations on
Polygons". Symmetry, 10, 2018.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
