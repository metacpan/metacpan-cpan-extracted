#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-12-01
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package GD::Sparkline;
use strict;
use warnings;
use GD;
use base qw(Class::Accessor);
use Readonly;
use Math::Bezier;

Readonly::Scalar our $H => 20;        # Height
Readonly::Scalar our $W => 80;        # Width
Readonly::Scalar our $T => 'b';       # Chart type
Readonly::Scalar our $B => q[FFFFFF]; # Background
Readonly::Scalar our $A => q[80D7B7]; # Area colour
Readonly::Scalar our $L => q[000000]; # Line colour
Readonly::Scalar our $BEZ_REZ => 10;

our $VERSION = q[0.05];

__PACKAGE__->mk_accessors(__PACKAGE__->fields());

sub fields {
  return qw(p s h w b a l t);
}

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;
  return $ref;
}

sub draw { ## no critic (ProhibitExcessComplexity)
  my $self   = shift;
  my $raw    = $self->p();
  my $series = $self->s();
  my $p      = [];
  my ($min, $max);

  if($raw) {
    $p = [map { ## no critic (ProhibitComplexMappings)
      if(!defined $min || $_<$min){
	$min=$_;
      }

      if(!defined $max || $_>$max){
	$max=$_;
      }

      $_;
    } unpack q[C]x(length $raw), ($raw || q[])];

  } elsif($series) {
    $p = [map { ## no critic (ProhibitComplexMappings)
      if(!defined $min || $_<$min){
	$min=$_;
      }

      if(!defined $max || $_>$max){
	$max=$_;
      }

      $_;
    } split /,/smx, $series];
  }

  my $h     = $self->h || $H;
  my $w     = $self->w || $W;
  my $gd    = GD::Image->newTrueColor($w, $h);
  my $b_str = $self->b;

  if($b_str eq 'transparent') {
    $b_str = 'ffffff';
  }

  my $bg   = $gd->colorAllocate(map { hex $_ } unpack 'A2A2A2', $b_str || $B);
  my $area = $gd->colorAllocate(map { hex $_ } unpack 'A2A2A2', $self->a || $A);
  my $line = $gd->colorAllocate(map { hex $_ } unpack 'A2A2A2', $self->l || $L);

  if($self->b eq 'transparent') {
    $gd->transparent($bg);
  }

  $gd->filledRectangle(0,0, $w,$h, $bg);

  my $type = $self->t || $T;
  my $func = "type_$type";

  if($self->can($func)) {
    $self->$func($gd, $p,
		 {
		  min => $min,
		  max => $max,
		 },
		 {
		  line => $line,
		  area => $area,
		  h    => $h,
		  w    => $w,
		 });
  }

  return $gd->png();
}

sub type_b {
  my ($self, $gd, $p, $data_attrs, $chart_attrs) = @_;
  my $min  = $data_attrs->{min};
  my $max  = $data_attrs->{max};
  my $line = $chart_attrs->{line};
  my $area = $chart_attrs->{area};
  my $h    = $chart_attrs->{h} || $H;
  my $w    = $chart_attrs->{w} || $W;

  my $dy     = 0+$max-$min;
  my $dx     = scalar @{$p} - 1;
  my $scaley = $h/($dy||1);
  my $scalex = $w/($dx||1);
  my $pos    = 0;

  my $lastx = 0;
  my @controls;

  for my $d (@{$p}) {
    my $y = $h-($d-$min)*$scaley;
    my $x = $pos*$scalex;

    push @controls, ($x, $y);
    $pos++;
  }

  my $bezier  = Math::Bezier->new(@controls);
  my $pointsa = $bezier->curve($w);#10000);#$w/$BEZ_REZ);
  my $pointsl = [@{$pointsa}];

  my ($lx, $ly) = splice @{$pointsa}, 0, 2;
  while(scalar @{$pointsa}) {
    my ($x, $y) = splice @{$pointsa}, 0, 2;

    my $poly = GD::Polygon->new;
    $poly->addPt($lx, $ly);
    $poly->addPt($lx, $h);
    $poly->addPt($x, $h);
    $poly->addPt($x, $y);
    $gd->filledPolygon($poly, $area);
    $lx = $x;
    $ly = $y;
  }

  ($lx, $ly) = splice @{$pointsl}, 0, 2;
  $gd->setAntiAliased($line);

  while(scalar @{$pointsl}) {
    my ($x, $y) = splice @{$pointsl}, 0, 2;

    $gd->line($lx, $ly, $x, $y, gdAntiAliased);
    $lx = $x;
    $ly = $y;
  }

  return 1;
}

1;
__END__

=head1 NAME

GD::Sparkline

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  my $oSpark = GD::Sparkline->new({
                                   s => q[10,10,20,50,60,80,100,400,100,80,40,30,15,15,15],
                                  });
  print $oSpark->draw();

=head1 DESCRIPTION

 Draw simple graphs using the magic of GD and Math::Bezier

=head1 SUBROUTINES/METHODS

=head2 fields - an array of available fields:

  my @aFields = GD::Sparkline->fields();

  p - raw data in ASCII
  s - series data in comma-separated decimal
  h - height of image in pixels, default 20
  w - width of image in pixels, default 80
  b - background colour in 6-digit hex or 'transparent', default FFFFFF
  a - area colour in 6-digit hex
  l - line colour in 6-digit hex
  t = b - bezier

 All are also available as get/set accessors

=head2 new - object constructor

  my $oSpark = GD::Sparkline->new({
                                   <fieldname> => <value>
                                   ...
                                  });

=head2 draw - generate and return PNG image from the dataset

  my $sPNG = $oSpark->draw();

=head2 type_b - handling for bezier charts

  $oSparkline->type_b($gd, $arDataPoints,
                      { min  => $iMin, max => $iMax },
                      { h    => $iHeight, w => $iWidth
                        line => $oGDLineColour, area => $oGDAreaColour });

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item GD

=item base

=item Class::Accessor

=item Readonly

=item Math::Bezier

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
