package GD::SVG;

use strict;
use Carp 'croak','carp','confess';
use SVG;
#use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
require Exporter;

$VERSION = '0.33';
# $Id: SVG.pm,v 1.16 2009/05/10 14:07:17 todd Exp $

# Conditional support for side-by-side raster generation. Off for now.
# Methods that support this are commented out multiple times (ie ######)
use constant USEGD => 0;
if (USEGD) {
  eval "use GD";
}

# A global debug flag which can be overriden by new()
use constant DEBUG => 0;

@ISA = qw(Exporter);
%EXPORT_TAGS = ('cmp'  => [qw(GD_CMP_IMAGE 
			      GD_CMP_NUM_COLORS
			      GD_CMP_COLOR
			      GD_CMP_SIZE_X
			      GD_CMP_SIZE_Y
			      GD_CMP_TRANSPARENT
			      GD_CMP_BACKGROUND
			      GD_CMP_INTERLACE
			      GD_CMP_TRUECOLOR
			     )
			  ]
	       );

@EXPORT = qw(
	     gdStyled
	     gdBrushed
	     gdTransparent
	     gdTinyFont
	     gdSmallFont
	     gdMediumBoldFont
	     gdLargeFont
	     gdGiantFont
	     gdDashSize
	     gdMaxColors
	     gdStyledBrushed
	     gdTiled
	     gdChord
	     gdEdged
	     gdNoFill
	     gdArc
	     gdPie
	    );

# Not yet implemented
#@EXPORT_OK = qw (
#		 GD_CMP_IMAGE 
#		 GD_CMP_NUM_COLORS
#		 GD_CMP_COLOR
#		 GD_CMP_SIZE_X
#		 GD_CMP_SIZE_Y
#		 GD_CMP_TRANSPARENT
#		 GD_CMP_BACKGROUND
#		 GD_CMP_INTERLACE
#		 GD_CMP_TRUECOLOR
#		);


# GD does not allow dynamic creation of fonts. These default values
# are approximate sizes for the various fonts based on an extensive
# afternoon of cross-comparison ;)
use constant DEFAULT_FONT       => 'Helvetica';
use constant TINY_HEIGHT        => 8;
use constant TINY_WIDTH         => 5;
use constant TINY_WEIGHT        => 'normal';
use constant SMALL_HEIGHT       => 11; # originally 12
use constant SMALL_WIDTH        => 6;
use constant SMALL_WEIGHT       => 'normal';
use constant MEDIUM_BOLD_HEIGHT => 13;
use constant MEDIUM_BOLD_WIDTH  => 7;
use constant MEDIUM_BOLD_WEIGHT => 'bold';
use constant LARGE_HEIGHT       => 16;
use constant LARGE_WIDTH        => 8;
use constant LARGE_WEIGHT       => 'normal';
use constant GIANT_HEIGHT       => 15;
use constant GIANT_WIDTH        => 8;
use constant GIANT_WEIGHT       => 'bold';

# TEXT_KLUDGE controls the number of pixels to bump text on the
# Y-axis in order to more closely match GD output.
use constant TEXT_KLUDGE       => '2';

#########################
# END CONSTANTS - No user serviceable options below this point
#########################

# Trap GD methods that are not yet implemented in SVG.pm
sub AUTOLOAD {
  my $self = shift;
  warn "GD method $AUTOLOAD is not implemented in GD::SVG" if ref $self && $self->{debug} > 0;
}

##################################################
# Exported methods that belong in Main namespace #
##################################################

# In GD, the gdStyled method allows one to draw with a styled line
# Here we will simply return the format of the line along with a flag
# so that appropriate subroutines can deal with it.

# Similarly, the gdTransparent method lets users introduce gaps in
# lines. I'll handle it similarly to gdStyled...
# This might just be as simple as setting the color to the background color.
# (This, of course, will not work for styled lines).
sub gdStyled  { return 'gdStyled'; }
sub gdBrushed { return 'gdBrushed'; }
sub gdTransparent { return 'gdTransparent'; }

sub gdStyledBrush { _error('gdStyledBrush'); }
sub gdTiled       { _error('gdTiled'); }
sub gdDashSize    { _error('gdDashSize'); }
sub gdMaxColors   { _error('gdMaxColors'); }

# Bitwise operations for filledArcs
sub gdArc    { return 0; }
sub gdPie    { return 0; }
sub gdChord  { return 1; }
sub gdEdged  { return 4; }
sub gdNoFill { return 2; }

sub gdAntiAliased { _error('gdAntiAliased'); }
sub setAntiAliased { shift->_error('setAntiAliased'); }
sub setAntiAliasedDontBlend { shift->_error('setAntiAliasedDontBlend'); }

################################
# Font Factories and Utilities
################################
sub gdTinyFont {
  my $this = bless {},'GD::SVG::Font';
  $this->{font}   = DEFAULT_FONT;
  $this->{height} = TINY_HEIGHT;
  $this->{width}  = TINY_WIDTH;
  $this->{weight} = TINY_WEIGHT;
  return $this;
}

sub gdSmallFont {
  my $this = bless {},'GD::SVG::Font';
  $this->{font}    = DEFAULT_FONT;
  $this->{height}  = SMALL_HEIGHT;
  $this->{width}   = SMALL_WIDTH;
  $this->{weight}  = SMALL_WEIGHT;
  return $this;
}

sub gdMediumBoldFont {
  my $this = bless {},'GD::SVG::Font';
  $this->{font}   = DEFAULT_FONT;
  $this->{height} = MEDIUM_BOLD_HEIGHT;
  $this->{width}  = MEDIUM_BOLD_WIDTH;
  $this->{weight} = MEDIUM_BOLD_WEIGHT;
  return $this;
}

sub gdLargeFont {
  my $this = bless {},'GD::SVG::Font';
  $this->{font}   = DEFAULT_FONT;
  $this->{height} = LARGE_HEIGHT;
  $this->{width}  = LARGE_WIDTH;
  $this->{weight} = LARGE_WEIGHT;
  return $this;
}

sub gdGiantFont {
  my $this = bless {},'GD::SVG::Font';
  $this->{font}   = DEFAULT_FONT;
  $this->{height} = GIANT_HEIGHT;
  $this->{width}  = GIANT_WIDTH;
  $this->{weight} = GIANT_WEIGHT;
  return $this;
}

# Don't break stuff!
# The can() method is not supported in GD::SVG
# sub can { return 0; }


package GD::SVG::Image;
use Carp 'croak','carp','confess';

# There must be a better way to trap these errors
sub _error {
  my ($self,$method) = @_;
  warn "GD method $method is not implemented in GD::SVG" if ($self->{debug} > 0);
}


#########################
# GD Constants
#########################
# Kludge - use precalculated values of cos(theta) and sin(theta)
# so that I do no have to examine quadrants

my @cosT = (qw/1024 1023 1023 1022 1021 1020 1018 1016 1014 1011 1008
1005 1001 997 993 989 984 979 973 968 962 955 949 942 935 928 920 912
904 895 886 877 868 858 848 838 828 817 806 795 784 772 760 748 736
724 711 698 685 671 658 644 630 616 601 587 572 557 542 527 512 496
480 464 448 432 416 400 383 366 350 333 316 299 282 265 247 230 212
195 177 160 142 124 107 89 71 53 35 17 0 -17 -35 -53 -71 -89 -107 -124
-142 -160 -177 -195 -212 -230 -247 -265 -282 -299 -316 -333 -350 -366
-383 -400 -416 -432 -448 -464 -480 -496 -512 -527 -542 -557 -572 -587
-601 -616 -630 -644 -658 -671 -685 -698 -711 -724 -736 -748 -760 -772
-784 -795 -806 -817 -828 -838 -848 -858 -868 -877 -886 -895 -904 -912
-920 -928 -935 -942 -949 -955 -962 -968 -973 -979 -984 -989 -993 -997
-1001 -1005 -1008 -1011 -1014 -1016 -1018 -1020 -1021 -1022 -1023
-1023 -1024 -1023 -1023 -1022 -1021 -1020 -1018 -1016 -1014 -1011
-1008 -1005 -1001 -997 -993 -989 -984 -979 -973 -968 -962 -955 -949
-942 -935 -928 -920 -912 -904 -895 -886 -877 -868 -858 -848 -838 -828
-817 -806 -795 -784 -772 -760 -748 -736 -724 -711 -698 -685 -671 -658
-644 -630 -616 -601 -587 -572 -557 -542 -527 -512 -496 -480 -464 -448
-432 -416 -400 -383 -366 -350 -333 -316 -299 -282 -265 -247 -230 -212
-195 -177 -160 -142 -124 -107 -89 -71 -53 -35 -17 0 17 35 53 71 89 107
124 142 160 177 195 212 230 247 265 282 299 316 333 350 366 383 400
416 432 448 464 480 496 512 527 542 557 572 587 601 616 630 644 658
671 685 698 711 724 736 748 760 772 784 795 806 817 828 838 848 858
868 877 886 895 904 912 920 928 935 942 949 955 962 968 973 979 984
989 993 997 1001 1005 1008 1011 1014 1016 1018 1020 1021 1022 1023
1023/);

