package Location::Area::DoCoMo::iArea;

################################
#
#  DoCoMo Functions for iArea
#  Location::Area::DoCoMo::iArea
#  

use 5.008;
use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD $useAdjustedAura);
$VERSION = 2.10;

use Carp;
use Location::GeoTool;
use Location::GeoTool::Aura;
use Location::Area::DoCoMo::iArea::Area;
require Location::Area::DoCoMo::iArea::Region;
require Location::Area::DoCoMo::iArea::Next;

__PACKAGE__->_make_accessors(
  qw(areaid sub_areaid name meshcache)
);

################################################################
# Constructor                  #
################################

sub import
{
  my $caller = shift;
  $useAdjustedAura = 0;
  foreach (@_)
  {
    $useAdjustedAura = 1 if ($_ =~ /useAdjustedAura/);
  }
}

################################
# From iArea code

sub create_iarea
{
  my $class = shift;
  my ($area,$sub_area) = @_;

  if ($area =~ /^(\d{3})(\d{2})$/)
  {
    $area = $1;
    $sub_area = $2;
  }
  elsif (!(($area =~ /^\d{3}$/) && ($sub_area =~ /^\d{2}$/)))
  {
    return undef;
  }

  return bless Location::Area::DoCoMo::iArea::Area->seek("$area$sub_area",$useAdjustedAura),$class;
}

################################
# From coordinate

sub create_coord
{
  my $class = shift;
  my $mesh = $class->calcurate_mesh(@_);
  return bless Location::Area::DoCoMo::iArea::Area->seek($mesh,$useAdjustedAura),$class;
}

sub include_area
{
  my $self = shift;
  my $mesh = $self->calcurate_mesh(@_);
  my ($m2,$m3,$m4,$m5,$m6,$m7) = $mesh =~ /^(\d{6})(\d?)(\d?)(\d?)(\d?)(\d?)$/;
  return $self->meshcache =~ /,(${m2}(${m3}(${m4}(${m5}(${m6}${m7}?)?)?)?)?),/ ? 1 : 0;
}

sub calcurate_mesh
{
  my $class = shift;
  my ($lat,$lon,$usetokyo,$format) = @_;

  if (UNIVERSAL::isa($lat, 'Location::GeoTool'))
  {
    ($lat,$lon) = $lat->datum_tokyo->format_second->array;
  }
  else
  {
    my $datum = $usetokyo || 'wgs84';
    $datum = 'tokyo' if ($datum eq '1');
    $format ||= 'spacetag';
    ($lat,$lon) = Location::GeoTool->create_coord($lat,$lon,$datum,$format)->datum_tokyo->format_second->array;
  }

  ($lat,$lon) = map { int ($_ * 1000) } ($lat,$lon);

  my @mesh = ();
  my $ab = int($lat / 2400000);
  my $cd = int($lon / 3600000) - 100;
  my $x1 = ($cd +100) * 3600000;
  my $y1 = $ab * 2400000;
  my $e = int(($lat - $y1) / 300000);
  my $f = int(($lon - $x1) / 450000);
  $mesh[0] = $ab.$cd.$e.$f;
  my $x2 = $x1 + $f * 450000;
  my $y2 = $y1 + $e * 300000;
  my $l3 = int(($lon - $x2) / 225000);
  my $m3 = int(($lat - $y2) / 150000);
  my $g = $l3 + $m3 * 2;
  $mesh[1] = $mesh[0].$g;  
  my $x3 = $x2 + $l3 * 225000;
  my $y3 = $y2 + $m3 * 150000;
  my $l4 = int(($lon - $x3) / 112500);
  my $m4 = int(($lat - $y3) / 75000);
  my $h = $l4 + $m4 * 2;
  $mesh[2] = $mesh[1].$h;  
  my $x4 = $x3 + $l4 * 112500;
  my $y4 = $y3 + $m4 * 75000;
  my $l5 = int(($lon - $x4) / 56250);
  my $m5 = int(($lat - $y4) / 37500);
  my $i = $l5 + $m5 * 2;
  $mesh[3] = $mesh[2].$i;  
  my $x5 = $x4 + $l5 * 56250;
  my $y5 = $y4 + $m5 * 37500;
  my $l6 = int(($lon - $x5) / 28125);
  my $m6 = int(($lat - $y5) / 18750);
  my $j = $l6 + $m6 * 2;
  $mesh[4] = $mesh[3].$j;
  my $x6 = $x5 + $l6 * 28125;
  my $y6 = $y5 + $m6 * 18750;
  my $l7 = int(($lon - $x6) / 14062.5);
  my $m7 = int(($lat - $y6) / 9375);
  my $k = $l7 + $m7 * 2;
  $mesh[5] = $mesh[4].$k;

  return $mesh[5];
}

