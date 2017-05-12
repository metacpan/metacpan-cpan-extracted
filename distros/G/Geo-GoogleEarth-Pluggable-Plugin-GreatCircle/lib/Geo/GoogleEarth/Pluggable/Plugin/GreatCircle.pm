package Geo::GoogleEarth::Pluggable::Plugin::GreatCircle;
use warnings;
use strict;
use GPS::Point;
use Geo::Forward;
use Geo::Inverse;   #fail at complie time if you don't have it

our $VERSION='0.01';

=head1 NAME

Geo::GoogleEarth::Pluggable::Plugin::GreatCircle - Great Circle plugin for Geo::GoogleEarth::Pluggable

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new;
  my $arc=$document->GreatCircleArcSegment(%data);

=head1 DESCRIPTION

Calculates the Great Circle Arc between two points and creates points in between so that Google Earth can display it as "straight" lines and it still looks like a Great Circle Arc.

=head1 USAGE

=head1 METHODS

=head2 GreatCircleArcSegment

Returns a LineString object.

  my $list=$folder->GreatCircleArcSegment(
                      startPoint=>{lat=>39,lon=>-77}, 
                      endPoint=>{lat=>40,lon=>-76});
  my @list=$folder->GreatCircleArcSegment(
                      name=>"My Great Circle", #name passed through to LineString
                      startPoint=>{lat=>39,lon=>-77}, 
                      endPoint=>{lat=>40,lon=>-76}, 
                      span=>5000);

startPoint and endPoint can be any valid scalar structure supported by GPS::Point->newMulti() constructor

=cut

sub GreatCircleArcSegment {
  my $self=shift; #$self isa Geo::GoogleEarth::Pluggable::Folder object
  my %data=@_;
  my $span=delete($data{"span"})||10000; #meters

  my $pt=[];  #list of GPS::Point objects
  $pt->[0] = GPS::Point->newMulti(delete($data{"startPoint"}));
  my $end  = GPS::Point->newMulti(delete($data{"endPoint"}));

  my ($faz, $baz, $dist)=$pt->[0]->distance($end); #requires Geo::Inverse
  $pt->[0]->heading($faz);
  $end->heading($baz-180);

  my $n=int($dist/$span);
  $n=2 if $n < 2;
  $span=$dist/$n;

  use Geo::Forward;
  my $gf=Geo::Forward->new;
  foreach my $i (1 .. $n-1) {
    my ($lat,$lon,$baz) = $gf->forward($pt->[$i-1]->latlon,$faz,$span);
    $pt->[$i]=GPS::Point->new(lat=>$lat, lon=>$lon);
    $faz=$baz+180;
  }

  $pt->[$n]=$end;
  $data{"coordinates"}=$pt;
  return $self->LineString(%data);
}

=head1 BUGS

Log on RT and send to geo-perl email list

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

=cut

1;