my @sinT = (qw/0 17 35 53 71 89 107 124 142 160 177 195 212 230 247
265 282 299 316 333 350 366 383 400 416 432 448 464 480 496 512 527
542 557 572 587 601 616 630 644 658 671 685 698 711 724 736 748 760
772 784 795 806 817 828 838 848 858 868 877 886 895 904 912 920 928
935 942 949 955 962 968 973 979 984 989 993 997 1001 1005 1008 1011
1014 1016 1018 1020 1021 1022 1023 1023 1024 1023 1023 1022 1021 1020
1018 1016 1014 1011 1008 1005 1001 997 993 989 984 979 973 968 962 955
949 942 935 928 920 912 904 895 886 877 868 858 848 838 828 817 806
795 784 772 760 748 736 724 711 698 685 671 658 644 630 616 601 587
572 557 542 527 512 496 480 464 448 432 416 400 383 366 350 333 316
299 282 265 247 230 212 195 177 160 142 124 107 89 71 53 35 17 0 -17
-35 -53 -71 -89 -107 -124 -142 -160 -177 -195 -212 -230 -247 -265 -282
-299 -316 -333 -350 -366 -383 -400 -416 -432 -448 -464 -480 -496 -512
-527 -542 -557 -572 -587 -601 -616 -630 -644 -658 -671 -685 -698 -711
-724 -736 -748 -760 -772 -784 -795 -806 -817 -828 -838 -848 -858 -868
-877 -886 -895 -904 -912 -920 -928 -935 -942 -949 -955 -962 -968 -973
-979 -984 -989 -993 -997 -1001 -1005 -1008 -1011 -1014 -1016 -1018
-1020 -1021 -1022 -1023 -1023 -1024 -1023 -1023 -1022 -1021 -1020
-1018 -1016 -1014 -1011 -1008 -1005 -1001 -997 -993 -989 -984 -979
-973 -968 -962 -955 -949 -942 -935 -928 -920 -912 -904 -895 -886 -877
-868 -858 -848 -838 -828 -817 -806 -795 -784 -772 -760 -748 -736 -724
-711 -698 -685 -671 -658 -644 -630 -616 -601 -587 -572 -557 -542 -527
-512 -496 -480 -464 -448 -432 -416 -400 -383 -366 -350 -333 -316 -299
-282 -265 -247 -230 -212 -195 -177 -160 -142 -124 -107 -89 -71 -53 -35
-17 /);


#############################
# GD::SVG::Image methods
#############################
sub new {
  my ($self,$width,$height,$debug) = @_;
  my $this = bless {},$self;
  my $img = SVG->new(width=>$width,height=>$height);
  $this->{img}    = [$img];
  $this->{width}  = $width;
  $this->{height} = $height;

  # Let's create an internal representation of the image in GD
  # so that I can easily use some of GD's methods
  ###GD###$this->{gd} = GD::Image->new($width,$height);

  # Let's just assume that we always want the foreground color to be
  # black This, for the most part, works for Bio::Graphics. This
  # certainly needs to be fixed...
  $this->{foreground} = $this->colorAllocate(0,0,0);
  $this->{debug} = ($debug) ? $debug : GD::SVG::DEBUG;
  return $this;
}

sub img {
    my $this = shift;
    return $this->{img}[0];
}

sub currentGroup {
    my $this = shift;
    $this->{currentGroup} = shift if @_;
    return $this->{currentGroup} || $this->{img}[-1];
    return $this->{img}[-1];
}

sub closeAllGroups {
    my $this = shift;
    while (@{$this->{img}}>1) {
	pop @{$this->{img}};
    }
}


#############################
# Image Data Output Methods #
#############################
sub svg {
  my $self = shift;
  $self->closeAllGroups;
  my $img = $self->img;
  $img->xmlify(-pubid => "-//W3C//DTD SVG 1.0//EN",
               -inline => 1);
}

###GD###sub png {
###GD###  my ($self,$compression) = @_;
###GD###  return $self->{gd}->png($compression);
###GD###}

###GD###sub jpeg {
###GD###  my ($self,$quality) = @_;
###GD###  return $self->{gd}->jpeg($quality);
###GD###}

#############################
# Color management routines #
#############################
# As with GD, colorAllocate returns integers...
# This could easily rely on GD itself to generate the indices
sub colorAllocate {
  my ($self,$r,$g,$b,$alpha) = @_;
  $r     ||= 0;
  $g     ||= 0;
  $b     ||= 0;
  $alpha ||= 0;

  ###GD###my $newindex = $self->{gd}->colorAllocate($r,$g,$b);

  # Cannot use the numberof keys to generate index
  # colorDeallocate removes keys.
  # Instead use the colors_added array.
  my $new_index = (defined $self->{colors_added}) ? scalar @{$self->{colors_added}} : 0;
  $self->{colors}->{$new_index} = [$r,$g,$b,$alpha];

  # Keep a list of colors in the order that they are added
  # This is used as a kludge for setBrush
  push (@{$self->{colors_added}},$new_index);
  return $new_index;
}

sub colorAllocateAlpha {
    my $self = shift;
    ###GD###$self->{gd}->colorAllocateAlpha($r,$g,$b,$alpha);
    $self->colorAllocate(@_);
}

sub colorDeallocate {
  my ($self,$index) = @_;
  my $colors = %{$self->{colors}};
  delete $colors->{$index};
  ###GD###$self->{gd}->colorDeallocate($index);
}

# workaround for bad GD
sub colorClosest {
  my ($self,@c) = @_;
  ###GD###my $index = $self->{gd}->colorClosest(@c);

  # Let's just return the color for now.
  # Terrible kludge.
  my $index = $self->colorAllocate(@c);
  return $index;
  #  my ($self,$gd,@c) = @_;
  #  return $self->{closestcache}{"@c"} if exists $self->{closestcache}{"@c"};
  #  return $self->{closestcache}{"@c"} = $gd->colorClosest(@c) if $GD::VERSION < 2.04;
  #  my ($value,$index);
  #  for (keys %COLORS) {
  #    my ($r,$g,$b) = @{$COLORS{$_}};
  #    my $dist = ($r-$c[0])**2 + ($g-$c[1])**2 + ($b-$c[2])**2;
  #    ($value,$index) = ($dist,$_) if !defined($value) || $dist < $value;
  #  }
  #  return $self->{closestcache}{"@c"} = $self->{translations}{$index};
}

sub colorClosestHWB { shift->_error('colorClosestHWB'); }

sub colorExact {
  my ($self,$r,$g,$b) = @_;
  ###GD###my $index = $self->{gd}->colorExact($r,$g,$b);
  
  # Let's just allocate the color instead of looking it up
  my $index = $self->colorAllocate($r,$g,$b);
  if ($index) {
    return $index;
  } else {
    return ('-1');
  }
}

sub colorResolve {
  my ($self,$r,$g,$b) = @_;
  ###GD###my $index = $self->{gd}->colorResolve($r,$g,$b);
  my $index = $self->colorAllocate($r,$g,$b);
  return $index;
}

sub colorsTotal {
  my $self = shift;
  ###GD###return $self->{gd}->colorsTotal;
  return scalar keys %{$self->{colors}};
}


sub getPixel {
  my ($self,$x,$y) = @_;
  # Internal GD - probably unnecessary in this context...
  # Will contstruct appropriate return value later
  ###GD### $self->{gd}->getPixel($x,$y);
  
  # I don't have any cogent way to fetch the value of an asigned pixel
  # without calculating all positions and loading into memory.
  
  # For these purposes, I could maybe just look it up...  From a hash
  # table or something - Keep track of all assigned pixels and their
  # color. Ugh. Compute intensive.
  return (1);
}

# Given the color index, return its rgb triplet
sub rgb {
  my ($self,$index) = @_;
  my ($r,$g,$b) = @{$self->{colors}->{$index}};
  return ($r,$g,$b);
}

sub transparent { shift->_error('transparent'); }


#######################
# Special Colors
#######################
# Kludgy preliminary support for gdBrushed This is based on
# Bio::Graphics implementation of set_pen which in essence just
# controls line color and thickness...  We will assume that the last
# color added is intended to be the foreground color.
sub setBrush {
  my ($self,$pen) = @_;
  ###GD###$self->{gd}->setBrush($pen);
  my ($width,$height) = $pen->getBounds();
  my $last_color = $pen->{colors_added}->[-1];
  my ($r,$g,$b) = $self->rgb($last_color);
  $self->{gdBrushed}->{color} = $self->colorAllocate($r,$g,$b);
  $self->{gdBrushed}->{thickness} = $width;
}

# There is no direct translation of gdStyled.  In gd, this is used to
# set the style for the line using the settings of the current brush.
# Drawing with the new style is then used by passing the gdStyled as a
# color.
sub setStyle {
  my ($self,@colors) = @_;
  ###GD###$self->{gd}->setStyle(@colors);
  $self->{gdStyled}->{color} = [ @colors ];
  return;
}

# Lines in GD are 1 pixel in diameter by default.
# setThickness allows line thickness to be changed.
# This should be retained until it's changed again
# Each method should check the thickness of the line...
sub setThickness {
  my ($self,$thickness) = @_;
  ###GD### $self->{gd}->setThickness($thickness);
  $self->{line_thickness} = $thickness;
  # WRONG!
  # $self->{prev_line_thickness} = (!defined $self->{prev_line_thickness}) ? $thickness : undef;
}


########################
# Grouping subroutines #
########################
sub startGroup {
    my $this  = shift;
    my $id    = shift;
    my $style = shift;

    my @args;
    push @args,(id    => $id)    if defined $id;
    push @args,(style => $style) if defined $style;

    my $group = $this->currentGroup->group(@args);
    push @{$this->{img}},$group;
    return $group;
}
sub endGroup {
    my $this  = shift;
    my $group = shift;

    if ($group) {
	my @imgs = grep {$_ ne $group} @{$this->{img}};
	$this->{img} = \@imgs;
    }
    elsif (@{$this->{img}}>1) {
	pop @{$this->{img}};
    }
    delete $this->{currentGroup};
}
sub newGroup {
    my $this  = shift;
    my $group = $this->startGroup(@_);
    eval "require GD::Group" unless GD::Group->can('new');
    return GD::Group->new($this,$group);
}

#######################
# Drawing subroutines #
#######################
sub setPixel {
  my ($self,$x1,$y1,$color_index) = @_;
  ###GD### $self->{gd}->setPixel($x1,$y1,$color_index);
  my ($img,$id,$thickness,$dasharray) = $self->_prep($x1,$y1);
  my $color = $self->_get_color($color_index);
  my $result =
    $img->circle(cx=>$x1,cy=>$y1,r=>'0.03',
		 id=>$id,
		 style=>{
			 'stroke'=>$color,
			 'fill'  =>$color,
			 'fill-opacity'=>'1.0'
			}
		);
  return $result;
}

sub line {
  my ($self,$x1,$y1,$x2,$y2,$color_index) = @_;
  # Are we trying to draw with a styled line (ie gdStyled, gdBrushed?)
  # If so, we need to deconstruct the values for line thickness,
  # foreground color, and dash spacing
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->line($x1,$y1,$x2,$y2,$fg);
  } else {
    ###GD### $self->{gd}->line($x1,$y1,$x2,$y2,$color_index);
    my ($img,$id) = $self->_prep($x1,$y1);
    my $style = $self->_build_style($id,$color_index,$color_index);
    
    # Suggested patch by Jettero to fix lines
    # that don't go to the ends of their length.
    # This could possibly be relocated to _build_style
    # but I'm unsure of the ramifications on other features.
    $style->{'stroke-linecap'} = 'square';
    my $result = $img->line(x1=>$x1,y1=>$y1,
			    x2=>$x2,y2=>$y2,
			    id=>$id,
			    style => $style,
			   );
    $self->_reset();
    return $result;
  }
}

