package Geo::OSM::Imager;

use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Math::Trig;
use Geo::Ellipsoid;
use LWP::UserAgent;
use HTTP::Request::Common;
use List::Util qw(max);
use List::MoreUtils qw(minmax);
use Imager;

=encoding utf-8

=head1 NAME

Geo::OSM::Imager - simplifies plotting onto OpenStreetMap tiles

=head1 SYNOPSIS

    my $g=Geo::OSM::Imager->new(ua => 'MyApplication');
    my $image=$g->init(\@points);
    ...
    my ($x,$y)=$g->latlon2xy($lat,$lon);
    $image->circle(x=>$x,y=>$y,r=>50,color=>$blue);
    ...
    $image->circle($g->latlon2hash($lat,$lon),r=>50,color=>$blue);
    ...
    $image->write(file => 'test.png');

=head1 DESCRIPTION

This module sets up an Imager object made of OpenStreetMap tiles, for
drawing of geographic data.

Beware of over-using OpenStreetMap tile servers, and see the usage
policy at https://operations.osmfoundation.org/policies/tiles/ .

Be hesitant about drawing straight lines over long distances, as map
projections will cause distortion. Over more than a few hundred
metres, the author prefers to break the line into a series of points
and plot individual line segments.

=cut

=head1 USAGE

=over

=item new()

Creates a new Geo::OSM::Imager object. Takes an optional hash of
parameters:

    maxx - maximum X size of the image, in pixels.
    maxy - maximum Y size of the image, in pixels.

The image will generally be between 50% and 100% of this size.

    margin    - fractional margin around bounding points
    marginlat - fractional latitude margin around bounding point
    marginlon - fractional longitude margin around bounding points

The fraction of the latitude/longitude span to leave as space around
the matter to be plotted. With a margin of zero, points will be
plotted right at the edges of the image. A margin of 1/7 works well,
and is the default. marginlat and marginlon allow you to define this
separately for latitude and longitude.

    tileage - minimum age to expire tiles

The number of seconds after which a tile may be considered "old" and
re-downloaded. Tileserver usage policy forbids an expiry of less than
one week (604800s), which is the default.

    tiledir - directory for the tile cache

The directory in which to store tiles; it must exist.

    tilesize - size of tiles

The pixel size of each tile. Leave at its default of 256 unless you
know what you're doing.

    tileurl - base URL for downloading tiles

The base URL for downloading files. If you are using a local
tileserver, or a public tileserver other than OpenStreetMap, set it
here. (A slash will be added, so don't end with one - usually this
shouldn't matter but tile.openstreetmap.org at least cares about the
difference.)

    ua - user-agent

Tileserver usage policy requires a "Valid HTTP User-Agent identifying
application". As a matter of policy you must set this yourself.

=cut

sub new {
  my ($pkg,%p)=@_;
  my $self={margin => 1/7,
            maxx => 2400,
            maxy => 2400,
            tileage => 604800,
            tiledir => "$ENV{HOME}/Maps/OSM",
            tilesize => 256,
            tileurl => 'https://tile.openstreetmap.org',
          };
  if (%p) {
    foreach my $param (qw(margin marginlat marginlon maxx maxy tileage tiledir tilesize tileurl ua)) {
      if (exists $p{$param}) {
        $self->{$param}=$p{$param};
      }
    }
  }
  $self->{marginlat} ||= $self->{margin};
  $self->{marginlon} ||= $self->{margin};
  $self->{lwp}=LWP::UserAgent->new(agent => $self->{ua});
  unless (defined $self->{ua}) {
    die "Need a user-agent to access OpenStreetMap tile servers";
  }
  bless($self,$pkg);
  return $self;
}

=item init()

Checks bounds and sets up the image. Pass an arrayref of points, each
of which can be either an arrayref [lat,lon] or a hashref including
lat and lon keys (or "latitude", "long", "longitude").

These need not be the same points you're going to plot, though that's
obviously the easiest approach.

Returns the Imager object.

=cut

