package Geo::Heatmap;
use Moose;
use Geo::Heatmap::USNaviguide_Google_Tiles;
use Imager;
use Storable;

has 'debug'         => (isa => 'Str', is => 'rw', default => 0);
has 'cache'         => (isa => 'Object', is => 'rw');
has 'logfile'       => (isa => 'Str', is => 'rw');
has 'return_points' => (isa => 'CodeRef', is => 'rw'); 
has 'zoom_scale'    => (isa => 'HashRef', is => 'rw'); 
has 'palette'       => (isa => 'Str', is => 'rw');
has 'scale'         => (isa => 'Int', is => 'rw', default => 1);
has 'blur'          => (isa => 'Int', is => 'rw', default => 4);  
has 'bin'           => (isa => 'Int', is => 'rw', default => 8); # should be a divisor of 256 
has 'density'       => (isa => 'HashRef', is => 'rw'); 

our $VERSION = '0.18';

__PACKAGE__->meta->make_immutable;

sub tile {
  my ($self, $tile, $debug) = @_;
  $debug |= 0;

  my ($x, $y, $z) = split(/\s+/, $tile);

  my $e;
  my %ubblob;
  my $k = 0;
  my $stitch;
  my $wi;
  my $line;
  my $ts = 256;

  my $mca = sprintf("blur_%s_%s_%s", $x, $y, $z);
  my $ubblob = $self->cache->get($mca);
  return $ubblob if defined $ubblob;

  my $image = Imager->new(xsize=>768, ysize=>768);
  for (my $i = -1; $i <= 1; $i++) {
    my $li = Imager->new();
    for (my $j = -1; $j <= 1; $j++) {
      $ubblob{$i}{$j} = $self->calc_hm_tile([$x+$j, $y+$i, $z]);
      $li->read(data => $ubblob{$i}{$j} ); 
  #    printf "%s %s\n", ($i+1)*$ts, ($j+1)*$ts;
      $image->paste(left=> ($j+1)*$ts, top=> ($i+1)*$ts, img=>$li);
    }
  }

  $image->filter(type=>"gaussian", stddev=>$self->blur);
  my $cropped = $image->crop(left=>255, top=>255, width=>256, height=>256);
  
  if ($debug > 1) {
    print "Debugging stitch\n";
  }

  $cropped->write(data => \$ubblob, type => 'png');
  $self->cache->set($mca, $ubblob);
  return $ubblob;
}