sub dashedLine { shift->_error('dashedLine'); }

# The fill parameter is used internally as a simplification...
sub rectangle {
  my ($self,$x1,$y1,$x2,$y2,$color_index,$fill) = @_;
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->rectangle($x1,$y1,$x2,$y2,$fg,$fill);
  } else {
    ###GD###$self->{gd}->rectangle($x1,$y1,$x2,$y2,$color_index);
    my ($img,$id) = $self->_prep($x1,$y1);
    my $style = $self->_build_style($id,$color_index,$fill);

    # flip coordinates if they are "backwards"
    ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
    ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
    my $result = 
      $img->rectangle(x=>$x1,y=>$y1,
		      width  =>$x2-$x1,
		      height =>$y2-$y1,
		      id     =>$id,
		      style => $style,
		     );
    $self->_reset();
    return $result;
  }
}

# This should just call the rectangle method passing it a flag.
# I will need to fix the glyph that bypasses this option...
sub filledRectangle {
  my ($self,$x1,$y1,$x2,$y2,$color) = @_;
  # Call the rectangle method passing the fill color
  $self->rectangle($x1,$y1,$x2,$y2,$color,$color);
}

sub polygon {
  my ($self,$poly,$color,$fill) = @_;
  $self->_polygon($poly,$color,$fill,1);
}

sub polyline {
  my ($self,$poly,$color,$fill) = @_;
  $self->_polygon($poly,$color,$fill,0);
}

sub polydraw {
  my $self = shift;	# the GD::Image
  my $p    = shift;	# the GD::Polyline or GD::Polygon
  my $c    = shift;	# the color
  return $self->polyline($p, $c) if $p->isa('GD::Polyline');
  return $self->polygon($p, $c);
}

sub _polygon {
  my ($self,$poly,$color_index,$fill,$close) = @_;
  my $shape = $close ? 'polygon' : 'polyline';
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->$shape($poly,$fg);
  } else {
    ###GD###$self->{gd}->polygon($poly,$color);
    # Create seperate x and y arrays of vertices
    my (@xpoints,@ypoints);
    if ($poly->can('_fetch_vertices')) {
      @xpoints = $poly->_fetch_vertices('x');
      @ypoints = $poly->_fetch_vertices('y');
    } else {
      my @points = $poly->vertices;
      @xpoints   = map { $_->[0] } @points;
      @ypoints   = map { $_->[1] } @points;
    }
    my ($img,$id) = $self->_prep($xpoints[0],$ypoints[0]);
    my $points = $img->get_path(
				x=>\@xpoints, y=>\@ypoints,
				-type=>$shape,
			       );
    my $style = $self->_build_style($id,$color_index,$fill);
    my $result =
      $img->$shape(
		    %$points,
		    id=>$id,
		    style => $style,
		   );
    $self->_reset();
    return $result;
  }
}

# Passing the stroke doesn't really work as expected...
sub filledPolygon {
  my ($self,$poly,$color) = @_;
  my $result = $self->polygon($poly,$color,$color);
  return $result;
}

sub ellipse {
  my ($self,$x1,$y1,$width,$height,$color_index,$fill) = @_;
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->ellipse($x1,$y1,$width,$height,$fg);
  } else {
    ###GD### $self->{gd}->ellipse($x1,$y1,$width,$height,$color_index);

    my ($img,$id) = $self->_prep($x1,$y1);
    # GD uses width and height - SVG uses radii...
    $width  = $width / 2;
    $height = $height / 2;
    my $style = $self->_build_style($id,$color_index,$fill);
    my $result =
      $img->ellipse(
		    cx=>$x1, cy=>$y1,
		    rx=>$width, ry=>$height,
		    id=>$id,
		    style => $style,
		   );
    $self->_reset();
    return $result;
  }
}

sub filledEllipse {
  my ($self,$x1,$y1,$width,$height,$color) = @_;
  my $result = $self->ellipse($x1,$y1,$width,$height,$color,$color);
  return $result;
}

# GD uses the arc() and filledArc() methods in two capacities
#   1. to create closed ellipses, where start and end are 0 and 360
#   2. to create honest-to-god open arcs
# The arc method is no longer being used to draw filledArcs.
# All the fill-specific code within is no deprecated.
sub arc {
  my ($self,$cx,$cy,$width,$height,$start,$end,$color_index,$fill) = @_;
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->arc($cx,$cy,$width,$height,$start,$end,$fg);
  } else {
    ###GD### $self->{gd}->arc($x,$y,$width,$height,$start,$end,$color);
    # Are we just trying to draw a closed arc (an ellipse)?
    my $result;
    if ($start == 0 && $end == 360 || $end == 360 && $start == 0) {
      $result = $self->ellipse($cx,$cy,$width,$height,$color_index,$fill);
    } else {
      my ($img,$id) = $self->_prep($cy,$cx);

      # Taking a stab at drawing elliptical arcs
      my ($start,$end,$large,$sweep,$a,$b) = _calculate_arc_params($start,$end,$width,$height);
      my ($startx,$starty) = _calculate_point_coords($cx,$cy,$width,$height,$start);
      my ($endx,$endy)     = _calculate_point_coords($cx,$cy,$width,$height,$end);

      # M = move to (origin of the curve)
      # my $rotation = abs $start - $end;
      my $style = $self->_build_style($id,$color_index,$fill);
      $result =
      	$img->path('d'=>"M$startx,$starty "  .
      		   "A$a,$b 0 $large,$sweep $endx,$endy",
		   style => $style,
		  );
    }
    $self->_reset();
    return $result;
  }
}

# Return the x and y positions of start and stop of arcs.
sub _calculate_point_coords {
  my ($cx,$cy,$width,$height,$angle) = @_;
  my $x = ( $cosT[$angle % 360] * $width)  / (2 * 1024) + $cx;
  my $y = ( $sinT[$angle % 360] * $height) / (2 * 1024) + $cy;
  return ($x,$y);
}

sub _calculate_arc_params {
  my ($start,$end,$width,$height) = @_;

  # GD uses diameters, SVG uses radii
  my $a = $width  / 2;
  my $b = $height / 2;
  
  while ($start < 0 )    { $start += 360; }
  while ($end < 0 )      { $end   += 360; }
  while ($end < $start ) { $end   += 360; }

  my $large = (abs $start - $end > 180) ? 1 : 0;
  # my $sweep = ($start > $end) ? 0 : 1;  # directionality of the arc, + CW, - CCW
  my $sweep = 1; # Always CW with GD
  return ($start,$end,$large,$sweep,$a,$b);
}

sub filledArc {
  my ($self,$cx,$cy,$width,$height,$start,$end,$color_index,$fill_style) = @_;
  if ($color_index eq 'gdStyled' || $color_index eq 'gdBrushed') {
    my $fg = $self->_distill_gdSpecial($color_index);
    $self->filledArc($cx,$cy,$width,$height,$start,$end,$fg);
  } else {
    ###GD### $self->{gd}->arc($x,$y,$width,$height,$start,$end,$color_index);
    my $result;

    # distill the special colors, if provided...
    my $fill_color;
    # Set it to gdArc, the default value to avoid undef errors in comparisons
    $fill_style ||= 0;
    if ($fill_style == 2 || $fill_style == 4 || $fill_style == 6) {
      $fill_color = 'none';
    } else {
      $fill_color = $self->_get_color($color_index);
    }

    # Are we just trying to draw a closed filled arc (an ellipse)?
    if (($start == 0 && $end == 360) || ($start == 360 && $end == 0)) {
      $result = $self->ellipse($cx,$cy,$width,$height,$color_index,$fill_color);
    }

    # are we trying to draw a pie?
    elsif ($end - $start > 180 && ($fill_style == 0 || $fill_style == 4)) {
      $self->filledArc($cx,$cy,$width,$height,$start,$start+180,$color_index,$fill_style);
#      $self->filledArc($cx,$cy,$width,$height,$start+180,$end,$color_index,$fill_style);
      $result = $self->filledArc($cx,$cy,$width,$height,$start+180,$end,$color_index,$fill_style);
    }

    else {
      my ($img,$id) = $self->_prep($cy,$cx);

      my ($start,$end,$large,$sweep,$a,$b) = _calculate_arc_params($start,$end,$width,$height);
      my ($startx,$starty) = _calculate_point_coords($cx,$cy,$width,$height,$start);
      my ($endx,$endy)     = _calculate_point_coords($cx,$cy,$width,$height,$end);

      # Evaluate the various fill styles
      # gdEdged connects the center to the start and end
      if ($fill_style == 4 || $fill_style == 6) {
	$self->line($cx,$cy,$startx,$starty,$color_index);
	$self->line($cx,$cy,$endx,$endy,$color_index);
      }

      # gdNoFill outlines portions of the arc
      # noFill or gdArc|gdNoFill
      if ($fill_style == 2 || $fill_style == 6) {
	$result = $self->arc($cx,$cy,$width,$height,$start,$end,$color_index);
	return $result;
      }

      # gdChord|gdNofFill
      if ($fill_style == 3) {
	$result = $self->line($startx,$starty,$endx,$endy,$color_index);
	return $result;
      }

      # Create the actual filled portion of the arc
      # This is the default behavior for gdArc and if no style is passed.
      if ($fill_style == 0 || $fill_style == 4) {
	# M = move to (origin of the curve)
	# my $rotation = abs $start - $end;
	my $style = $self->_build_style($id,$color_index,$fill_color);	
	$result =
	  $img->path('d'=>"M$startx,$starty "  .
		     "A$a,$b 0 $large,$sweep $endx,$endy",
		     style => $style,
		    );
      }

      # If we are filling, draw a filled triangle to complete.
      # This is also the same as using gdChord by itself
      my $poly = GD::SVG::Polygon->new();
      $poly->addPt($cx,$cy);
      $poly->addPt($startx,$starty);
      $poly->addPt($endx,$endy);
      $self->filledPolygon($poly,$color_index);
    }

    $self->_reset();
    return $result;
  }
}

