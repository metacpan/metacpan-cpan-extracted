#!/usr/bin/perl
use warnings;
use strict;

=head1 NAME

Geo-GoogleEarth-Pluggable-Plugin-Styles-Example.pl - Geo-GoogleEarth-Pluggable Style Plugin Examples

=cut

use Geo::GoogleEarth::Pluggable;
use DateTime;

my $document=Geo::GoogleEarth::Pluggable->new(name=>"Style Examples ". DateTime->now, open=>1);
my $point=MyPoint->new;
my $points=$document->Folder(name=>"Points ". DateTime->now);
my $lines=$document->Folder(name=>"Lines ". DateTime->now);
my $polygons=$document->Folder(name=>"Polygons ". DateTime->now);


#Red
$points->Point(name=>"IconStyleRedDot", $point->next, 
               style=>$document->IconStyleRedDot);
$lines->LineString(name=>"LineStyleRed", coordinates=>$point->line,
                   style=>$document->LineStyleRed(width=>3));
$polygons->LinearRing(name=>"PolyStyleRed", coordinates=>$point->poly,
                      style=>$document->PolyStyleRed(alpha=>"65%"));
#Orange
$points->Point(name=>"IconStyleOrangeDot", $point->next, 
               style=>$document->IconStyleOrangeDot);
$lines->LineString(name=>"LineStyleOrange", coordinates=>$point->line,
                   style=>$document->LineStyleOrange(width=>3));
$polygons->LinearRing(name=>"PolyStyleOrange", coordinates=>$point->poly,
                      style=>$document->PolyStyleOrange(alpha=>"65%"));
#Yellow
$points->Point(name=>"IconStyleYellowDot", $point->next, 
               style=>$document->IconStyleYellowDot);
$lines->LineString(name=>"LineStyleYellow", coordinates=>$point->line,
                   style=>$document->LineStyleYellow(width=>3));
$polygons->LinearRing(name=>"PolyStyleYellow", coordinates=>$point->poly,
                      style=>$document->PolyStyleYellow(alpha=>"65%"));
#Green
$points->Point(name=>"IconStyleGreenDot", $point->next, 
               style=>$document->IconStyleGreenDot);
$lines->LineString(name=>"LineStyleGreen", coordinates=>$point->line,
                   style=>$document->LineStyleGreen(width=>3));
$polygons->LinearRing(name=>"PolyStyleGreen", coordinates=>$point->poly,
                      style=>$document->PolyStyleGreen(alpha=>"65%"));
#Blue
$points->Point(name=>"IconStyleBlueDot", $point->next, 
               style=>$document->IconStyleBlueDot);
$lines->LineString(name=>"LineStyleBlue", coordinates=>$point->line,
                   style=>$document->LineStyleBlue(width=>3));
$polygons->LinearRing(name=>"PolyStyleBlue", coordinates=>$point->poly,
                      style=>$document->PolyStyleBlue(alpha=>"65%"));
#Purple
$points->Point(name=>"IconStylePurpleDot", $point->next, 
               style=>$document->IconStylePurpleDot);
$lines->LineString(name=>"LineStylePurple", coordinates=>$point->line,
                   style=>$document->LineStylePurple(width=>3));
$polygons->LinearRing(name=>"PolyStylePurple", coordinates=>$point->poly,
                      style=>$document->PolyStylePurple(alpha=>"65%"));
#White
$points->Point(name=>"IconStyleWhiteDot", $point->next, 
               style=>$document->IconStyleWhiteDot);
$lines->LineString(name=>"LineStyleWhite", coordinates=>$point->line,
                   style=>$document->LineStyleWhite(width=>3));
$polygons->LinearRing(name=>"PolyStyleWhite", coordinates=>$point->poly,
                      style=>$document->PolyStyleWhite(alpha=>"65%"));
#Gray
$points->Point(name=>"IconStyleGrayDot", $point->next, 
               style=>$document->IconStyleGrayDot);
$lines->LineString(name=>"LineStyleGray", coordinates=>$point->line,
                   style=>$document->LineStyleGray(width=>3));
$polygons->LinearRing(name=>"PolyStyleGray", coordinates=>$point->poly,
                      style=>$document->PolyStyleGray(alpha=>"65%"));
