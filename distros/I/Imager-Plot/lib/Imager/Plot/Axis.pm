package Imager::Plot::Axis;

use strict;
use vars qw();

use Imager;

use Imager::Plot::Util;
use Imager::Plot::DataSet;


############################################
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
# |    |   |   |   |   |   |   |   |   |   #
############################################

my $black = Imager::Color->new(0,0,0,255);
my $blue  = Imager::Color->new(0,0,70,255);
my $white = Imager::Color->new(255,255,255,255);

sub gfont {
  my $fname = shift;
  if (ref($fname)) {
    return $fname;
  } else {
    my $font = Imager::Font->new(file => $fname, size=>10,color=>$black);
    die "Unable to load font $fname for Axis labels\n" unless $font;
    return $font;
  }
}


sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %temp = @_;
  my $fname = $temp{'GlobalFont'};

  my %opts=(
	    Width          => undef,   # width includes axis drawing
	    Height         => undef,   # height and the endpoints
	    XRANGE         => undef,
	    YRANGE         => undef,
	    XDRANGE        => undef,
	    YDRANGE        => undef,
	    DATASETS       => [],
	    XGRIDLIST      => [],
	    YGRIDLIST      => [],
	    grid           => 1,
	    make_decor     => \&make_decor,
	    make_ranges    => \&make_ranges,
	    make_xrange    => \&make_xrange,
	    make_yrange    => \&make_yrange,
	    make_xticklist => \&nothing,
	    make_yticklist => \&nothing,
	    make_xgridlist => \&MakeXGridList,
	    make_ygridlist => \&MakeYGridList,
	    XtickFont      => gfont($fname),
	    YtickFont      => gfont($fname),
	    BackGround     => $white,
	    FrameColor     => $black,
	    XgridShow	   => 1,
	    YgridShow	   => 1,
	    YgridNum	   => 5,
	    XgridNum	   => 5,
	    XtickMargin	   => 3,
	    YtickMargin	   => 3,
	    Border         => "lrtb", #rt",	# left, right, top, bottom
	    Xformat        => \&myround,
	    Yformat        => \&myround,
	    @_);
  my $self  = \%opts;

  bless ($self, $class);
  return $self;
}

sub AddDataSet {
  my $self = shift;
  my $hint = @{$self->{DATASETS}};
  my $dataset = Imager::Plot::DataSet->new(@_, hint=>$hint);
  push(@{$self->{DATASETS}}, $dataset);
  return $dataset;
}


sub setparm {
  my $self = shift;
  my %np=@_;
  for (keys %np) {
    $self->{$_}=$np{$_};
  }
}

sub CheckValues {
  my $self = shift;
}

# gets the cumulative bounding box

sub data_bbox {
  my $self = shift;
  my @tbox = map { [ $_->data_bbox() ] } @{$self->{DATASETS}};

  my @bbox = @{shift @tbox};
  for my $cb (@tbox) {
    $bbox[0]= $cb->[0] if $cb->[0]<$bbox[0];
    $bbox[1]= $cb->[1] if $cb->[1]>$bbox[1];
    $bbox[2]= $cb->[2] if $cb->[2]<$bbox[2];
    $bbox[3]= $cb->[3] if $cb->[3]>$bbox[3];
  }

  return @bbox;
}

sub MakeMap {
  my ($oldmin, $oldmax, $newmin, $newmax) = @_;
  return sub { map { ($_-$oldmin)/($oldmax-$oldmin)*($newmax-$newmin)+$newmin } @_; }
}

# Axis Rendering routines

# Axis::render calls render_tick and RenderGrid
#

# render

sub Render {
  my $self = shift;
  my %opts = (%{$self},@_);
  my ($xs, $ys, $xmin,$ymin,$xmax,$ymax);

  my $img = $opts{Image};

  $xmin = $opts{Xoff};
  $xmax = $opts{Xoff} + $self->{Width};
  $ymin = $opts{Yoff} - $self->{Height};
  $ymax = $opts{Yoff};

  $self->{make_decor}->($self);

  my $Xmapper = MakeMap(@{$self->{XRANGE}}, $xmin+1, $xmax);
  my $Ymapper = MakeMap(@{$self->{YRANGE}}, $ymax, $ymin+1);

  if ($self->{BackGround}) {
    $img->box(color => $self->{BackGround},
	      xmin  => $xmin,
	      ymin  => $ymin,
	      xmax  => $xmax,
	      ymax  => $ymax,
	      filled=> 1);
  }

  $self->RenderGrid(Image  => $img,
		    Xmapper=> $Xmapper,
		    Ymapper=> $Ymapper,
		    Xoff   => $opts{Xoff},
		    Yoff   => $opts{Yoff},
		    XgridShow => $opts{XgridShow},
		    YgridShow => $opts{YgridShow},
		   );


  # Draw the Axis edges
  if (index($self->{'Border'}, "l")>-1) {
    $img->line(color => $self->{FrameColor},
	       x1 => $xmin,
	       y1 => $ymin,
	       x2 => $xmin,
	       y2 => $ymax);
  }
  if (index($self->{'Border'}, "r")>-1) {
    $img->line(color => $self->{FrameColor},
	       x1 => $xmax,
	       y1 => $ymin,
	       x2 => $xmax,
	       y2 => $ymax+1);
  }
  if (index($self->{'Border'}, "b")>-1) {
    $img->line(color => $self->{FrameColor},
	       x1 => $xmin,
	       y1 => $ymax,
	       x2 => $xmax,
	       y2 => $ymax);
  }
  if (index($self->{'Border'}, "t")>-1) {
    $img->line(color => $self->{FrameColor},
	       x1 => $xmin,
	       y1 => $ymin,
	       x2 => $xmax,
	       y2 => $ymin);
  }

  for my $DataSet (@{$self->{DATASETS}}) {
    $DataSet->Draw(Image   => $img,
		   Xmapper => $Xmapper,
		   Ymapper => $Ymapper,
		   x1 => $xmin+1,
		   y1 => $ymin,
		   x2 => $xmax,
		   y2 => $ymax
                   );
  }

  $self->RenderTickLabels(Image  => $img,
			  Xmapper=> $Xmapper,
			  Ymapper=> $Ymapper,
			  %opts,
			 );
}