# Flood fill that stops at first pixel of a different color.
sub fill         { shift->_error('fill'); }
sub fillToBorder { shift->_error('fillToBorder'); }

##################################################
# Image Copying Methods
##################################################

# Taking a stab at implementing the copy() methods
# Should be relatively easy to implement clone() from this
sub copy {
    my $self = shift;
    my ($source,$dstx,$dsty,$srcx,$srcy,$width,$height) = @_;

    # special case -- if we have been asked to copy a
    # GD::Image into us, then we embed an image with the
    # data:url
    if ($source->isa('GD::Image') || $source->isa('GD::Simple')) {
	return $self->_copy_image(@_);
    }

    my $topx    = $srcx;
    my $topy    = $srcy;
    my $bottomx = $srcx + $width;   # arithmetic right here?
    my $bottomy = $srcy + $height;

    # Fetch all elements of the source image
    my @elements = $source->img->getElements;
    foreach my $element (@elements) {
	my $att = $element->getAttributes();
	# Points|rectangles|text, circles|ellipses, lines
	my $x = $att->{x} || $att->{cx} || $att->{x1};
	my $y = $att->{y} || $att->{cy} || $att->{y1};

	# Use the first point for polygons
	unless ($x && $y) {
	    my @points = split(/\s/,$att->{points});
	    if (@points) {
		($x,$y) = split(',',$points[0]);
	    }
	}

	# Paths
	unless ($x && $y) {
	    my @d = split(/\s/,$att->{d});
	    if (@d) {
		($x,$y) = split(',',$d[0]);
		$x =~ s/^M//;  # Remove the style directive
	    }
	}

	# Are the starting coords within the bounds of the desired rectangle?
	# We will simplistically assume that the entire glyph fits inside
	# the rectangle which may not be true.
	if (($x >= $topx && $y >= $topy) &&
	    ($x <= $bottomx && $y <= $bottomy)) {
	    my $type = $element->getType;
	    # warn "$type $x $y $bottomx $bottomy $topx $topy"; 

	    # Transform the coordinates as necessary,
	    # calculating the offsets relative to the
	    # original bounding rectangle in the source image

	    # Text or rectangles
	    if ($type eq 'text' || $type eq 'rect') {
		my ($newx,$newy) = _transform_coords($topx,$topy,$x,$y,$dstx,$dsty);
		$element->setAttribute('x',$newx);
		$element->setAttribute('y',$newy);	
		# Circles or ellipses
	    } elsif ($type eq 'circle' || $type eq 'ellipse') {
		my ($newx,$newy) = _transform_coords($topx,$topy,$x,$y,$dstx,$dsty);
		$element->setAttribute('cx',$newx);
		$element->setAttribute('cy',$newy);
		# Lines
	    } elsif ($type eq 'line') {
		my ($newx1,$newy1) = _transform_coords($topx,$topy,$x,$y,$dstx,$dsty);
		my ($newx2,$newy2) = _transform_coords($topx,$topy,$att->{x2},$element->{y2},$dstx,$dsty);
		$element->setAttribute('x1',$newx1);
		$element->setAttribute('y1',$newy1);
		$element->setAttribute('x2',$newx2);
		$element->setAttribute('y2',$newy2);
		# Polygons
	    } elsif ($type eq 'polygon') {
		my @points = split(/\s/,$att->{points});
		my @transformed;
		foreach (@points) {
		    ($x,$y) = split(',',$_);
		    my ($newx,$newy) = _transform_coords($topx,$topy,$x,$y,$dstx,$dsty);
		    push (@transformed,"$newx,$newy");
		}
		my $transformed = join(" ",@transformed);
		$element->setAttribute('points',$transformed);
		# Paths
	    } elsif ($type eq 'path') {
		
	    }

	    # Create new elements for the destination image
	    # via the generic SVG::Element::tag method
	    my %attributes = $element->getAttributes;
	    $self->img->tag($type,%attributes);
	}
    }
}

# Used internally by the copy method
# Transform coordinates of a given point with reference
# to a bounding rectangle
sub _transform_coords {
  my ($refx,$refy,$x,$y,$dstx,$dsty) = @_;
  my $xoffset = $x - $refx;
  my $yoffset = $y - $refy;
  my $newx = $dstx + $xoffset;
  my $newy = $dsty + $yoffset;
  return ($newx,$newy);
}

sub _copy_image {
    my $self = shift;
    my ($source,$dstx,$dsty,$srcx,$srcy,$width,$height) = @_;

    eval "use MIME::Base64; 1"
	or croak "The MIME::Base64 module is required to copy a GD::Image into a GD::SVG: $@";

    my $subimage = GD::Image->new($width,$height); # will be loaded
    $subimage->copy($source->isa('GD::Simple') ? $source->gd : $source,
		    0,0,
		    $srcx,$srcy,
		    $width,$height);

    my $data     = encode_base64($subimage->png);
    my ($img,$id) = $self->_prep($dstx,$dsty);
    my $result = 
	$img->image('x'    => $dstx,
		    'y'    => $dsty,
		    width  => $width,
		    height => $height,
		    id     => $id,
		    'xlink:href' => "data:image/png;base64,$data");
    $self->_reset;
    return $result;
}




##################################################
# Image Transformation Methods
##################################################

# None implemented

##################################################
# Character And String Drawing
##################################################
sub string {
  my ($self,$font_obj,$x,$y,$text,$color_index) = @_;
  my $img = $self->currentGroup;
  my $id = $self->_create_id($x,$y);
  my $formatting = $font_obj->formatting();
  my $color = $self->_get_color($color_index);
  my $result =
    $img->text(
	       id=>$id,
	       x=>$x,
	       y=>$y + $font_obj->{height} - GD::SVG::TEXT_KLUDGE,
	       %$formatting,
	       fill      => $color,
	      )->cdata($text);
  return $result;
}

sub stringUp {
  my ($self,$font_obj,$x,$y,$text,$color_index) = @_;
  my $img = $self->currentGroup;
  my $id = $self->_create_id($x,$y);
  my $formatting = $font_obj->formatting();
  my $color = $self->_get_color($color_index);
  $x += $font_obj->height;
  my $result =
    $img->text(
	       id=>$id,
	       %$formatting,
	       'transform' => "translate($x,$y) rotate(-90)",
	       fill      => $color,
	      )->cdata($text);
}

sub char {
  my ($self,@rest) = @_;
  $self->string(@rest);
}

sub charUp {
  my ($self,@rest) = @_;
  $self->stringUp(@rest);
}

# Replicating the TrueType handling
#sub GD::Image::stringFT { shift->_error('stringFT'); }

sub stringFT {
    return;
}

# not implemented
sub useFontConfig { 
    return 0;
}


##################################################
# Alpha Channels
##################################################
sub alphaBlending { shift->_error('alphaBlending'); }
sub saveAlpha     { shift->_error('saveAlpha'); }

##################################################
# Miscellaneous Image Methods
##################################################
sub interlaced { shift->_error('inerlaced'); }

sub getBounds {
  my $self = shift;
  my $width = $self->{width};
  my $height = $self->{height};
  return($width,$height);
}

sub isTrueColor { shift->_error('isTrueColor'); }
sub compare     { shift->_error('compare'); }
sub clip        { shift->_error('clip'); }
sub boundsSafe  { shift->_error('boundsSafe'); }

##########################################
# Internal routines for meshing with SVG #
##########################################
# Fetch out typical params used for drawing.
package GD::SVG::Image;
use Carp 'confess';

sub _prep {
  my ($self,@params) = @_;
  my $img = $self->currentGroup;
  my $id = $self->_create_id(@params);
  # my $thickness = $self->_get_thickness() || 1;
#  return ($img,$id,$thickness,undef);
  return ($img,$id,undef,undef);
}

# Pass in a ordered list to create a hash ref of style parameters
# ORDER: $id,$color_index,$fill_color,$stroke_opacity);
sub _build_style {
  my ($self,$id,$color,$fill,$stroke_opacity) = @_;
  my $thickness = $self->_get_thickness() || 1;

  my $fill_opacity = ($fill) ? '1.0' : 0;
  $fill = defined $fill ? $self->_get_color($fill) : 'none';
  if ((my $color_opacity = $self->_get_opacity($color)) > 0) {
      $stroke_opacity = (127-$color_opacity)/127;
  } else {
      $stroke_opacity ||= '1.0';
  }
  my %style = ('stroke'         => $self->_get_color($color),
	       'stroke-opacity' => $stroke_opacity,
	       'stroke-width'   => $thickness,
	       'fill'           => $fill,
	       'fill-opacity'   => $stroke_opacity,
      );
  my $dasharray = $self->{dasharray};
  if ($self->{dasharray}) {
    $style{'stroke-dasharray'} = @{$self->{dasharray}};
    $style{fill} = 'none';
  }
  return \%style;
}

# From a color index, return a stringified rgb triplet for SVG
sub _get_color {
  my ($self,$index) = @_;
  confess "somebody gave me a bum index!" unless length $index > 0;
  return ($index) if ($index =~ /rgb/); # Already allocated.
  return ($index) if ($index eq 'none'); # Generate by callbacks using none for fill
  my ($r,$g,$b,$a) = @{$self->{colors}->{$index}};
  my $color = "rgb($r,$g,$b)";
  return $color;
}

sub _get_opacity {
  my ($self,$index) = @_;
  confess "somebody gave me a bum index!" unless length $index > 0;
  return ($index) if ($index =~ /rgb/); # Already allocated.
  return ($index) if ($index eq 'none'); # Generate by callbacks using none for fill
  my ($r,$g,$b,$a) = @{$self->{colors}->{$index}};
  return $a;
}

sub _create_id {
  my ($self,$x,$y) = @_;
  $self->{id_count}++;
  return (join('-',$self->{id_count},$x,$y));
}