sub calc_hm_tile {
  my ($self, $coord) = @_;

  my ($x, $y, $z) = @$coord;

  my $mca = sprintf("raw_%s_%s_%s", $x, $y, $z);
  my $ubblob = $self->cache->get($mca);
  return $ubblob if defined $ubblob;  
  my $zoom_scale = $self->zoom_scale;

  my $value = &Google_Tile_Factors($z, 0) ;
  my %r = Google_Tile_Calc($value, $y, $x);

  my $image = Imager->new(xsize=>256, ysize=>256);
  $image->box(filled => 1, color => 'white');
  my $rp = $self->return_points();
  my $ps = &$rp(\%r);;
  my $palette = Storable::retrieve($self->palette);
  $palette->[-1] = [100, 100, 100];
  my @density;
  my $bin = $self->bin;
  foreach my $p (@$ps) {
    my @d = Google_Coord_to_Pix($value, $p->[0], $p->[1]);
    my $ix = $d[1] - $r{PXW};
    my $iy = $d[0] - $r{PYN};
    $density[int($ix/$bin)][int($iy/$bin)] ++;
    printf "%s %s %s %s\n", $ix, $iy, $ix % $bin, $iy % $bin if $self->debug >5;
  }
  
  my $maxval = ($bin)**2;
  # $zoom_scale->{$z} |= 0;
  my $defscale = $zoom_scale->{$z} > 0 ? $zoom_scale->{$z} : $maxval;
  $defscale *= 1.1 ;
  my $scale = 500/log($defscale);
  my $max = 256/$bin - 1;
  my $dmax = 0;
  
  for (my $i = 0; $i <= $max; $i++) {
    for (my $j = 0; $j <= $max; $j++) {
      my $xc  = $i*$bin;
      my $yc  = $j*$bin;
      my $xlc = $xc+$bin;
      my $ylc = $yc+$bin;
      my $d = $density[$i][$j] ? $density[$i][$j] : 1;
      $dmax = $d > $dmax ? $d : $dmax;
      my $color_index = int(500-log($d)*$scale);
      $color_index = 5 if $color_index < 1;
      $color_index = -1 if $d < 3;
      my $color = $palette->[$color_index];
      # from percent to RGB - gna
      my $rgb = Imager::Color->new( $color->[0] * 2.55, $color->[1]*2.55, $color->[2]*2.55 );
      $image->box(color=> $rgb, xmin=>$xc,  ymin=>$yc,
                               xmax=>$xlc, ymax=>$ylc, filled=>1);

#      $image->Draw(fill=>"rgb($rgb)" , primitive=>'rectangle', points=>"$xc,$yc $xlc,$ylc");
      printf "[%s][%s] %s %s\n", $i, $j, $d, $color_index if $self->debug > 0;
    }
  }
  
  if ($self->logfile) {
    open (LOG, ">>". $self->logfile);
    printf LOG  "densitylog:  x y z pointcount: %s %s %s %s\n", $x, $y, $z, $dmax;
    close LOG;
  }
  
  $image->write(data => \$ubblob, type => 'png');
  $self->cache->set($mca, $ubblob);
  return $ubblob;
}

1;


__END__

=pod

=head1 NAME

Geo::Heatmap - generate a density map (aka heatmap) overlay layer for Google Maps, see the www directory in the distro how it works

see the script directory for creating a scale

for a real life example see 

http://www.trust-box.at/dev/gm/GoogleMapsHeatmap/www/GoogleMapsHeatmap.html

for Dokumentation see

=head1 HOMEPAGE

http://www.trust-box.at/googlemaps-geoheatmap/

=head1 REQUIRES

  Moose
  CHI
  Imager

=head1 METHODS

=head2 tile

  tile();

  return the tile image in png format

=head1 ATTRIBUTES

  debug
  cache
  logfile
  return_points
  zoom_scale
  palette

=head2 USAGE

Create a Heatmap layer for GoogleMaps

=head3 The HTML part

=begin html

<pre>
<code>
  &lt;head&gt;
     &lt;meta name="viewport" content="initial-scale=1.0, user-scalable=no" /&gt;
     &lt;style type="text/css"&gt;
       html { height: 100% }
       body { height: 100%; margin: 0; padding: 0 }
       #map-canvas { height: 100% }
     &lt;/style&gt;
     &lt;script type="text/javascript"
       src="https://maps.googleapis.com/maps/api/js?key=<yourapikey>&sensor=true"&gt;
     &lt;/script&gt;
     &lt;script type="text/javascript"&gt;
       var overlayMaps = [{
         getTileUrl: function(coord, zoom) {
           return "hm.fcgi?tile="+coord.x+"+"+coord.y+"+"+zoom;
         },
 
         tileSize: new google.maps.Size(256, 256),
         isPng: true,
         opacity: 0.4
       }];
 
       function initialize() {
         var mapOptions = {
           center: new google.maps.LatLng(48.2130, 16.375),
           zoom: 9
         };
         var map = new google.maps.Map(document.getElementById("map-canvas"),
             mapOptions);
 
       var overlayMap = new google.maps.ImageMapType(overlayMaps[0]);
       map.overlayMapTypes.setAt(0,overlayMap);
 
       }
       google.maps.event.addDomListener(window, 'load', initialize);
 
     &lt;/script&gt;
   &lt;/head&gt;
   &lt;body&gt;
     &lt;div id="map-canvas"/&gt;
  &lt;/body&gt;
