package GPS::Point;
use strict;
use warnings;
use Scalar::Util qw{reftype};

our $VERSION = '0.20';

=head1 NAME

GPS::Point - Provides an object interface for a GPS point.

=head1 SYNOPSIS

  use GPS::Point;
  my $obj=GPS::Point->newGPSD($GPSD_O_line);#e.g. GPSD,O=....
  my $obj=GPS::Point->new(
         time        => $time,    #float seconds from the unix epoch
         lat         => $lat,     #signed degrees
         lon         => $lon,     #signed degrees
         alt         => $hae,     #meters above the WGS-84 ellipsoid
         speed       => $speed,   #meters/second (over ground)
         heading     => $heading, #degrees clockwise from North
         climb       => $climb,   #meters/second
         etime       => $etime,   #float seconds
         ehorizontal => $ehz,     #float meters
         evertical   => $evert,   #float meters
         espeed      => $espeed,  #meters/second
         eheading    => $ehead,   #degrees
         eclimb      => $eclimb,  #meters/second
         mode        => $mode,    #GPS mode [?=>undef,None=>1,2D=>2,3D=>3]
         tag         => $tag,     #Name of the GPS message for data
       ); 

=head1 DESCRIPTION

This is a re-write of L<Net::GPSD::Point> with the goal of being more re-usable.

GPS::Point - Provides an object interface for a GPS fix (e.g. Position, Velocity and Time).

  Note: Please use Geo::Point, if you want 2D or projection support.

=head1 USAGE

  print scalar($point->latlon), "\n";       #latlon in scalar context
  my ($x,$y,$z)=$point->ecef;               #if Geo::ECEF is available
  my $GeoPointObject=$point->GeoPoint;      #if Geo::Point is available
  my @distance=$point->distance($point2);   #if Geo::Inverse is available
  my $distance=$point->distance($point2);   #if Geo::Inverse->VERSION >=0.05

=head1 USAGE TODO

  my $obj=GPS::Point->newNMEA($NMEA_lines); #e.g. GGA+GSA+RMC

=head1 CONSTRUCTORS

=head2 new

  my $obj = GPS::Point->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 newGPSD

  my $obj=GPS::Point->newGPSD($GPSD_O_line);#e.g. GPSD,O=....

Note: GPSD protocol 2 is soon to be defunct.

=cut

sub newGPSD {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initializeGPSD(@_);
  return $self;
}

=head2 newMulti

Constructs a GPS::Point from a Multitude of arguments. Arguments can be a L<GPS::Point>, L<Geo::Point>, {lat=>$lat,lon=>$lon} (can be blessed), [$lat, $lon] (can be blessed) or a ($lat, $lon) pair. 

  my $point=GPS::Point->newMulti( $lat, $lon, $alt ); #supports lat, lon and alt
  my $point=GPS::Point->newMulti([$lat, $lon, $alt]); #supports lat, lon and alt
  my $point=GPS::Point->newMulti({lat=>$lat, lon=>$lon, ...});
  my $point=GPS::Point->newMulti(GPS::Point->new(lat=>$lat, lon=>$lon));
  my $point=GPS::Point->newMulti(Geo::Point->new(lat=>$lat, long=>$lon, proj=>'wgs84'));
  my $point=GPS::Point->newMulti({latitude=>$lat, longtude=>$lon});

Note: Hash reference context supports the following keys lat, lon, alt, latitude, longitude, long, altitude, elevation, hae, elev.

Note: Units are always decimal degrees for latitude and longitude and meters above the WGS-84 ellipsoid for altitude.

=cut

sub newMulti {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initializeMulti(@_);
  return $self;
}

=head2 initialize, initializeGPSD, initializeMulti

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
}

sub initializeGPSD {
  my $self=shift();
  my $line=shift(); #GPSD,O=MID2 1175911006.190 ? 53.527185 -113.530093 705.51 4.00 3.49 0.0000 0.074 0.101 ? 8.00 6.99 3
  my @line=split(/,/, $line);
  warn("Warning: Expected GPSD formatted line.") unless $line[0] eq "GPSD";
  my $obj=undef();
  foreach (@line) { #I pull the last one if O=?,O=?,...
    my @rpt=split(/=/, $_);
    if ($rpt[0] eq 'O') {
      my @data=map {&_q2u($_)} split(/\s+/, $rpt[1]);
      %$self=(tag         => $data[ 0],
              time        => $data[ 1],
              etime       => $data[ 2],
              lat         => $data[ 3],
              lon         => $data[ 4],
              alt         => $data[ 5],
              ehorizontal => $data[ 6],
              evertical   => $data[ 7],
              heading     => $data[ 8],
              speed       => $data[ 9],
              climb       => $data[10],
              eheading    => $data[11],
              espeed      => $data[12],
              eclimb      => $data[13],
              mode        => $data[14]);
    }
  } 
}