# Break apart the internal representation of gdBrushed
# setting the line thickness and returning the foreground color
sub _distill_gdSpecial {
  my ($self,$type) = @_;
  # Save the previous line thickness so I can restore after drawing...
  $self->{prev_line_thickness} = $self->_get_thickness() || 1;
  my $thickness = $self->{$type}->{thickness};
  $thickness ||= 1;
  my $color;
  if ($type eq 'gdStyled') {
    # Calculate the size in pixels of each dash
    # The first color only will be used starting with the first
    # dash; remaining dashes will become gaps
    my @colors = @{$self->{$type}->{color}};
    my ($prev,@dashes,$dash_length);
    foreach (@colors) {
      if (!$prev) {
	$dash_length = 1;
      # Numeric comparisons work for normal colors
      # but fail for named special colors like gdTransparent
      } elsif ($prev && $prev eq $_) {
	$dash_length++;
      } elsif ($prev && $prev ne $_) {
#      } elsif ($prev && $prev == $_) {
#	$dash_length++;
#      } elsif ($prev && $prev != $_) {
	push (@{$self->{dasharray}},$dash_length);
	$dash_length = 1;
      }
      $prev = $_;
    }
    push (@{$self->{dasharray}},$dash_length);
    $color = $colors[0];
  } else {
    $color = $self->{$type}->{color};
  }
  
  $self->setThickness($thickness);
  return $color;
}


# Reset presistent drawing settings between uses of stylized brushes
sub _reset {
  my $self = shift;
  $self->{line_thickness} = $self->{prev_line_thickness} || $self->{line_thickness};
  $self->{prev_line_thickness} = undef;
  delete $self->{dasharray};
}

# SVG needs some self-awareness so that post-drawing operations can
# occur. This is accomplished by tracking all of the pixels that have
# been filled in thus far.
sub _save {
  my ($self) = @_;
  #  my $path = $img->get_path(x=>[$x1,$x2],y=>[$y1,$y2],-type=>'polyline',-closed=>1);
  #  foreach (keys %$path) {
  #    print STDERR $_,"\t",$path->{$_},"\n";
  #  }
  #  push (@{$self->{pixels_filled}},$path);
}

# Value-access methods
# Get the thickness of the line (if it has been set)
sub _get_thickness {  return shift->{line_thickness} }

# return the internal GD object
sub _gd { return shift->{gd} }

##################################################
# GD::SVG::Polygon
##################################################
package GD::SVG::Polygon;
use GD::Polygon;
use vars qw(@ISA);
@ISA = 'GD::Polygon';

sub _error {
  my ($self,$method) = @_;
  GD::SVG::Image->_error($method);
}

sub DESTROY { }

# Generic Font package for accessing height and width information
# and for formatting strings
package GD::SVG::Font;

use vars qw/@ISA/;
@ISA = qw(GD::SVG);

# Return guestimated values on the font height and width
sub width   { return shift->{width}; }
sub height  { return shift->{height}; }
sub font    { return shift->{font}; }
sub weight  { return shift->{weight}; }
sub nchars  { shift->_error('nchars')} # NOT SUPPORTED!!

# Build the formatting hash for each font...
sub formatting {
  my $self = shift;
  my $size    = $self->height;
  my $font    = $self->font;
  my $weight  = $self->weight;
  my %format = ('font-size' => $size,
		'font'       => $font,
#		'writing-mode' => 'tb',
	       );
  $format{'font-weight'} = $weight if ($weight);
  return \%format;
}

sub Tiny  { return GD::SVG::gdTinyFont; }
sub Small { return GD::SVG::gdSmallFont; }
sub MediumBold { return GD::SVG::gdMediumBoldFont; }
sub Large { return GD::SVG::gdLargeFont; }
sub Giant { return GD::SVG::gdGiantFont; }

sub _error {
  my ($self,$method) = @_;
  GD::SVG::Image->_error($method);
}

sub DESTROY { }

1;

=pod

=head1 NAME

GD::SVG - Seamlessly enable SVG output from scripts written using GD

=head1 SYNOPSIS

    # use GD;
    use GD::SVG;

    # my $img = GD::Image->new();
    my $img = GD::SVG::Image->new();

    # $img->png();
    $img->svg();

=head1 DESCRIPTION

GD::SVG painlessly enables scripts that utilize GD to export scalable
vector graphics (SVG). It accomplishes this task by wrapping SVG.pm
with GD-styled method calls. To enable this functionality, one need
only change the "use GD" call to "use GD::SVG" (and initial "new"
method calls).

=head1 EXPORTS

GD::SVG exports the same methods as GD itself, overriding those
methods.

=head1 USAGE

In order to generate SVG output from your script using GD::SVG, you
will need to first

  # use GD;
  use GD::SVG;

After that, each call to the package classes that GD implements should
be changed to GD::SVG. Thus:

  GD::Image    becomes  GD::SVG::Image
  GD::Font     becomes  GD::SVG::Font

=head1 DYNAMICALLY SELECTING SVG OUTPUT

If you would like your script to be able to dynamically select either
PNG or JPEG output (via GD) or SVG output (via GD::SVG), you should
place your "use" statement within an eval. In the example below, each
of the available classes is created at the top of the script for
convenience, as well as the image output type.

  my $package = shift;
  eval "use $package";
  my $image_pkg = $package . '::Image';
  my $font_pkg  = $package . '::Font';

  # Creating new images thus becomes
  my $image   = $image_pkg->new($width,$height);

  # Establish the image output type
  my $image_type;
  if ($package = 'GD::SVG') {
    $image_type = 'svg';
  } else {
    $image_type = 'png';
  }

Finally, you should change all GD::Image and GD::Font references to
$image_pkg-> and $font_pkg->, respectively.

  GD::Image->new()   becomes   $image_pkg->new()
  GD::Font->Large()  becomes   $font_pkg->Large()

The GD::Polygon and GD::Polyline classes work with GD::SVG without
modification.

If you make heavy use of GD's exported methods, it may also be
necessary to add () to the endo of method names to avoide bareword
compilation errors. That's the price you pay for using exported
functions!

=head1 IMPORTANT NOTES

GD::SVG does not directly generate SVG, but instead relies upon
SVG.pm. It is not intended to supplant SVG.pm.  Furthermore, since
GD::SVG is, in essence an API to an API, it may not be suitable for
applications where speed is of the essence. In these cases, GD::SVG
may provide a short-term solution while scripts are re-written to
enable more direct output of SVG.

Many of the GD::SVG methods accept additional parameters (which are in
turn reflected in the SVG.pm API) that are not supported in GD.  Look
through the remainder of this document for options on specific In
addition, several functions have yet to be mapped to SVG.pm
calls. Please see the section below regarding regarding GD functions
that are missing or altered in GD::SVG.

A similar module (SVG::GD) implements a similar wrapper around
GD. Please see the section at the bottom of this document that
compares GD::SVG to SVG::GD.

=head1 PREREQUISITES

GD::SVG requires the Ronan Oger's SVG.pm module, Lincoln Stein's GD.pm
module, libgd and its dependencies.

=head1 GENERAL DIFFICULTIES IN TRANSLATING GD TO SVG

These are the primary weaknesses of GD::SVG.

=over 4

=item SVG requires unique identifiers for each element

Each element in an SVG image requires a unique identifier. In general,
GD::SVG handles this by automatically generating unique random
numbers.  In addition to the typical parameters for GD methods,
GD::SVG methods allow a user to pass an optional id parameter for
naming the object.

=item Direct calls to the GD package will fail

You must change direct calls to the classes that GD invokes:
    GD::Image->new() should be changed to GD::SVG::Image->new()

See the documentation above for how to dynamically switch between
packages.

=item raster fill() and fillToBorder() not supported

As SVG documents are not inherently aware of their canvas, the flood
fill methods are not currently supported.

=item getPixel() not supported.

Although setPixel() works as expected, its counterpart getPixel() is
not supported. I plan to support this method in a future release.

=item No support for generation of images from filehandles or raw data

GD::SVG works only with scripts that generate images directly in the
code using the GD->new(height,width) approach. newFrom() methods are
not currently supported.

=item Tiled fills are not supported

Any functions passed gdTiled objects will die.

=item Styled and Brushed lines only partially implemented

Calls to the gdStyled and gdBrushed functions via a
rather humorous kludge (and simplification). Depending on the
complexity of the brush, they may behave from slightly differently to
radically differently from their behavior under GD. You have been
warned. See the documentation sections for the methods that set these
options (setStyle(), setBrush(), and setTransparent()).

=back

See below for a full list of methods that have not yet been
implemented.

=head1 WHEN THINGS GO WRONG

GD is a complicated module.  Translating GD methods into those
required to draw in SVG are not always direct. You may or may not get
the output you expect. In general, some tweaking of image parameters
(like text height and width) may be necessary.

If your script doesn't work as expected, first check the list of
methods that GD::SVG provides.  Due to differences in the nature of
SVG images, not all GD methods have been implemented in GD::SVG.

If your image doesn't look as expected, try tweaking specific aspects
of image generation.  In particular, check for instances where you
calculate dimensions of items on the fly like font->height. In SVG,
the values of fonts are defined explicitly.

=head1 GD FUNCTIONS MISSING FROM GD::SVG

The following GD functions have not yet been incorporated into
GD::SVG. If you attempt to use one of these functions (and you have
enabled debug warnings via the new() method), GD::SVG will print a
warning to STDERR.

  Creating image objects:
    GD::Image->newPalette([$width,$height])
    GD::Image->newTrueColor([$width,$height])
    GD::Image->newFromPng($file, [$truecolor])
    GD::Image->newFromPngData($data, [$truecolor])
    GD::Image->newFromJpeg($file, [$truecolor])
    GD::Image->newFromJpegData($data, [$truecolor])
    GD::Image->newFromXbm($file)
    GD::Image->newFromWMP($file)
    GD::Image->newFromGd($file)
    GD::Image->newFromGdData($data)
    GD::Image->newFromGd2($file)
    GD::Image->newFromGd2Data($data)
    GD::Image->newFromGd2Part($file,srcX,srcY,width,height)
    GD::Image->newFromXpm($filename)

  Image methods:
    $gddata   = $image->gd
    $gd2data  = $image->gd2
    $wbmpdata = $image->wbmp([$foreground])

  Color control methods:
    $image->colorAllocateAlpha()
    $image->colorClosest()
    $image->colorClosestHWB()
    $image->getPixel()
    $image->transparent()

  Special Colors:
    $image->setBrush() (semi-supported, with kludge)
    $image->setStyle() (semi-supported, with kludge)
    gdTiled
    $image->setAntialiased()
    gdAntiAliased()
    $image->setAntiAliasedDontBlend()

  Drawing methods:
    $image->dashedLine()
    $image->fill()
    $image->fillToBorder()

  Image copying methods
    None of the image copying methods are yet supported

  Image transformation methods
    None of the image transformation methods are yet supported

  Character and string drawing methods
     $image->stringUp()  - incompletely supported - broken
     $image->charUp()
     $image->stringFT()

  Alpha Channels
    $image->alphaBlending()
    $image->saveAlpha()

  Miscellaneous image methods
    $image->isTrueColor()
    $image->compare($image2)
    $image->clip()
    $image->boundsSafe()

  GD::Polyline
    Supported without modifications

  Font methods:
    $font->nchars()
    $font->offset()

