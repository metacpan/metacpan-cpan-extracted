# This Source Code and Perl Module Copyright by Arnar M. Hrafnkelsson
# (addi@umich.edu) 2001 (C) This source is released under the same
# terms as Perl, that is GPL and Artistic.  For details see the Perl
# License and the files Copying and Artistic in this Distribution.



# Imager::Plot
#
# Manages the axis position and global labels
#
#

package Imager::Plot;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Imager;
use Imager::Plot::Util;
use Imager::Plot::Axis;


require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.09';


# Plot generation process:
#
# 1. Make all axis.
# 2. Arrange all axis onto plot surface according to hints and coderef
# 3. draw all axis and data in order.
#

# Size determination method:

# If axis is given:
# Ysize = title+topmargin+yaxis+bottommargin+xlabel
# Xsize = ylabel+leftmargin+xaxis+rightmargin
#
# else
# yaxis = Ysize - (title+topmargin+bottommargin+xlabel)
# xaxis = Xsize - (leftmargin+rightmargin)
#







sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts=(
	    Width        => 400, # default size if no image is given
	    Height       => 300,
	    Image        => undef,
	    LeftMargin   => 10,  # This is global 'extra' space, nothing should be painted in it
	    RightMargin  => 10,
	    TopMargin    => 10,
	    BottomMargin => 10,
	    TitleMargin  => 15,
	    XlabelMargin => 10,
	    YlabelMargin => 10,
	    Title        => "",
	    GlobalFont   => undef,
	    Xlabel       => "",
	    Ylabel       => "",
	    @_);

  my $fname = $opts{GlobalFont};
  my $black = Imager::Color->new(0,0,0,0);

  if(!$opts{XlabelFont}) {
      $opts{XlabelFont} = (ref($fname)) ? $fname : Imager::Font->new(file => $fname, size=>12,color=>$black);
  }

  if(!$opts{YlabelFont}) {
      $opts{YlabelFont} = (ref($fname)) ? $fname : Imager::Font->new(file => $fname, size=>12,color=>$black);
  }

  if(!$opts{TitleFont}) {
      $opts{TitleFont}  = (ref($fname)) ? $fname : Imager::Font->new(file => $fname, size=>16,color=>$black);
  }

  my $self  = \%opts;
  bless ($self, $class);
  return $self;
}



sub Set {
  my $self = shift;
  my %np=@_;
  for (keys %np) {
    $self->{$_}=$np{$_};
  }
}

sub SetDimensions {
  my $self = shift;
  if ($self->{Image}) {
    $self->{Width}  = $self->{Image}->getwidth();
    $self->{Height} = $self->{Image}->getheight();
  }

  if ($self->{XAxis} and !$self->{Width}) {
    $self->{Width}  = $self->{XAxis} + $self->{LeftMargin} + $self->{RightMargin} + $self->{YlabelMargin};
  }
  if ($self->{Width} and !$self->{XAxis}) {
    $self->{XAxis} = $self->{Width} - ( $self->{LeftMargin} + $self->{RightMargin} + $self->{YlabelMargin} );
  }

  if ($self->{YAxis} and !$self->{Height}) {
    $self->{Height} = $self->{YAxis} + $self->{TitleMargin} + $self->{TopMargin} + $self->{BottomMargin};
  }
  if ($self->{Height} and !$self->{YAxis}) {
    $self->{YAxis} = $self->{Height} -( $self->{TitleMargin} + $self->{TopMargin} + $self->{BottomMargin} );
  }

}


sub GetAxis {
  my $self = shift;
  $self->SetDimensions();
  if (!defined($self->{AXIS})) {
    $self->{AXIS} = Imager::Plot::Axis->new(Width      => $self->{XAxis},
					    Height     => $self->{YAxis},
					    GlobalFont => $self->{GlobalFont});
  }
  return $self->{AXIS};
}



sub AddDataSet {
  my $self = shift;
  return $self->GetAxis->AddDataSet(@_);
}


sub Render {
  my $self = shift;
  my %opts = @_;

  my $Axis = $self->GetAxis();
  my $Xoff = $opts{Xoff} + $self->{LeftMargin},
  my $Yoff = $opts{Yoff} - $self->{BottomMargin},
  delete $opts{Xoff};
  delete $opts{Yoff};

  $Axis->Render(Xoff => $Xoff,
		Yoff => $Yoff,
		%opts);


  $self->RenderLabels(Xoff   => $Xoff,
		      Yoff   => $Yoff,
		      %opts);
}