sub initializeMulti {
  my $self=shift;
  my $point=shift;
  if (!ref($point)) {
    $self->{'lat'}=$point                          ||0;
    $self->{'lon'}=shift                           ||0;
    $self->{'alt'}=shift                           ||0;
  } elsif (ref($point) eq "Geo::Point") {
    $point=$point->in('wgs84') unless $point->proj eq "wgs84";
    $self->{'lat'}=$point->latitude                ||0;
    $self->{'lon'}=$point->longitude               ||0;
  } elsif (ref($point) eq "GPS::Point") {
    %$self=%$point;
  } elsif (ref($point) eq "Net::GPSD::Point") {
    $self->{'time'}=$point->time;
    $self->{'lat'}=$point->latitude                ||0;
    $self->{'lon'}=$point->longitude               ||0;
    $self->{'alt'}=$point->altitude                ||0;
    $self->{'speed'}=$point->speed;
    $self->{'heading'}=$point->heading;
    $self->{'climb'}=$point->climb;
    $self->{'etime'}=$point->errortime;
    $self->{'ehorizontal'}=$point->errorhorizontal;
    $self->{'evertical'}=$point->errorvertical;
    $self->{'espeed'}=$point->errorspeed;
    $self->{'eheading'}=$point->errorheading;
    $self->{'eclimb'}=$point->errorclimb;
    $self->{'mode'}=$point->mode;
    $self->{'tag'}=$point->tag;
  } elsif (reftype($point) eq "HASH") {
    %$self=%$point;
    $self->{'lat'}=$point->{'lat'}                 ||
                     delete($point->{'latitude'})  ||0;
    $self->{'lon'}=$point->{'lon'}                 ||
                     delete($point->{'long'})      ||
                     delete($point->{'longitude'}) ||0;
    $self->{'alt'}=$point->{'alt'}                 ||
                     delete($point->{'altitude'})  ||
                     delete($point->{'elevation'}) ||
                     delete($point->{'hae'})       ||
                     delete($point->{'elev'})      ||0;
  } elsif (reftype($point) eq "ARRAY") {
    $self->{'lat'}=$point->[0]                     ||0;
    $self->{'lon'}=$point->[1]                     ||0;
    $self->{'alt'}=$point->[2]                     ||0;
  }
}

=head1 METHODS (Base)

=head2 time

Sets or returns seconds since the Unix epoch, UTC (float, seconds)

  print $obj->time, "\n";

=cut

sub time {
  my $self = shift();
  $self->{'time'}=shift() if @_;
  return $self->{'time'};
}

=head2 lat, latitude

Sets or returns Latitude (float, degrees)

  print $obj->lat, "\n";

=cut

*latitude=\&lat;

sub lat {
  my $self=shift;
  $self->{'lat'}=shift if @_;
  return $self->{'lat'};
}

=head2 lon, long, longitude

Sets or returns Longitude (float, degrees)

  print $obj->lon, "\n";

=cut

*longitude=\&lon;
*long=\&lon;

sub lon {
  my $self = shift();
  $self->{'lon'}=shift() if @_;
  return $self->{'lon'};
}

=head2 alt, altitude, hae, elevation

Sets or returns Altitude (float, meters) 

  print $obj->alt, "\n";

=cut

*altitude=\&alt;
*hae=\&alt;
*elevation=\&alt;

sub alt {
  my $self = shift();
  $self->{'alt'}=shift() if @_;
  return $self->{'alt'};
}

=head2 speed

Sets or returns speed (float, meters/sec)

  print $obj->speed, "\n";

=cut

sub speed {
  my $self = shift();
  $self->{'speed'}=shift() if @_;
  return $self->{'speed'};
}

=head2 heading, bearing

Sets or returns heading (float, degrees)

  print $obj->heading, "\n";

=cut

*bearing=\&heading;

sub heading {
  my $self = shift();
  $self->{'heading'}=shift() if @_;
  return $self->{'heading'};
}

=head2 climb

Sets or returns vertical velocity (float, meters/sec)

  print $obj->climb, "\n";

=cut

sub climb {
  my $self = shift();
  $self->{'climb'}=shift() if @_;
  return $self->{'climb'};
}

=head2 etime

Sets or returns estimated timestamp error (float, seconds, 95% confidence)

  print $obj->etime, "\n";

=cut

sub etime {
  my $self = shift();
  $self->{'etime'}=shift() if @_;
  return $self->{'etime'};
}

=head2 ehorizontal