=head1 GROUPING FUNCTIONS GD::SVG

GD::SVG supports three additional methods that provides the ability to
recursively group objects:

=over 4

=item $this->startGroup([$id,\%style]), $this->endGroup()

These methods start and end a group in a procedural manner. Once a
group is started, all further drawing will be appended to the group
until endGroup() is invoked. You may optionally pass a string ID and
an SVG styles hash to startGroup.

=item $group = $this->newGroup([$id,\%style])

This method returns a GD::Group object, which has all the behaviors of
a GD::SVG object except that it draws within the current group. You
can invoke this object's drawing methods to draw into a group. The
group is closed once the object goes out of scope. While the object is
open, invoking drawing methods on the parent GD::SVG object will also
draw into the group until it goes out of scope.

Here is an example of using grouping in the procedural way:

 use GD::SVG;
 my $img   = GD::SVG::Image->new(500,500);
 my $white = $img->colorAllocate(255,255,255);
 my $black = $img->colorAllocate(0,0,0);
 my $blue  = $img->colorAllocate(0,0,255);
 my $red   = $img->colorAllocate(255,0,0);

 $img->startGroup('circle in square');
 $img->rectangle(100,100,400,400,$blue);

 $img->startGroup('circle and boundary');
 $img->filledEllipse(250,250,200,200,$red);
 $img->ellipse(250,250,200,200,$black);

 $img->endGroup;
 $img->endGroup;
 
 print $img->svg;

Here is an example of using grouping with the GD::Group object:

  ...

 my $g1 = $img->newGroup('circle in square');
 $g1->rectangle(100,100,400,400,$blue);

 my $g2 = $g1->startGroup('circle and boundary');
 $g2->filledEllipse(250,250,200,200,$red);
 $g2->ellipse(250,250,200,200,$black);

 print $img->svg;

Finally, here is a fully worked example of using the GD::Simple module
to make the syntax cleaner:

 #!/usr/bin/perl
    
 use strict;
 use GD::Simple;

 GD::Simple->class('GD::SVG');

 my $img = GD::Simple->new(500,500);
 $img->bgcolor('white');
 $img->fgcolor('blue');

 my $g1 = $img->newGroup('circle in square');
 $g1->rectangle(100,100,400,400);
 $g1->moveTo(250,250);

 my $g2 = $g1->newGroup('circle and boundary');
 $g2->fgcolor('black');
 $g2->bgcolor('red');
 $g2->ellipse(200,200);

 print $img->svg;

=back

=head1 GD VERSUS GD::SVG METHODS

All GD::SVG methods mimic the naming and interface of GD methods.  As
such, maintenance of GD::SVG follows the development of both GD and
SVG. Much of the original GD documentation is replicated here for ease
of use. Subtle differences in the implementation of these methods
between GD and GD::SVG are discussed below. In particular, the return
value for some GD::SVG methods differs from its GD counterpart.

=head1 OBJECT CONSTRUCTORS: CREATING IMAGES

GD::SVG currently only supports the creation of image objects via its
new constructor.  This is in contrast to GD proper which supports the
creation of images from previous images, filehandles, filenames, and
data.

=over 4

=item $image = GD::SVG::Image->new($height,$width,$debug);

Create a blank GD::SVG image object of the specified dimensions in
pixels. In turn, this method will create a new SVG object and store it
internally. You can turn on debugging with the GD::SVG specific $debug
parameter.  This should be boolean true and will cause non-implemented
methods to print a warning on their status to STDERR.

=back

=head1 GD::SVG::Image METHODS

Once a GD::Image object is created, you can draw with it, copy it, and
merge two images.  When you are finished manipulating the object, you
can convert it into a standard image file format to output or save to
a file.

=head2 Image Data Output Methods

GD::SVG implements a single output method, svg()!

=over 4

=item $svg = $image->svg();

This returns the image in SVG format. You may then print it, pipe it
to an image viewer, or write it to a file handle. For example,

  $svg_data = $image->svg();
  open (DISPLAY,"| display -") || die;
  binmode DISPLAY;
  print DISPLAY $svg_data;
  close DISPLAY;

if you'd like to return an inline version of the image (instead of a
full document version complete with the DTD), pass the svg() method the
'inline' flag:

  $svg_data = $image->svg(-inline=>'true');

Calling the other standard GD image output methods (eg
jpeg,gd,gd2,png) on a GD::SVG::Image object will cause your script to
exit with a warning.

=back

=head2 Color Control

These methods allow you to control and manipulate the color table of a
GD::SVG image. In contrast to GD which uses color indices, GD::SVG
passes stringified RGB triplets as colors. GD::SVG, however, maintains
an internal hash structure of colors and colored indices in order to
map GD functions that manipulate the color table. This typically
requires behind-the-scenes translation of these stringified RGB
triplets into a color index.

=over 4

=item $stringified_color = $image->colorAllocate(RED,GREEN,BLUE)

Unlike GD, colors need not be allocated in advance in SVG.  Unlike GD
which returns a color index, colorAllocate returns a formatted string
compatible with SVG. Simultaneously, it creates and stores internally
a GD compatible color index for use with GD's color manipulation
methods.

  returns: "rgb(RED,GREEN,BLUE)"

=item $index = $image->colorAllocateAlpha()

NOT IMPLEMENTED

=item $image->colorDeallocate($index)

Provided with a color index, remove it from the color table.

=item $index = $image->colorClosest(red,green,blue)

This returns the index of the color closest in the color table to the
red green and blue components specified. This method is inherited
directly from GD.

  Example: $apricot = $myImage->colorClosest(255,200,180);

NOT IMPLEMENTED

=item $index = $image->colorClosestHWB(red,green,blue)

NOT IMPLEMENTED

=item $index = $image->colorExact(red,green,blue)

Retrieve the color index of an rgb triplet (or -1 if it has yet to be
allocated).

NOT IMPLEMENTED

=item $index = $image->colorResolve(red,green,blue)

NOT IMPLEMENTED

=item $colors_total = $image->colorsTotal()

Retrieve the total number of colors indexed in the image.

=item $index = $image->getPixel(x,y)

NOT IMPLEMENTED

=item ($red,$green,$blue) = $image->rgb($index)

Provided with a color index, return the RGB triplet.  In GD::SVG,
color indexes are replaced with actual RGB triplets in the form
"rgb($r,$g,$b)".

=item $image->transparent($colorIndex);

Control the transparency of individual colors.

NOT IMPLEMENTED

=back

=head2 Special Colors

GD implements a number of special colors that can be used to achieve
special effects.  They are constants defined in the GD:: namespace,
but automatically exported into your namespace when the GD module is
loaded. GD::SVG offers limited support for these methods.

=over 4

=item $image->setBrush($brush) (KLUDGE ALERT)

=item gdBrushed

In GD, one can draw lines and shapes using a brush pattern.  Brushes
are just images that you can create and manipulate in the usual way.
When you draw with them, their contents are used for the color and
shape of the lines.

To make a brushed line, you must create or load the brush first, then
assign it to the image using setBrush().  You can then draw in that
with that brush using the gdBrushed special color.  It's often useful
to set the background of the brush to transparent so that the
non-colored parts don't overwrite other parts of your image.

  # Via GD, this is how one would set a Brush
  $diagonal_brush = new GD::Image(5,5);
  $white = $diagonal_brush->colorAllocate(255,255,255);
  $black = $diagonal_brush->colorAllocate(0,0,0);
  $diagonal_brush->transparent($white);
  $diagonal_brush->line(0,4,4,0,$black); # NE diagonal

GD::SVG offers limited support for setBrush (and the corresponding
gdBrushed methods) - currently only in the shapes of squares.
Internally, GD::SVG extracts the longest dimension of the image using
the getBounds() method. Next, it extracts the second color set,
assuming that to be the foreground color. It then re-calls the
original drawing method with these new values in place of the
gdBrushed. See the private _distill_gdSpecial method for the internal
details of this operation.

=item $image->setThickness($thickness)

Lines drawn with line(), rectangle(), arc(), and so forth are 1 pixel
thick by default.  Call setThickness() to change the line drawing
width.

=item $image->setStyle(@colors)

setStyle() and gdStyled() are partially supported in GD::SVG. GD::SVG
determines the alternating pattern of dashes, treating the first
unique color encountered in the array as on, the second as off and so
on. The first color in the array is then used to draw the actual line.

=item gdTiled

NOT IMPLEMENTED

=item gdStyled()

The GD special color gdStyled is partially implemented in
GD::SVG. Only the first color will be used to generate the dashed
pattern specified in setStyle(). See setStyle() for additional
information.

=item $image->setAntiAliased($color)

NOT IMPLEMENTED

=item gdAntiAliased

NOT IMPLEMENTED

=item $image->setAntiAliasedDontBlend($color,[$flag])

NOT IMPLEMENTED

=back

=head2 Drawing Commands

=over 4

=item $image->setPixel($x,$y,$color)

Set the corresponding pixel to the given color.  GD::SVG implements
this by drawing a single dot in the specified color at that position.

=item $image->line(x1,y1,x2,y2,color);

Draw a line between the two coordinate points with the specified
color.  Passing an optional id will set the id of that SVG
element. GD::SVG also supports drawing with the special brushes -
gdStyled and gdBrushed - although these special styles are difficult
to replicate precisley in GD::SVG.

=item $image->dashedLine($x1,$y1,$x2,$y2,$color);

NOT IMPLEMENTED

=item $image->rectangle($x1,$y1,$x2,$y2,$color);

This draws a rectangle with the specified color.  (x1,y1) and (x2,y2)
are the upper left and lower right corners respectively.  You may also
draw with the special colors gdBrushed and gdStyled.