</code>
</pre>
<br>

=end html

=head3 The (f)cgi part

=begin html

<pre>
<code>
  #!/usr/bin/env perl
  
  use strict;
  use FCGI;
  use DBI;
  use CHI;
  use FindBin qw/$Bin/;
  use lib "$Bin/../lib";
  
  use Geo::Heatmap;
  
  #my $cache = CHI->new( driver  => 'Memcached::libmemcached',
  #    servers    => [ "127.0.0.1:11211" ],
  #    namespace  => 'GoogleMapsHeatmap',
  #);
  
  
  my $cache = CHI->new( driver => 'File',
           root_dir => '/tmp/GoogleMapsHeatmap'
       );
  
  
  our $dbh = DBI->connect("dbi:Pg:dbname=gisdb", 'gisdb', 'gisdb', {AutoCommit => 0});
  
  my $request = FCGI::Request();
  
  while ($request->Accept() >= 0) {
    my $env = $request->GetEnvironment();
    my $p = $env->{'QUERY_STRING'};
  
    my ($tile) = ($p =~ /tile=(.+)/);
    $tile =~ s/\+/ /g;
  
    # package needs a CHI Object for caching
    #               a Function Reference to get LatLOng within a Google Tile
    #               maximum number of points per zoom level
  
    my $ghm = Geo::Heatmap->new();
    $ghm->palette('palette.store');
    $ghm->zoom_scale( {
      1 => 298983,
      2 => 177127,
      3 => 104949,
      4 => 90185,
      5 => 70338,
      6 => 37742,
      7 => 28157,
      8 => 12541,
      9 => 3662,
      10 => 1275,
      11 => 417,
      12 => 130,
      13 => 41,
      14 => 18,
      15 => 10,
      16 => 6,
      17 => 2,
      18 => 0,
    } );
  
  sub get_points {
    my $r = shift;
  
    my $sth = $dbh->prepare( qq(select ST_AsEWKT(geom) from geodata
                           where geom &&
                ST_SetSRID(ST_MakeBox2D(ST_Point($r->{LATN}, $r->{LNGW}),
                                        ST_Point($r->{LATS}, $r->{LNGE})
                          ),4326))
                );
  
    $sth->execute();
  
    my @p;
    while (my @r = $sth->fetchrow) {
      my ($x, $y) = ($r[0] =~/POINT\((.+?) (.+?)\)/);
      push (@p, [$x ,$y]);
    }
    $sth->finish;
    return \@p;
  }
  </code>
  </pre>

=end html 

You need a color palette (one is included) to encode values to colors, in Storable Format as 
an arrayref of arrayrefs eg

    [50] = [34, 45, 56]

which means that a normalized value of 50 would lead to an RGB color of 34% red , 45% blue, 
56% green.

=over 4

=item zoom_scale

The maximum number of points for a given google zoom scale. You would be able to extract 
to values from the denisity log or derive them from your data in some cunning way

=item cache

You need some caching for the tiles otherwise the map would be quite slow. Use a CHI object 
with the cache you like

=item return_points

A function reference which expects a single hashref as a parameter which defines two LAT/LONG 
points to get all data points within this box:

      $r->{LATN}, $r->{LNGW}), $r->{LATS}, $r->{LNGE}

The function has to return an arrayref of arrayrefs of the points within the box

=item tile

Returns the rendered image

=back


=head1 REPOSITORY

L<https://github.com/MarkHofstetter/GoogleMapsHeatmap>

=head1 AUTHOR

Mark Hofstetter <hofstettm@cpan.org>

  Thanks to 
  brian d foy
  Marcel Gruenauer
  David Steinbrunner

=head1 TODO

=begin html

<ul>
  <li> put more magic in calculation of zoom scales </li>
  <li> make more things configurable </li>
  <li> add even more tests </li>
</ul>

=end html

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Hofstetter

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