sub init {
  my ($self,$points)=@_;
  my @series;
  foreach my $p (@{$points}) {
    if (ref $p eq 'ARRAY') {
      map {push @{$series[$_]},$p->[$_]} (0,1);
    } elsif (ref $p eq 'HASH') {
      my $lat;
      foreach my $latname (qw(lat latitude)) {
        $lat ||= $p->{$latname};
      }
      my $lon;
      foreach my $lonname (qw(lon long longitude)) {
        $lon ||= $p->{$lonname};
      }
      if (defined $lat && defined $lon) {
        push @{$series[0]},$lat;
        push @{$series[1]},$lon;
      }
    }
  }
  my @minmax=map {[minmax(@{$_})]} @series;
  $self->{geo}=Geo::Ellipsoid->new(units => 'degrees');

  my %bounds=(lon => [undef,undef],
              lat => [undef,undef]);
  $bounds{lat}[0]=$minmax[0][0]-($minmax[0][1]-$minmax[0][0])*$self->{marginlat};
  $bounds{lat}[1]=$minmax[0][1]+($minmax[0][1]-$minmax[0][0])*$self->{marginlat};
  $bounds{lon}[0]=$minmax[1][0]-($minmax[1][1]-$minmax[1][0])*$self->{marginlon};
  $bounds{lon}[1]=$minmax[1][1]+($minmax[1][1]-$minmax[1][0])*$self->{marginlon};

  my $longdist=max(
    $self->{geo}->to($bounds{lat}[0],$bounds{lon}[0],$bounds{lat}[0],$bounds{lon}[1]),
    $self->{geo}->to($bounds{lat}[1],$bounds{lon}[0],$bounds{lat}[1],$bounds{lon}[1]),
      );                                 # metres
  my $longscale=$longdist/$self->{maxy}; # metres/pixel
  my $latdist=max(
    $self->{geo}->to($bounds{lat}[0],$bounds{lon}[0],$bounds{lat}[1],$bounds{lon}[0]),
    $self->{geo}->to($bounds{lat}[0],$bounds{lon}[1],$bounds{lat}[1],$bounds{lon}[1]),
      );
  my $latscale=$latdist/$self->{maxx};
  my $scale=max($longscale,$latscale); # make sure it fits, use wider scale
  $self->{zoomlevel}=int(
    log(
      cos(
        deg2rad(
          ($bounds{lat}[0]+$bounds{lat}[1])/2
            )
          )*6378137.0*2*pi/$scale
            )/log(2)-8
              );

  while ($self->{zoomlevel} > 18) {
    $self->{zoomlevel}--;
    foreach my $mode (qw(lat lon)) {
      my $mean=($bounds{$mode}[0]+$bounds{$mode}[1])/2;
      foreach my $nn (0,1) {
        $bounds{$mode}[$nn]+=($bounds{$mode}[$nn]-$mean);
      }
    }
  }

  $self->{xmax}=int(($self->getTileNumber($bounds{lat}[1],$bounds{lon}[1]))[0]+.9999999);
  $self->{xmin}=int(($self->getTileNumber($bounds{lat}[0],$bounds{lon}[0]))[0]);
  $self->{ymax}=int(($self->getTileNumber($bounds{lat}[0],$bounds{lon}[0]))[1]+.9999999);
  $self->{ymin}=int(($self->getTileNumber($bounds{lat}[1],$bounds{lon}[1]))[1]);

  my $img=Imager->new(xsize => $self->{tilesize}*($self->{xmax}-$self->{xmin}+1),                     ysize => $self->{tilesize}*($self->{ymax}-$self->{ymin}+1),
                      channels => 4);
  mkdir "$self->{tiledir}/$self->{zoomlevel}";
  foreach my $x ($self->{xmin}..$self->{xmax}) {
    mkdir "$self->{tiledir}/$self->{zoomlevel}/$x";
    foreach my $y ($self->{ymin}..$self->{ymax}) {
      my $stub="$self->{zoomlevel}/$x/$y.png";
      my $dl=1;
      if (-e "$self->{tiledir}/$stub") {
        my $fa=(stat("$self->{tiledir}/$stub"))[9];
        if (time-$fa < $self->{tileage}) {
          $dl=0;
        }
      }
      if ($dl) {
        my $rq=HTTP::Request->new(GET => "$self->{tileurl}/$stub");
        my $rp=$self->{lwp}->request($rq);
        if ($rp->is_success) {
          open OUT,">$self->{tiledir}/$stub" or die "Can't open $self->{tiledir}/$stub for writing\n";
          binmode OUT;
          print OUT $rp->content;
          close OUT;
        } else {
          die "Couldn't fetch $self->{tileurl}/$stub\n";
        }
      }
      my $i=Imager->new;
      $i->read(file => "$self->{tiledir}/$self->{zoomlevel}/$x/$y.png");
      $img->rubthrough(left => $self->{tilesize}*($x-$self->{xmin}),
                       top => $self->{tilesize}*($y-$self->{ymin}),
                       src => $i);
    }
  }
  $self->{offsetx}=$self->{offsety}=$self->{img}=0;
  my $xclipmax=int(($self->latlon2xy($bounds{lat}[1],$bounds{lon}[1]))[0]);
  my $xclipmin=int(($self->latlon2xy($bounds{lat}[0],$bounds{lon}[0]))[0]+.9999999);
  my $yclipmax=int(($self->latlon2xy($bounds{lat}[0],$bounds{lon}[0]))[1]+.9999999);
  my $yclipmin=int(($self->latlon2xy($bounds{lat}[1],$bounds{lon}[1]))[1]);
  $self->{img}=$img->crop(left => $xclipmin,
                          top => $yclipmin,
                          width => $xclipmax-$xclipmin,
                          height => $yclipmax-$yclipmin);
  $self->{offsetx}=-$xclipmin;
  $self->{offsety}=-$yclipmin;
  return $self->{img};
}