=item $image->filledRectangle($x1,$y1,$x2,$y2,$color);

filledRectangle is a GD specific method with no direct equivalent in
SVG.  GD::SVG translates this method into an SVG appropriate method by
passing the filled color parameter as a named 'filled' parameter to
SVG. Drawing with the special colors is also permitted. See the
documentation for the line() method for additional details.

   GD call:
     $img->filledRectangle($x1,$y1,$x2,$y2,$color);
  
   SVG call:
     $img->rectangle(x=> $x1,y=> $y1,
		     width  => $x2-$x1,
		     height => $y2-$y1,
		     fill   => $color

=item $image->polygon($polygon,$color);

This draws a polygon with the specified color.  The polygon must be
created first (see "Polygons" below).  The polygon must have at least
three vertices.  If the last vertex doesn't close the polygon, the
method will close it for you.  Both real color indexes and the special
colors gdBrushed, gdStyled and gdStyledBrushed can be specified. See
the documentation for the line() method for additional details.

  $poly = new GD::Polygon;
  $poly->addPt(50,0);
  $poly->addPt(99,99);
  $poly->addPt(0,99);
  $image->polygon($poly,$blue);

=item $image->filledPolygon($polygon,$color);

This draws a polygon filled with the specified color.  Drawing with
the special colors is also permitted. See the documentation for the
line() method for additional details.

  # make a polygon
  $poly = new GD::Polygon;
  $poly->addPt(50,0);
  $poly->addPt(99,99);
  $poly->addPt(0,99);

  # draw the polygon, filling it with a color
  $image->filledPolygon($poly,$peachpuff);

=item $image->filledPolygon($polygon,$color);

This draws a polygon filled with the specified color.  Drawing with
the special colors is also permitted. See the documentation for the
line() method for additional details.

  # make a polygon
  $poly = new GD::Polygon;
  $poly->addPt(50,0);
  $poly->addPt(99,99);
  $poly->addPt(0,99);

  # draw the polygon, filling it with a color
  $image->filledPolygon($poly,$peachpuff);

=item $image->polyline(polyline,color)

  $image->polyline($polyline,$black)

This draws a polyline with the specified color.
Both real color indexes and the special 
colors gdBrushed, gdStyled and gdStyledBrushed can be specified.

Neither the polyline() method or the polygon() method are very picky:
you can call either method with either a GD::Polygon or a
GD::Polyline.  The I<method> determines if the shape is "closed" or
"open" as drawn, I<not> the object type.

=item $image-E<gt>polydraw(polything,color)

	$image->polydraw($poly,$black)

This method draws the polything as expected (polygons are closed,
polylines are open) by simply checking the object type and calling
either $image->polygon() or $image->polyline().

=item $image->ellipse($cx,$cy,$width,$height,$color)

=item $image->filledEllipse($cx,$cy,$width,$height,$color)

These methods() draw ellipses. ($cx,$cy) is the center of the arc, and
($width,$height) specify the ellipse width and height, respectively.
filledEllipse() is like ellipse() except that the former produces
filled versions of the ellipse. Drawing with the special colors is
also permitted. See the documentation for the line() method for
additional details.

=item $image->arc($cy,$cy,$width,$height,$start,$end,$color);

This draws arcs and ellipses.  (cx,cy) are the center of the arc, and
(width,height) specify the width and height, respectively.  The
portion of the ellipse covered by the arc are controlled by start and
end, both of which are given in degrees from 0 to 360.  Zero is at the
top of the ellipse, and angles increase clockwise.  To specify a
complete ellipse, use 0 and 360 as the starting and ending angles.  To
draw a circle, use the same value for width and height.

Internally, arc() calls the ellipse() method of SVG.pm. Drawing with
the special colors is also permitted. See the documentation for the
line() method for additional details.

Currently, true arcs are NOT supported, only those where the start and
end equal 0 and 360 respectively resulting in a closed arc.

=item $image->filledArc($cx,$cy,$width,$height,$start,$end,$color
[,$arc_style])

This method is like arc() except that it colors in the pie wedge with
the selected color.  $arc_style is optional.  If present it is a
bitwise OR of the following constants:

gdArc           connect start & end points of arc with a rounded edge
gdChord         connect start & end points of arc with a straight line
gdPie           synonym for gdChord
gdNoFill        outline the arc or chord
gdEdged         connect beginning and ending of the arc to the center

gdArc and gdChord are mutally exclusive.  gdChord just connects the
starting and ending angles with a straight line, while gdArc pro-
duces a rounded edge. gdPie is a synonym for gdArc. gdNoFill indi-
cates that the arc or chord should be outlined, not filled.  gdEdged,
used together with gdNoFill, indicates that the beginning and ending
angles should be connected to the center; this is a good way to
outline (rather than fill) a "pie slice."

Using these special styles, you can easily draw bordered ellipses and
circles.

# Create the filled shape:
$image->filledArc($x,$y,$width,$height,0,360,$fill);
# Now border it.
$image->filledArc($x,$y,$width,$height,0,360,$color,gdNoFill);

=item $image->fill();

NOT IMPLEMENTED

=item $image->fillToBorder()

NOT IMPLEMENTED

=back

=head2 Image Copying Methods

The basic copy() command is implemented in GD::SVG. You can copy one
GD::SVG into another GD::SVG, or copy a GD::Image or GD::Simple object
into a GD::SVG, thereby embedding a pixmap image into the SVG image.

All other image copying methods are unsupported, and if your script
calls one of the following methods, your script will die remorsefully
with a warning.  With sufficient demand, I might try to implement some
of these methods.  For now, I think that they are beyond the intent of
GD::SVG.

  $image->clone()
  $image->copyMerge()
  $image->copyMergeGray()
  $image->copyResized()
  $image->copyResampled()
  $image->trueColorToPalette()

=head2 Image Transfomation Commands

None of the image transformation commands are implemented in GD::SVG.
If your script calls one of the following methods, your script will
die remorsefully with a warning.  With sufficient demand, I might try
to implement some of these methods.  For now, I think that they are
beyond the intent of GD::SVG.

  $image = $sourceImage->copyRotate90()
  $image = $sourceImage->copyRotate180()
  $image = $sourceImage->copyRotate270()
  $image = $sourceImage->copyFlipHorizontal()
  $image = $sourceImage->copyFlipVertical()
  $image = $sourceImage->copyTranspose()
  $image = $sourceImage->copyReverseTranspose()
  $image->rotate180()
  $image->flipHorizontal()
  $image->flipVertical()

=head2 Character And String Drawing

GD allows you to draw characters and strings, either in normal
horizon- tal orientation or rotated 90 degrees.  In GD, these routines
use a GD::Font object.  Internally, GD::SVG mimics the behavior of GD
with respect to fonts in a very similar manner, using instead a
GD::SVG::Font object described in more detail below.

GD's font handling abilities are not as flexible as SVG and it does
not allow the dynamic creation of fonts, instead exporting five
available fonts as global variables: gdGiantFont, gdLargeFont,
gdMediumBoldFont, gdSmallFont and gdTinyFont. GD::SVG also exports
these same global variables but establishes them in a different manner
using constant variables to establish the font family, font height and
width of these global fonts.  These values were chosen to match as
closely as possible GD's output.  If unsatisfactory, adjust the
constants at the top of this file.  In all subroutines below, GD::SVG
passes a generic GD::SVG::Font object in place of the exported font
variables.

=over 4

=item $image->string($font,$x,$y,$string,$color)

This method draws a string starting at position (x,y) in the speci-
fied font and color.  Your choices of fonts are gdSmallFont,
gdMediumBoldFont, gdTinyFont, gdLargeFont and gdGiantFont.

  $myImage->string(gdSmallFont,2,10,"Peachy Keen",$peach);

=item $image->stringUp($font,$x,$y,$string,$color)

Same as the previous example, except that it draws the text rotated
counter-clockwise 90 degrees.

=item $image->char($font,$x,$y,$char,$color)

=item $image->charUp($font,$x,$y,$char,$color)

These methods draw single characters at position (x,y) in the spec-
ified font and color.  They're carry-overs from the C interface, where
there is a distinction between characters and strings.  Perl is
insensible to such subtle distinctions. Neither is SVG, which simply
calls the string() method internally.

=item @bounds = $image->stringFT($fgcolor,$font-
       name,$ptsize,$angle,$x,$y,$string)

=item @bounds = $image->stringFT($fgcolor,$font-
       name,$ptsize,$angle,$x,$y,$string,\%options)

In GD, these methods use TrueType to draw a scaled, antialiased
strings using the TrueType font of your choice. GD::SVG can handle
this directly generating by calling the string() method internally. 

  The arguments are as follows:

  fgcolor    Color index to draw the string in
  fontname   An absolute path to the TrueType (.ttf) font file
  ptsize     The desired point size (may be fractional)
  angle      The rotation angle, in radians
  x,y        X and Y coordinates to start drawing the string
  string     The string itself

GD::SVG attempts to extract the name of the font from the pathname
supplied in the fontname argument. If it fails, Helvetica will be used
instead.

If successful, the method returns an eight-element list giving the
boundaries of the rendered string:

  @bounds[0,1]  Lower left corner (x,y)
  @bounds[2,3]  Lower right corner (x,y)
  @bounds[4,5]  Upper right corner (x,y)
  @bounds[6,7]  Upper left corner (x,y)

This from the GD documentation (not yet implemented in GD::SVG):

An optional 8th argument allows you to pass a hashref of options to
stringFT().  Two hashkeys are recognized: linespacing, if present,
controls the spacing between lines of text.  charmap, if present, sets
the character map to use.

The value of linespacing is supposed to be a multiple of the char-
acter height, so setting linespacing to 2.0 will result in double-
spaced lines of text.  However the current version of libgd (2.0.12)
does not do this.  Instead the linespacing seems to be double what is
provided in this argument.  So use a spacing of 0.5 to get separation
of exactly one line of text.  In practice, a spacing of 0.6 seems to
give nice results.  Another thing to watch out for is that successive
lines of text should be separated by the "\r\n" characters, not just
"\n".

The value of charmap is one of "Unicode", "Shift_JIS" and "Big5".  The
interaction between Perl, Unicode and libgd is not clear to me, and
you should experiment a bit if you want to use this feature.

  $gd->stringFT($black,'/dosc/windows/Fonts/pala.ttf',40,0,20,90,
                "hi there\r\nbye now",
                {linespacing=>0.6,
                 charmap  => 'Unicode',
               });

For backward compatibility with older versions of the FreeType
library, the alias stringTTF() is also recognized.  Also be aware that
relative font paths are not recognized due to problems in the libgd
library.

=item $hasfontconfig = $image-E<gt>useFontConfig($flag)

Call useFontConfig() with a value of 1 in order to enable support for
fontconfig font patterns (see stringFT).  Regardless of the value of
$flag, this method will return a true value if the fontconfig library
is present, or false otherwise.

NOT IMPLEMENTED

=back

=head2 Alpha Channels

=over 4

=item $image->alphaBlending($blending)

NOT IMPLEMENTED

=item $image->saveAlpha($saveAlpha)

NOT IMPLEMENTED

=back

=head2 Miscellaneous Image Methods

=over 4

=item $image->interlaced([$flag])

NOT IMPLEMENTED

=item ($width,$height) = $image->getBounds()

getBounds() returns the height and width of the image.

=item $is_truecolor = $image->isTrueColor()

NOT IMPLEMENTED

=item $flag = $image1->compare($image2)

NOT IMPLEMENTED

=item $image->clip($x1,$y1,$x2,$y2)
       ($x1,$y1,$x2,$y2) = $image->clip

NOT IMPLEMENTED

=item $flag = $image->boundsSafe($x,$y)

NOT IMPLEMENTED

=back

=head1 GD::SVG::Polygon METHODS

SVG is much more adept at creating polygons than GD. That said, GD
does provide some rudimentary support for polygons but must be created
as seperate objects point by point.

=over 4

=item $poly = GD::SVG::Polygon->new

Create an empty polygon with no vertices.

  $poly = new GD::SVG::Polygon;

=item $poly->addPt($x,$y)

Add point (x,y) to the polygon.

  $poly->addPt(0,0);
  $poly->addPt(0,50);
  $poly->addPt(25,25);

=item ($x,$y) = $poly->getPt($index)

Retrieve the point at the specified vertex.

  ($x,$y) = $poly->getPt(2);

=item $poly->setPt($index,$x,$y)

Change the value of an already existing vertex.  It is an error to set
a vertex that isn't already defined.

  $poly->setPt(2,100,100);

=item ($x,$y) = $poly->deletePt($index)

Delete the specified vertex, returning its value.

  ($x,$y) = $poly->deletePt(1);

=item $poly->toPt($dx,$dy)

Draw from current vertex to a new vertex, using relative (dx,dy)
coordinates.  If this is the first point, act like addPt().

  $poly->addPt(0,0);
  $poly->toPt(0,50);
  $poly->toPt(25,-25);

NOT IMPLEMENTED

=item $vertex_count = $poly->length()

Return the number of vertices in the polygon.

=item @vertices = $poly->vertices()

Return a list of all the verticies in the polygon object.  Each mem-
ber of the list is a reference to an (x,y) array.

  @vertices = $poly->vertices;
  foreach $v (@vertices)
      print join(",",@$v),"\n";
  }