sub RenderLabels {

  my $self = shift;
  my %opts = @_;
  my $img  = $opts{Image};

  my $ymin = $opts{Yoff} - $self->GetAxis()->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->GetAxis()->{Width};

  my $xx   = ($xmin+$xmax)/2;

  my $string = $self->{Xlabel};
  my $font   = $self->{XlabelFont};

  my ($neg_width,
      $global_descent,
      $pos_width,
      $global_ascent,
      $descent,
      $ascent) = $font->bounding_box(string=>$string);

  $img->string(font  => $font,
	       text  => $string,
	       x     => $xx-($neg_width+$pos_width)/2,
	       y     => $ymax+$global_ascent+$self->GetAxis()->{'XtickFont'}->{'size'}+$self->{XlabelMargin},
	       aa    => 1);


  $string = $self->{Ylabel};
  $font   = $self->{YlabelFont};

  ($neg_width,
   $global_descent,
   $pos_width,
   $global_ascent,
   $descent,
   $ascent) = $font->bounding_box(string=>$string);

  if ($self->{YlabelPosition} and $self->{YlabelPosition} eq 'center') {
    $img->string(font  => $font,
		 text  => $string,
		 x     => $xmin - ($pos_width - $neg_width) - $self->{YlabelMargin},
		 y     => $ymax - (($ymax - $ymin)/2) - (($descent + $ascent) / 2),
		 aa    => 1);
  } else {
    $img->string(font  => $font,
		 text  => $string,
		 x     => $xmin-10,    # XXX: Fudge factor
		 y     => $ymin-3,     # more fudge
		 aa    => 1);
  }

  $string = $self->{Title};
  $font   = $self->{TitleFont};

  ($neg_width,
   $global_descent,
   $pos_width,
   $global_ascent,
   $descent,
   $ascent) = $font->bounding_box(string=>$string);

  $img->string(font  => $font,
	       text  => $string,
	       x     => ($xmin+$xmax)/2-($neg_width+$pos_width)/2,
	       y     => $ymin-$self->{'YlabelFont'}->{'size'} - $self->{YlabelMargin},
	       aa    => 1);


}






sub PutText {
  my ($self, $x, $y, $string) = @_;
  my $len=length($string);
  my $img = $self->{BImage};

  $img->string(font=>$self->{FONT}, string=>$string, x=>$x, y=>$y) or die $img->errstr;
}





# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
  # Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Imager::Plot - Perl extension for generating fancy graphic plots in color.

=head1 SYNOPSIS

  use Imager;
  use Imager::Plot;

  $plot = Imager::Plot->new(Width  => 550,
  			  Height => 350,
  			  GlobalFont => 'ImUgly.ttf');

  my @X = 0..100;
  my @Y = map { sin($_/10) } @X;
  my @Z = map { 1+cos($_/10) } @X;

  $plot->AddDataSet(X  => \@X, Y => \@Z);
  $plot->AddDataSet(X  => \@X, Y => \@Y,
    		  style=>{marker=>{size   => 2,
    				   symbol => 'circle',
    				   color  => Imager::Color->new('red'),
    			       },
    		      });

  $img = Imager->new(xsize=>600, ysize => 400);
  $img->box(filled=>1, color=>'white');

  $plot->{'Ylabel'} = 'angst';
  $plot->{'Xlabel'} = 'time';
  $plot->{'Title'} = 'Quality time';

  $plot->Render(Image => $img, Xoff => 40, Yoff => 370);
  $img->write(file => "testout.png");


=head1 DESCRIPTION

This is a module for generating fancy raster plots in color.
There is support for drawing multiple datasets on the same plot,
over a background image.  It's even possible to do shadows with
some thinking.

It's also possible to generate clean plots without any chartjunk
at all.

The plot is generated in a few phases.  First the initial
plot object is generated and contains defaults at that
point.  Then datasets are added with possible drawing
specifications.

Most of the actual work is delegated to Imager::Plot::Axis.
See the Imager::Plot::Axis manpage for more information
on how to control grid generation, ranges for data (zoom).

For more on the drawing styles for Datasets see the
Imager::Plot::DataSet manpage.


=head1 AUTHOR

Arnar M. Hrafnkelsson, addi@umich.edu

=head1 SEE ALSO
Imager, Imager::Plot::Axis, Imager::Plot::DataSet, perl(1).

=cut