=item image()

Returns the Imager object.

=cut

# let the user plot onto it
sub image {
  my ($self)=@_;
  unless (exists $self->{img}) {
    die "Not yet initialised.\n";
  }
  return $self->{img};
}

=item zoom()

Returns the zoom level of the initialised object. See
L<Zoom levels|http://wiki.openstreetmap.org/wiki/Zoom_levels> and
L<Slippy Map Tilenames|http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames>
for more.

=cut

sub zoom {
  my ($self)=@_;
  unless (exists $self->{img}) {
    die "Not yet initialised.\n";
  }
  return $self->{zoomlevel};
}

sub getTileNumber {
  my ($self,$lat,$lon) = @_;
  my $zoom = $self->{zoomlevel};
  my $xtile = ($lon+180)/360 *2**$zoom;
  my $ytile = (1 - log(tan(deg2rad($lat)) + sec(deg2rad($lat)))/pi)/2 *2**$zoom;
  return ($xtile, $ytile);
}

=item latlon2xy($lat,$lon)

Given a (latitude, longitude) coordinate pair, returns the (x, y)
coordinate pair needed to plot onto the Imager object.

=cut

sub latlon2xy {
  my ($self,$lat,$lon) = @_;
  unless (exists $self->{img}) {
    die "Not yet initialised.\n";
  }
  my ($x,$y)=$self->getTileNumber($lat,$lon);
  $x=($x-$self->{xmin})*$self->{tilesize}+$self->{offsetx};
  $y=($y-$self->{ymin})*$self->{tilesize}+$self->{offsety};
  return ($x,$y);
}

=item latlon2hash($lat,$lon)

Given a (latitude, longitude) coordinate pair, returns a list of the
form ('x', $x, 'y', $y) for use with many Imager plotting functions.

=cut

sub latlon2hash {
  my ($self,$lat,$lon) = @_;
  my ($x,$y)=$self->latlon2xy($lat,$lon);
  return ('x',$x,'y',$y);
}

=item segment($lat1,$lon1,$lat2,$lon2,$step)

Given two (latitude, longitude) coordinate pairs and a step value,
returns an arrayref of (latitude, longitude) coordinate pairs
interpolating the route on a great circle. This is generally worth
doing when distances exceed around 100 miles or high precision is
wanted.

A positive step value is the length of each segment in metres. A
negative step value is the number of divisions into which the overall
line should be split.

=cut

sub segment {
  my ($self,$lat1,$lon1,$lat2,$lon2,$step)=@_;
  my @out=[$lat1,$lon1];
  my ($r,$b)=$self->{geo}->to($lat1,$lon1,$lat2,$lon2);
  if ($step<0) {
    $step=-$r/$step;
  }
  my $ra=0;
  while ($ra<$r) {
    $ra+=$step;
    push @out,[$self->{geo}->at($lat1,$lon1,$ra,$b)];
    $out[-1][1]=$self->constrain($out[-1][1],180);
  }
  push @out,[$lat2,$lon2];
  return @out;
}

sub constrain {
  my ($self,$angle,$range)=@_;
  while ($angle>$range) {
    $angle-=$range*2;
  }
  while ($angle<-$range) {
    $angle+=$range*2;
  }
  return $angle;
}

=back

=head1 OTHER CONSIDERATIONS

Note that you need not draw directly onto the supplied object: you can
create a new transparent image using the width and height of the one
provided by the module, draw onto that, and copy the results with a
rubthrough or compose command. See L<Imager::Transformations> for
more.

=head1 BUGS

Won't work to span +/- 180 degrees longitude.

=head1 LICENSE

Copyright (C) 2017 Roger Bell_West.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Roger Bell_West E<lt>roger@firedrake.orgE<gt>

=head1 SEE ALSO

L<Imager>

=cut

1;