Sets or returns horizontal error estimate (float, meters)

  print $obj->ehorizontal, "\n";

=cut

sub ehorizontal {
  my $self = shift();
  $self->{'ehorizontal'}=shift() if @_;
  return $self->{'ehorizontal'};
}

=head2 evertical

Sets or returns vertical error estimate (float, meters)

  print $obj->evertical, "\n";

=cut

sub evertical {
  my $self = shift();
  $self->{'evertical'}=shift() if @_;
  return $self->{'evertical'};
}

=head2 espeed

Sets or returns error estimate for speed (float, meters/sec, 95% confidence)

  print $obj->espeed, "\n";

=cut

sub espeed {
  my $self = shift();
  $self->{'espeed'}=shift() if @_;
  return $self->{'espeed'};
}

=head2 eheading

Sets or returns error estimate for course (float, degrees, 95% confidence)

  print $obj->eheading, "\n";

=cut

sub eheading {
  my $self = shift();
  $self->{'eheading'}=shift() if @_;
  return $self->{'eheading'};
}

=head2 eclimb

Sets or returns Estimated error for climb/sink (float, meters/sec, 95% confidence)

  print $obj->eclimb, "\n";

=cut

sub eclimb {
  my $self = shift();
  $self->{'eclimb'}=shift() if @_;
  return $self->{'eclimb'};
}

=head2 mode

Sets or returns the NMEA mode (integer; undef=>no mode value yet seen, 1=>no fix, 2=>2D, 3=>3D)

  print $obj->mode, "\n";

=cut

sub mode {
  my $self = shift();
  $self->{'mode'}=shift() if @_;
  return $self->{'mode'};
}

=head2 tag

Sets or returns a tag identifying the last sentence received. For NMEA devices this is just the NMEA sentence name; the talker-ID portion may be useful for distinguishing among results produced by different NMEA talkers in the same wire. (string)

  print $obj->tag, "\n";

=cut

sub tag {
  my $self = shift();
  $self->{'tag'}=shift() if @_;
  return $self->{'tag'};
}

=head1 METHODS (Value Added)

=head2 fix

Returns either 1 or 0 based upon if the GPS point is from a valid fix or not.

  print $obj->fix, "\n";

At a minimum this method requires mode to be set.

=cut

sub fix {
  my $self=shift;
  if (defined($self->mode) and $self->mode > 1) {
    return 1;
  } else {
    return 0;
  }
}

=head2 datetime

Returns a L<DateTime> object from time

  my $dt=$point->datetime;

At a minimum this method requires time to be set.

=cut

sub datetime {
  my $self=shift;
  eval 'use DateTime';
  if ($@) {
    die("Error: The datetime method requires DateTime");
  } else {
    return DateTime->from_epoch(epoch=>$self->time); 
  }
}

=head2 latlon, latlong

Returns Latitude, Longitude as an array in array context and as a space joined string in scalar context

  my @latlon=$point->latlon;
  my $latlon=$point->latlon;

At a minimum this method requires lat and lon to be set.

=cut

*latlong=\&latlon;

sub latlon {
  my $self = shift();
  my @latlon=($self->lat, $self->lon);
  return wantarray ? @latlon : join(" ", @latlon);
}

=head2 setAltitude

Sets altitude from USGS web service and then returns the GPS::Point object.  This method is a wrapper around L<Geo::WebService::Elevation::USGS>.

  my $point=GPS::Point->new(lat=>$lat, lon=>$lon)->setAltitude;
  $point->setAltitude;
  my $alt=$point->alt;

At a minimum this method requires lat and lon to be set and alt to be undef.

=cut

sub setAltitude {
  my $self=shift;
  unless (defined $self->alt) {
    eval 'use Geo::WebService::Elevation::USGS';
    if ($@) {
      die("Error: The setAltitude method requires Geo::WebService::Elevation::USGS");
    } else {
      my $eq=Geo::WebService::Elevation::USGS->new(units=>"METERS", croak=>0);
      my $return=$eq->getElevation($self); #Assume this is HAE WGS-84
      $self->alt($return->{'Elevation'}) if ref($return) eq "HASH";
    }
  }
  return $self;
}

=head2 ecef

Returns ECEF coordinates. This method is a wrapper around L<Geo::ECEF>.

  my ($x,$y,$z) = $point->ecef;
  my @xyz       = $point->ecef;
  my $xyz_aref  = $point->ecef; #if Geo::ECEF->VERSION >= 0.08

At a minimum this method requires lat and lon to be set. (alt of 0 is assumed by Geo::ECEF->ecef).

=cut

