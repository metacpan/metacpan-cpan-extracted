package Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint;
use Geo::Forward;
use warnings;
use strict;

our $VERSION='0.03';

=head1 NAME

Geo::GoogleEarth::Pluggable::Plugin::CircleByCenterPoint - CircleByCenterPoint plugin for Geo::GoogleEarth::Pluggable

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new;
  my $circle=$document->CircleByCenterPoint(%data);
  my $arc=$document->ArcByCenterPoint(%data);

=head1 DESCRIPTION

=head1 USAGE

=head1 METHODS

=head2 CircleByCenterPoint

  my $polygon=$document->CircleByCenterPoint(
                                name       => "My CircleByCenterPoint",
                                radius     => 1000,       #meters
                                lat        =>  38.896079, #WGS-84 degrees
                                lon        => -77.036554, #WGS-84 degrees
                                alt        => 0,      #reference see LookAt
                                deltaAngle => 7.2,    #default
                               );

=cut

sub CircleByCenterPoint {
  my $self=shift; #$self isa Geo::GoogleEarth::Pluggable::Folder object
  my %data=@_;
  $data{"startAngle"} ||= 0;
  $data{"endAngle"} = $data{"startAngle"} + 360;
  return $self->ArcByCenterPoint(%data);
}

=head2 ArcByCenterPoint

  my $polygon=$document->ArcByCenterPoint(
                                name       => "My ArcByCenterPoint",
                                radius     => 500,    #meters
                                startAngle => 33.3,   #degrees CW/North
                                endAngle   => 245.7,  #degrees CW/North
                                deltaAngle => 7.2,    #default
                                lat        => 38.889, #WGS-84 degrees
                                lon        =>-77.035, #WGS-84 degrees
                                alt        => 0,      #reference LookAt
                               );

=cut

sub ArcByCenterPoint {
  my $self=shift; #$self isa Geo::GoogleEarth::Pluggable::Folder object
  my %data=@_;
  $data{"startAngle"} ||= 0;
  $data{"endAngle"}   ||= 180;
  $data{"deltaAngle"} ||= 7.2;
  $data{"deltaAngle"}   = 0.1 if $data{"deltaAngle"} < 0.1;
  $data{"deltaAngle"}   = 90 if $data{"deltaAngle"} > 90;
  my $interpolate       = int(($data{"endAngle"} - $data{"startAngle"})/$data{"deltaAngle"});
  $data{"deltaAngle"}   = ($data{"endAngle"} - $data{"startAngle"})/$interpolate;
  $data{"radius"}       = 1000 unless defined $data{"radius"};
  $data{"alt"}        ||= 0;
  my $coordinates=[];
  my $gf=Geo::Forward->new;
  foreach my $index (0 .. $interpolate) {
    $data{"angle"}=$data{"startAngle"} + $index * $data{"deltaAngle"};
    my ($lat,$lon,$baz)=$gf->forward(@data{qw{lat lon angle radius}});
    push @$coordinates, {lon=>$lon, lat=>$lat, alt=>$data{"alt"}};
  }
  $data{"coordinates"}=$coordinates;
  my $isCircle=abs($data{"endAngle"} - $data{"startAngle"} - 360) <= 0.00001;
  delete(@data{qw{lat lon angle radius alt deltaAngle startAngle endAngle}});
 #use Data::Dumper;
 #print Dumper([\%data]);
  if ($isCircle) {
    return $self->LinearRing(%data);
  } else {
    return $self->LineString(%data);
  }
}

=head2 BoundingBox

  my $box=$folder->BoundingBox(
                                 name => "My Box",
                                 ulat => 39.1,
                                 ulon => -77.1,
                                 llat => 38.9,
                                 llon => -77.3,
                                 alt  => 0
                              );

=cut

sub BoundingBox {
  my $self=shift;
  my %data=@_;
  $data{"alt"} ||= 0;
  $data{"coordinates"}=[
                   {lat=>$data{"ulat"}, lon=>$data{"ulon"}, alt=>$data{"alt"}},
                   {lat=>$data{"llat"}, lon=>$data{"ulon"}, alt=>$data{"alt"}},
                   {lat=>$data{"llat"}, lon=>$data{"llon"}, alt=>$data{"alt"}},
                   {lat=>$data{"ulat"}, lon=>$data{"llon"}, alt=>$data{"alt"}},
                   {lat=>$data{"ulat"}, lon=>$data{"ulon"}, alt=>$data{"alt"}},
                       ];
  delete(@data{qw{ulat ulon llat llon}});
  return $self->LinearRing(%data) 
}

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable>

=cut

1;