sub trn {
  sprintf("%g",sprintf("%.0e",shift));
}


sub RenderGrid {
  my $self = shift;
  my %opts  = @_;
  my $xgridc;
  my $ygridc = $xgridc = i_color_new(140,140,140,0);
  my $img = $opts{Image};

  my $ymin = $opts{Yoff} - $self->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->{Width};

  if($opts{XgridShow}) {
    my @XGrid = $opts{Xmapper}->(@{$self->{XGRIDLIST}});
    for my $xx (@XGrid) {
      $img->polyline(y=>[$ymin,$ymax],x=>[$xx,$xx],color=>$xgridc);
    }
  }

  if($opts{YgridShow}) {
    my @YGrid = $opts{Ymapper}->(@{$self->{YGRIDLIST}});
    for my $yy (@YGrid) {
      $img->polyline(y=>[$yy,$yy],x=>[$xmin,$xmax],color=>$xgridc);
    }
  }
}

# now incorrectly uses the Grid points

sub RenderTickLabels {

  my $self = shift;
  my %opts = @_;
  my $img  = $opts{Image};

  my $ymin = $opts{Yoff} - $self->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->{Width};

  my @XGrid = $opts{Xmapper}->(@{$self->{XGRIDLIST}});
  my @YGrid = $opts{Ymapper}->(@{$self->{YGRIDLIST}});

  my $font  = $self->{XtickFont};

  for my $xi (0..@XGrid-1) {
    my $xx = $XGrid[$xi];
    my $xv = $self->{XGRIDLIST}->[$xi];

    my $string = $self->{Xformat}->($xv);

    my ($neg_width,
	$global_descent,
	$pos_width,
	$global_ascent,
	$descent,
	$ascent) = $font->bounding_box(string=>$string);

    my $x = $xx-($neg_width+$pos_width)/2;
    my $ay = 0;

    if(ref($opts{XtickMarker}) eq 'HASH') {
      my %style = %{$opts{XtickMarker}};

      if($style{symbol} eq 'line') {
	my $ystart = $ymax;
	if($style{align} eq 'center') {
	  $ystart -= int($style{size} / 2);
	  $ay = int($style{size} / 2);
	} elsif($style{align} eq 'top') {
	  $ystart -= $style{size};
	} else {
	  $ay = $style{size};
	}

	my $mcolor = $style{color} || $self->{FrameColor};

	$img->line(color => $mcolor,
		   x1 => $xx,
		   x2 => $xx,
		   y1 => $ystart,
		   y2 => $ystart + $style{size},
		   antialias => $style{antialias}
		  );
      }
    }

    $img->string(font => $font,
		 text => $string,
		 x    => $xx-($neg_width+$pos_width)/2,
		 y    => $ymax+$global_ascent+3+$opts{XtickMargin} + $ay,
		 aa   => 1);
  }

  $font = $self->{YtickFont};

  for my $yi (0..@YGrid-1) {
    my $yy = $YGrid[$yi];
    my $yv = $self->{YGRIDLIST}->[$yi];

    my $string = $self->{Yformat}->($yv);

    my ($neg_width,
	$global_descent,
	$pos_width,
	$global_ascent,
	$descent,
	$ascent) = $font->bounding_box(string=>$string);

    my $ax = 0;

    if(ref($opts{YtickMarker}) eq 'HASH') {
      my %style = %{$opts{XtickMarker}};

      if($style{symbol} eq 'line') {
	my $xstart = $xmin - $style{size};
	if($style{align} eq 'center') {
	  $xstart += int($style{size} / 2);
	  $ax = int($style{size} / 2);
	} elsif($style{align} eq 'left') {
	  $xstart = $xmin;
	} else {
	  $ax = $style{size};
	}

	my $mcolor = $style{color} || $self->{FrameColor};

	$img->line( color => $mcolor,
		    x1 => $xstart,
		    x2 => $xstart + $style{size},
		    y1 => $yy,
		    y2 => $yy,
		    antialias => $style{antialias}
		  );
      }
    }

    $img->string(font => $font,
		 text => $string,
		 x    => $xmin-$pos_width-3 - $self->{YtickMargin} - $ax,
		 y    => $yy+($ascent+$descent)/2,
		 aa   => 1);
  }
}