sub ecef {
  my $self=shift;
  eval 'use Geo::ECEF';
  die("Error: The ecef method requires Geo::ECEF") if $@;
  die("Error: The found geo::ecef not Geo::ECEF.") unless Geo::ECEF->can("new");
  my $obj=Geo::ECEF->new;
  return $obj->ecef($self->lat, $self->lat, $self->alt);
}

=head2 GeoPoint

Returns a L<Geo::Point> Object in the WGS-84 projection.

  my $GeoPointObject = $point->GeoPoint;

At a minimum this method requires lat and lon to be set.

=cut

sub GeoPoint {
  my $self = shift();
  eval 'use Geo::Point';
  if ($@) {
    die("Error: The GeoPoint method requires Geo::Point");
  } else {
    return Geo::Point->new(lat=>$self->lat, long=>$self->lon, proj=>'wgs84');
  }
}

=head2 distance

Returns distance in meters between the object point and the argument point. The argument can be any valid argument of newMulti constructor.  This method is a wrapper around Geo::Inverse.

  my ($faz, $baz, $dist) = $point->distance($pt2); #Array context
  my $dist = $point->distance($lat, $lon);  #if Geo::Inverse->VERSION >=0.05 

At a minimum this method requires lat and lon to be set.

=cut

sub distance {
  my $self=shift;
  my $point=$_[0];
  $point=GPS::Point->newMulti(@_) unless ref($point) eq "GPS::Point";
  if (defined $point) {
    eval 'use Geo::Inverse';
    if ($@) {
      die("Error: The distance method requires Geo::Inverse");
    } else {
      my $gi=Geo::Inverse->new;
      return $gi->inverse($self->latlon, $point->latlon);
    }
  } else {
    die(qq{Error: Could not create point from parameters.});
  }
}

=head2 track

Returns a point object at the predicted location in time seconds assuming constant velocity. Using L<Geo::Forward> calculation.

  my $new_point=$point->track($seconds); #default $point->heading
  my $new_point=$point->track($seconds => $heading);

At a minimum this method requires lat and lon to be set. It might be very useful to have speed, heading and time set although they all default to zero.

=cut

sub track {
  my $self=shift;
  my $seconds=shift||0;        #seconds
  my $heading=shift;           #degrees
  $heading=$self->heading || 0 unless defined $heading; #support 0 degrees passed
  my $speed=$self->speed || 0; #m/s
  my $dist=$speed * $seconds;  #meters
  my $point=$self->forward($dist => $heading);
  $point->time(($self->time||0) + $seconds);
  return $point;
}

=head2 forward

Returns a point object at the distance and heading using L<Geo::Forward> calculations.

  my $point=$point->forward($dist);             #default $point->heading
  my $point=$point->forward($dist => $heading); #meters => degrees

At a minimum this method requires lat and lon to be set. It might be useful to have heading set although the default is zero.

=cut

sub forward {
  my $self=shift;
  my $dist=shift || 0; #meters
  my $faz=shift;       #degrees
  $faz=$self->heading || 0 unless defined $faz;
  eval 'use Geo::Forward';
  if ($@) {
    die("Error: The track method requires Geo::Forward");
  } else {
    my $gf=Geo::Forward->new;
    my ($lat2,$lon2,$baz) = $gf->forward($self->latlon, $faz, $dist);
    my $point=GPS::Point->new(%$self);
    $point->lat($lat2);
    $point->lon($lon2);
    return $point;
  }
}

=head2 buffer

Returns a list of L<GPS::Point> objects equidistant from the current object location.

  my @buffer=$point->buffer($radius_meters, $sections); #returns (GPS::Point, GPS::Point, ...)
  my $buffer=$point->buffer($radius_meters, $sections); #returns [GPS::Point, GPS::Point, ...]

=cut

sub buffer {
  my $self=shift;
  my $radius=shift; #meters
  my $sections=shift || 60; #60 sections = 61 verticies
  my @buffer=();
  my $arc=360/$sections; #not zero!
  foreach my $step (0 .. $sections) {
    my $angle=$arc * $step;

    push @buffer, $self->forward($radius => $angle);
  }
  return wantarray ? @buffer : \@buffer;
}

sub _q2u {
  my $a=shift();
  return $a eq '?' ? undef() : $a;
}

=head1 BUGS

Please log on RT and send email to GPSD-DEV or GEO-PERL email lists.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com
  account=>perl,tld=>com,domain=>michaelrdavis
  http://www.davisnetworks.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::Point>, L<Net::GPSD>, L<Net::GPSD::Point>, L<Geo::ECEF>, L<Geo::Functions>, L<Geo::Forward>, L<Geo::Inverse>, L<Geo::Distance>, L<Geo::Ellipsoids>, L<Geo::WebService::Elevation::USGS>, L<DateTime>

=cut

1;