=item @rect = $poly->bounds()

Return the smallest rectangle that completely encloses the polygon.
The return value is an array containing the (left,top,right,bottom) of
the rectangle.

  ($left,$top,$right,$bottom) = $poly->bounds;

=item $poly->offset($dx,$dy)

Offset all the vertices of the polygon by the specified horizontal
(dh) and vertical (dy) amounts.  Positive numbers move the polygon
down and to the right. Returns the number of vertices affected.

  $poly->offset(10,30);

=item $poly->map($srcL,$srcT,$srcR,$srcB,$destL,$dstT,$dstR,$dstB)

Map the polygon from a source rectangle to an equivalent position in a
destination rectangle, moving it and resizing it as necessary.  See
polys.pl for an example of how this works.  Both the source and
destination rectangles are given in (left,top,right,bottom) coordi-
nates.  For convenience, you can use the polygon's own bounding box as
the source rectangle.

  # Make the polygon really tall
  $poly->map($poly->bounds,0,0,50,200);

NOT IMPLEMENTED

=item $poly->scale($sx,$sy)

Scale each vertex of the polygon by the X and Y factors indicated by
sx and sy.  For example scale(2,2) will make the polygon twice as
large.  For best results, move the center of the polygon to position
(0,0) before you scale, then move it back to its previous position.

NOT IMPLEMENTED

=item $poly->transform($sx,$rx,$sy,$ry,$tx,$ty)

Run each vertex of the polygon through a transformation matrix, where
sx and sy are the X and Y scaling factors, rx and ry are the X and Y
rotation factors, and tx and ty are X and Y offsets.  See the Adobe
PostScript Reference, page 154 for a full explanation, or experiment.

NOT IMPLEMENTED

=back

=head2 GD::Polyline

Please see GD::Polyline for information on creating open polygons and
splines.

=head1 GD::SVG::Font METHODS

NOTE: The object-oriented implementation to font utilites is not yet
supported.

The libgd library (used by the Perl GD library) has built-in support
for about half a dozen fonts, which were converted from public-domain
X Windows fonts.  For more fonts, compile libgd with TrueType support
and use the stringFT() call.

GD::SVG replicates the internal fonts of GD by hardcoding fonts which
resemble the design and point size of the original.  Each of these
fonts is available both as an imported global (e.g. gdSmallFont) and
as a package method (e.g. GD::Font->Small).

=over 4

=item gdTinyFont

=item GD::Font->Tiny

This is a tiny, almost unreadable font, 5x8 pixels wide.

=item gdSmallFont

=item GD::Font->Small

This is the basic small font, "borrowed" from a well known public
domain 6x12 font.

=item gdMediumBoldFont

=item GD::Font->MediumBold

This is a bold font intermediate in size between the small and large
fonts, borrowed from a public domain 7x13 font;

=item gdLargeFont

=item GD::Font->Large

This is the basic large font, "borrowed" from a well known public
domain 8x16 font.

=item gdGiantFont

=item GD::Font->Giant

This is a 9x15 bold font converted by Jan Pazdziora from a sans serif
X11 font.

=item $font->nchars

This returns the number of characters in the font.

  print "The large font contains ",gdLargeFont->nchars," characters\n";

NOT IMPLEMENTED

=item $font->offset()

This returns the ASCII value of the first character in the font

=item $width = $font->width

=item $height = $font->height

These return the width and height of the font.

  ($w,$h) = (gdLargeFont->width,gdLargeFont->height);

=back

=head1 REAL WORLD EXAMPLES

=over 4

=item BioPerl

The Bio::Graphics package of the BioPerl project makes use of GD::SVG
to export SVG graphics.

  http://www.bioperl.org/

=item Generic Genome Browser

The Generic Genome Browser (GBrowse) utilizes Bio::Graphics and
enables SVG dumping of genomics views. You can see a real-world
example of SVG output from GBrowse at WormBase:

  http://www.wormbase.org/cgi-bin/gbrowse/

Further information about the Generic Genome Browser is available at
the Generic Model Organism Project home page:

  http://www.gmod.org/

=item toddot

I've also prepared a number of comparative images at my website
(shameless plug, hehe):

  http://www.toddot.net/projects/GD-SVG/

=back

=head1 INTERNAL METHODS

The following internal methods are private and documented only for
those wishing to extend the GD::SVG interface.

=over 4

=item _distill_gdSpecial()

When a drawing method is passed a stylized brush via gdBrushed, the
internal _distill_gdSpecial() method attempts to make sense of this by
setting line thickness and foreground color. Since stylized brushes
are GD::SVG::Image objects, it does this by fetching the width of the
image using the getBounds method. This width is then used to
setThickness.  The last color set by colorAllocate is then used for
the foreground color.

In setting line thickness, GD::SVG temporarily overrides any
previously set line thickness.  In GD, setThickness is persistent
through uses of stylized brushes. To accomodate this behavior,
_distill_gdSpecial() temporarily stores the previous line_thickness in
the $self->{previous_line_thickness} flag.

=item _reset()

The _reset() method is used to restore persistent drawing settings
between uses of stylized brushes. Currently, this involves

  - restoring line thickness

=back

=head1 IMPORTANT NOTE! GD::SVG / SVG::GD

A second module (SVG::GD), written by Ronan Oger also provides similar
functionality as this module. Ronan and I are concurrently developing
these modules with an eye towards integrating them in the future. In
principle, the primary difference is that GD::SVG aims to generate SVG
and SVG only.  That is, it:

  1. Does not store an internal representation of the GD image

  2. Does not enable JPG, PNG, OR SVG output from a single pass
     through data

  3. Only occasioanally uses inherited methods from GD

Instead GD::SVG depends on the user to choose which output format they
would like in advance, "use"ing the appropriate module for that
output. As described at the start of this document, module selection
between GD and GD::SVG can be made dynamically using eval statements
and variables for the differnet classes that GD and GD::SVG create.

There is a second reason for not maintaining a double representation
of the data in GD and SVG format: SVG documents can quickly become
very large, especially with large datasets. In cases where scripts are
primarily generating png images in a server environment and would only
occasionally need to export SVG, gernerating an SVG image in parallel
would result in an unacceptable performance hit.

Thus GD::SVG aims to be a plugin for existing configurations that
depend on GD but would like to take advantage of SVG output.

SVG::GD, on the other hand, aims to tie in the raster-editing ability
of GD with the power of SVG output. In part, it aims to do this by
inheriting many methods from GD directly and bringing them into the
functional space of GD.  This makes SVG::GD easier to set up initially
(simply by adding the "use SVG::GD" below the "use GD" statement of
your script. GD::SVG sacrfices this initial ease-of-setup for more
targeted applications.

=head1 ACKNOWLEDGEMENTS

Lincoln Stein, my postdoctoral mentor, author of GD.pm, and all around
Perl stud. Ronan Oger, author of SVG.pm conceptualized and implemented
another wrapper around GD at about the exact same time as this module.
He also provided helpful discussions on implementing GD functions into
SVG.  Oliver Drechsel and Marc Lohse provided patches to actually
make the stringUP method functional.

=head1 AUTHOR

Todd Harris, PhD E<lt>harris@cshl.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright @ 2003-2005 Todd Harris and the Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD>,
L<SVG>,
L<SVG::Manual>,
L<SVG::DOM>

=cut