# data set style description:

# $style->{line}->{color=>$color, antialias=>0};
# $style->{marker}->{color=>$color, symbol=>"circle"};
# coderef decides if text goes with that point



sub make_dranges {
  my $self = shift;
  my @bbox = $self->data_bbox();
  $self->{XDRANGE} = [@bbox[0,1]];
  $self->{YDRANGE} = [@bbox[2,3]];
}

sub make_xrange {
  my $self = shift;
  $self->{XRANGE} = [@{$self->{XDRANGE}}];
}

sub make_yrange {
  my $self = shift;
  $self->{YRANGE} = [@{$self->{YDRANGE}}];
}

sub make_ranges {
  my $self = shift;
  $self->make_dranges(); # real member function
  $self->{make_xrange}->($self);
  $self->{make_yrange}->($self);
}

sub nothing {}

sub MakeXGridList {
  my $self = shift;
  my ($min, $max)  = @{$self->{XRANGE}};
  my $d  = ($max-$min)/$self->{XgridNum};
  my $d2 = trn($d);
  my (@rc,$i);

  $i = sprintf("%.0f",$min/$d2)*$d2;
  while ( 1 ) {
    push(@rc,$i) if($i >= $min);
    $i+=$d2;
    last if $i > $max;
  }

  if (($rc[0]-$min) < 0.01*($max-$min)) {
    shift(@rc);
  }
  if ($max-($rc[-1]) < 0.01*($max-$min)) {
#    print "$min $max $rc[-1]\n";
    pop(@rc);
  }

  $self->{XGRIDLIST} = \@rc;
}

sub MakeYGridList {
  my $self = shift;
  my ($min, $max)  = @{$self->{YRANGE}};
  my $d  = ($max-$min)/$self->{YgridNum};
  my $d2 = trn($d);
  my (@rc,$i);

  $i = sprintf("%.0f",$min/$d2)*$d2;
  while ( 1 ) {
    push(@rc,$i) if($i >= $min);
    $i+=$d2;
    last if $i > $max;
  }

  if (($rc[0]-$min) < 0.01*($max-$min)) {
    shift(@rc);
  }
  if ($max-($rc[-1]) < 0.01*($max-$min)) {
    pop(@rc);
  }
  $self->{YGRIDLIST} = \@rc;
}


sub make_decor {
  my $self = shift;
  $self->{make_ranges}   ->($self);
  $self->{make_xticklist}->($self);
  $self->{make_yticklist}->($self);
  $self->{make_xgridlist}->($self);
  $self->{make_ygridlist}->($self);
}



1;


__END__
  # Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Imager::Plot::Axis - Axis handling of Imager::Plot.

=head1 SYNOPSIS

  use Imager;
  use Imager::Plot::Axis;

  # Create our dummy data
  @X = 0..10;
  @Y = map { $_**3 } @X;

  # Create Axis object

  $Axis = Imager::Plot::Axis->new(Width => 200, Height => 180, GlobalFont=>"ImUgly.ttf");
  $Axis->AddDataSet(X => \@X, Y => \@Y);

  $Axis->{XgridShow} = 1;  # Xgrid enabled
  $Axis->{YgridShow} = 0;  # Ygrid disabled

  $Axis->{Border} = "lrb"; # left right and bottom edges

  # See Imager::Color manpage for color specification
  $Axis->{BackGround} = "#cccccc";

  # Override the default function that chooses the x range
  # of the graph, similar exists for y range

  $Axis->{make_xrange} = sub {
      $self = shift;
      my $min = $self->{XDRANGE}->[0]-1;
      my $max = $self->{XDRANGE}->[1]+1;
      $self->{XRANGE} = [$min, $max];
  };

  $img = Imager->new(xsize=>600, ysize => 400);
  $img->box(filled=>1, color=>"white");

  $Axis->Render(Xoff=>50, Yoff=>370, Image=>$img);

  $img->write(file=>"foo.ppm") or die $img->errstr;



=head1 DESCRIPTION

This part of Imager::Plot takes care of managing the graph area
itself.  It handles the grid, tickmarks, background in axis area and
the data sets of course.  All the data sets have to be given to the
Axis object before rendering it so that everything is only written
only once and scaling of axis can be done automatically.  This also
helps in doing chartjunk tricks like shadows.

The size of the Axis area is controlled by the Width and Height
parameters of the C<new> method.  The border region/frame of the axis
is considered to lie in the coordinate system.  The default order of
drawing is the following: Background image, grid, frame, ticks.

Note that the Axis currently renders the ticklabels.  This might
change in the near future.













=head1 AUTHOR

Arnar M. Hrafnkelsson, addi@umich.edu

=head1 SEE ALSO
Imager, Imager::Plot, Imager::DataSet, Imager::Style
perl(1).

=cut