#Black
$points->Point(name=>"IconStyleBlackDot", $point->next, 
               style=>$document->IconStyleBlackDot);
$lines->LineString(name=>"LineStyleBlack", coordinates=>$point->line,
                   style=>$document->LineStyleBlack(width=>3));
$polygons->LinearRing(name=>"PolyStyleBlack", coordinates=>$point->poly,
                      style=>$document->PolyStyleBlack(alpha=>"65%"));

#Default Stick Pin Icons

$points->Point(name=>"IconStyleRed", $point->next, 
               style=>$document->IconStyleRed);
$points->Point(name=>"IconStyleOrange", $point->next, 
               style=>$document->IconStyleOrange);
$points->Point(name=>"IconStyleYellow", $point->next, 
               style=>$document->IconStyleYellow);
$points->Point(name=>"IconStyleGreen", $point->next, 
               style=>$document->IconStyleGreen);
$points->Point(name=>"IconStyleBlue", $point->next, 
               style=>$document->IconStyleBlue);
$points->Point(name=>"IconStylePurple", $point->next, 
               style=>$document->IconStylePurple);
$points->Point(name=>"IconStyleWhite", $point->next, 
               style=>$document->IconStyleWhite);
$points->Point(name=>"IconStyleGray", $point->next, 
               style=>$document->IconStyleGray);
$points->Point(name=>"IconStyleBlack", $point->next, 
               style=>$document->IconStyleBlack);

#Paddles and Line Widths

$points->Point(name=>"IconStylePaddle", $point->next, 
               style=>$document->IconStylePaddle);
$lines->LineString(name=>"LineStyleRed-50-1", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>"50%",width=>1));
$points->Point(name=>"IconStylePaddleA", $point->next, 
               style=>$document->IconStylePaddle("A"));
$lines->LineString(name=>"LineStyleRed-50-2", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>"50%",width=>2));
$points->Point(name=>"IconStylePaddleB", $point->next, 
               style=>$document->IconStylePaddle("B"));
$lines->LineString(name=>"LineStyleRed-50-3", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>"50%",width=>3));
$points->Point(name=>"IconStylePaddleC", $point->next, 
               style=>$document->IconStylePaddle("C"));
$lines->LineString(name=>"LineStyleRed-50-4", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>50/100*255,width=>4));
$points->Point(name=>"IconStylePaddleD", $point->next, 
               style=>$document->IconStylePaddle("D"));
$lines->LineString(name=>"LineStyleRed-50-4.5", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>50/100*255,width=>4.5));
$points->Point(name=>"IconStylePaddleE", $point->next, 
               style=>$document->IconStylePaddle("E"));
$lines->LineString(name=>"LineStyleRed-50-5", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>50/100*255,width=>5));
$points->Point(name=>"IconStylePaddleF", $point->next, 
               style=>$document->IconStylePaddle("F"));
$lines->LineString(name=>"LineStyleRed-50-5.5", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>50/100*255,width=>5.5));
$points->Point(name=>"IconStylePaddleG", $point->next, 
               style=>$document->IconStylePaddle("G"));
$lines->LineString(name=>"LineStyleRed-50-6", coordinates=>$point->line,
                   style=>$document->LineStyleRed(alpha=>50/100*255,width=>6));

print $document->render;

package MyPoint;

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->{"lat"}=39;
  $self->{"lon"}=-77;
  $self->{"delta"}=-0.001;
  return $self;
}

sub next {
  my $self=shift;
  $self->{"lat"}+=$self->{"delta"};
  $self->{"lon"}+=$self->{"delta"};
  return %$self;
}

sub line {
  my $self=shift;
  return [
          {lat=>$self->{"lat"}, lon=>$self->{"lon"}+0.001},
          {lat=>$self->{"lat"}+0.00001, lon=>$self->{"lon"}+0.002},
         ];
}

sub poly {
  my $self=shift;
  return [
          {lat=>$self->{"lat"}+0.001, lon=>$self->{"lon"}-0.001},
          {lat=>$self->{"lat"}+0.002, lon=>$self->{"lon"}-0.002},
          {lat=>$self->{"lat"}+0.001, lon=>$self->{"lon"}+0.000},
          {lat=>$self->{"lat"}+0.001, lon=>$self->{"lon"}-0.001},
         ];
}