################################################################
# Fields                       #
################################

################################
# Construct accessor methods

sub _make_accessors 
{
  my($class, @attr) = @_;
  for my $attr (@attr) {
    no strict 'refs';
    *{"$class\::$attr"} = sub { shift->{$attr} };
  }
}

################################
# Accessor method for full areaid

sub full_areaid {$_[0]->id}
sub id{ $_[0]->areaid().$_[0]->sub_areaid() }

sub prefecture
{
  my $self = shift;
  unless ($self->{prefecture})
  {
    ($self->{region},$self->{prefecture}) = Location::Area::DoCoMo::iArea::Region->seek($self->{areaid},$self->{sub_areaid});
  }
  return $self->{prefecture};
}

sub region
{
  my $self = shift;
  unless ($self->{region})
  {
    ($self->{region},$self->{prefecture}) = Location::Area::DoCoMo::iArea::Region->seek($self->{areaid},$self->{sub_areaid});
  }
  return $self->{region};
}

################################################################
# Methods                      #
################################

################################
# Get new Location::Area::DoCoMo::iArea objects which next to this area

sub get_nextarea
{
  my $self = shift;
  my $next = Location::Area::DoCoMo::iArea::Next->seek($self->{areaid},$self->{sub_areaid});

  my @nextareas = ();
  foreach my $s (@$next)
  {
    $s =~ s/\-//;
    my $tmpobj = Location::Area::DoCoMo::iArea->create_iarea($s);
    push (@nextareas,$tmpobj);
  }
  return wantarray() ? @nextareas : \@nextareas;
}

################################
# Get Location::GeoTool::Aura object of this area's aura

sub get_aura
{
  Location::GeoTool::Aura->create_vertex(map {$_[0]->$_} ('sw','se','nw','ne'));
}

################################
# Get Location::GeoTool object of center point of this area's aura

sub get_center
{
  $_[0]->get_aura->get_center;
}

################################
# For internal use: Get Location::GeoTool object of each vertex of area's aura

sub sw{$_[0]->{'sw'} ||= Location::GeoTool->create_coord($_[0]->{"south"}/1000,$_[0]->{"west"}/1000,'tokyo','second')}
sub se{$_[0]->{'se'} ||= Location::GeoTool->create_coord($_[0]->{"south"}/1000,$_[0]->{"east"}/1000,'tokyo','second')}
sub nw{$_[0]->{'nw'} ||= Location::GeoTool->create_coord($_[0]->{"north"}/1000,$_[0]->{"west"}/1000,'tokyo','second')}
sub ne{$_[0]->{'ne'} ||= Location::GeoTool->create_coord($_[0]->{"north"}/1000,$_[0]->{"east"}/1000,'tokyo','second')}

################################################################
# Legacy                       #
################################

sub setArea{shift->create_iarea(@_)}
sub setCoordinate{shift->create_coord(@_)}
sub getNextArea{shift->get_nextarea(@_)}
sub getAura
{
  my ($self,$usetokyo) = @_;
  my $datum;
  $datum = $usetokyo ? 'datum_tokyo' : 'datum_wgs84';

  return $self->get_aura->$datum->format_spacetag->array;
}

1;
__END__

=head1 NAME

Location::Area::DoCoMo::iArea - Get NTT DoCoMo's i-Area from i-Area code or Geo coordinate

=head1 SYNOPSIS

  use Location::Area::DoCoMo::iArea;
  # Or, if you want to use adjusted Aura data,
  use Location::Area::DoCoMo::iArea qw(useAdjustedAura);

  #Create object

  # Get i-Area object from Geo coordinate at WGS84 Datum
  $oiArea = Location::Area::DoCoMo::iArea->create_coord("34/20/39.933","135/21/51.826","tokyo","mapion");
  # or 
  $oiArea = Location::Area::DoCoMo::iArea->create_coord("342039.933","1352151.826","wgs84","dmsn");

  # Get i-Area object from full area code
  $oiArea = Location::Area::DoCoMo::iArea->create_iarea("152","00");
  # or same
  $oiArea = Location::Area::DoCoMo::iArea->create_iarea("15200");

  #Get data

  # Get full area code (5digit)
  my $fid = $oiArea->full_areaid();
  # Get main area code (3digit)
  my $pid = $oiArea->areaid();
  # Get sub area code (2digit)
  my $sid = $oiArea->sub_areaid();

  # Get area name (at EUC-JP character code)
  my $name = $oiArea->name();
  # Get prefecture name of this area (at EUC-JP character code)
  my $pref = $oiArea->prefecture();
  # Get region name of this area (at EUC-JP character code)
  my $reg = $oiArea->region();

  # Get aura (boundary square of area) object (Location::GeoTool::Aura)
  my $oAura = $oiArea->get_aura;
  # Get south, west, north, east limit of this area at WGS84 datum, gpsOne format
  my ($slim,$wlim,$nlim,$elim) = $oAura->datum_wgs84->format_gpsone->array;
  # Or at TOKYO datum, degree
  my ($slim,$wlim,$nlim,$elim) = $oAura->datum_tokyo->format_degree->array;

  # Get Aura's center point object (Location::GeoTool)
  my ($clat,$clong) = $oiArea->get_center->array;

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=head3 create_coord

Create Location::Area::DoCoMo::iArea object from coordinate.

  Usage:
    $obj = Location::Area::DoCoMo::iArea->create_coord($lat,$lon,$datum,$format);
  Arguments:
    $lat   : Latitude (North are Positive).
    $lon   : Longitude (East are Positive).
    $datum : Specify datum of $lat/$long. (See Location::GeoTool)
    $format: Specify format of $lat/$long. (See Location::GeoTool)

  or another way,

  Usage:
    $obj = Location::Area::DoCoMo::iArea->create_coord($point);
  Arguments:
    $point : Object of Location::GeoTool.

  Return Values:
    $obj   : Location::Area::DoCoMo::iArea object. undef if can't bind coordinate to area.

=head3 create_iarea

Create Location::Area::DoCoMo::iArea object from full area code.

  Usage:
    $obj = Location::Area::DoCoMo::iArea->create_iarea($id,$sid);
  Arguments:
    $id    : Set full area code or main area code
    $lon   : Set sub area code (needed if you give main area code as $id)
  Return Values:
    $obj   : Location::Area::DoCoMo::iArea object. undef if can't bind code to area.

=head2 FIELDS

=head3 full_areaid

=head3 areaid

=head3 sub_areaid

Each fields return full area code, main area code or sub area code.

=head3 name

=head3 prefecture

=head3 region

Each fields return area name, prefecture name of this area or region name of this area.
Each return values are described in EUC-JP character code.

=head2 METHODS

=head3 include_area

Check the point is included current area or not.

  Usage:
    $is_include = $obj->include_area($lat,$lon,$datum,$format);
    # or
    $is_include = $obj->include_area($point);

  Return Values:
    $is_include : Return 1 if included, 0 if not.

=head3 get_aura

Get aura (boundary square of area) object - Location::GeoTool::Aura.

  Usage:
    $oAura = $obj->get_aura;

The way to use Location::GeoTool::Aura object is like below:

 #Specify datum or format:
   $oAura->datum_wgs84->format_degree...
  Names of methods are same with Location::GeoTool.

 #Get boundary latitude/longitude array:
   ($sbound,$wbound,$nbound,$ebound) = $oAura->......->array;

  Notice:
    NTT DoCoMo's aura data contains a lot of inconsistencies.
    There are differents between Aura boundary square, which is
    defined by DoCoMo's summary data, and that is calcurated
    from mesh data.

    So, I add adjusted aura data which are calcurated from mesh,
    you can use it.
    If you want, you should use this module like this:
     
     use Location::Area::DoCoMo::iArea qw(useAdjustedAura);
    
=head3 get_center

Get aura's center point by Location::GeoTool object.

  Usage:
    $cpoint = $obj->get_center;

To get coordinate of center point, like below:

   ($clat,$clong) = $cpoint->datum_wgs84->format_degree->array;

=head3 get_nextarea

  Get i-Area object list which are next to this area.

  Usage:
    @next = $obj->getNextArea;
  Return Values:
    @next  : i-Area object list of areas next to this area.
  Notice:
   1.If there is the sea between one area and another, they are not next area.
     This definition is based on NTT DoCoMo's.
   2.DoCoMo's official data contains a lot of inconsistencies.
     So, this module adjusts them.

=head1 DEPENDENCIES

 Carp
 Location::GeoTool

=head1 SEE ALSO

 i-Area data in this version is based on NTT DoCoMo's data, publicated in Mar. 29th, 2004.
 You can get original data on 
 http://www.nttdocomo.co.jp/p_s/imode/iarea/iareadata040329.lzh.
 And, next area data is based on NTT DoCoMo's web site,
 http://www.nttdocomo.co.jp/p_s/imode/iarea/iareaweb/iarea_contents.html.
 You should see these site.

 Support this module in Kokogiko! web site : http://kokogiko.net/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Kokogiko!,
And, latest data updating is based on Mr. Kunihiko Miyanaga(ideaman's Inc. 
http://www.ideamans.com/)'s work.
Thank you!

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
