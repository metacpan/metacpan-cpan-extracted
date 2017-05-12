package GO::View::GD;

#######################################################################
# Module Name  :  GO/View/GD.pm
#
# Date created :  Oct. 2003
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#######################################################################

=pod

=head1 NAME

GO::View::GD - a helper class for GO::View to deal with the image

=head1 SYNOPSIS

use GO::View::GD;

To instantiate a new GO::View::GD object, you may use  
following syntax:

    my $gd = GO::View::GD->new(width  => $imgWidth,
                               height => $imgHeight);               


my $im = $gd->im;
my $white = $gd->white;
my $red = $gd->red;

and more ......     

=cut

use strict;
use warnings;
use GD;

use vars qw ($PACKAGE $VERSION);

$PACKAGE = "GO::View::GD";
$VERSION = 0.11;

#######################################################################
sub new {      ############ constructor ###############################
#######################################################################

=head2 new

  Title    : new
  Function : Creates a new GO::View::GD object
           : recognized named parameters are height and width
             both of which must be provided.
  Returns  : a GO::View::GD object
  Args     : the named parameters

=cut
       
    my ($class, %args) = @_;

    my $self = {};

    bless $self, $class;
    
    if (!$args{'width'} || !$args{'height'}) {

	die "The image width and height must be passed to $PACKAGE.";
	
    }

    $self->{'_im'} = new GD::Image($args{'width'}, $args{'height'});

    $self->{'_width'} = $args{'width'};
    $self->{'_height'} = $args{'height'};

    $self->_initColors;

    return $self;
}

#######################################################################
sub _initColors {
#######################################################################
# This private method simply initializes some colors, and stores them within
# the object for subsequent retrieval

    my ($self) = @_;

    $self->{'_white'}  = $self->im->colorAllocate(255, 255, 255);
    $self->{'_white1'} = $self->im->colorAllocate(254, 254, 254);
    
    $self->{'_black'} = $self->im->colorAllocate(0, 0, 0);

    $self->{'_blue'}  = $self->im->colorAllocate(0, 0, 255);
    $self->{'_blue1'} = $self->im->colorAllocate(0, 0, 125);
    $self->{'_blue2'} = $self->im->colorAllocate(0, 255, 255);
    $self->{'_blue3'} = $self->im->colorAllocate(0, 204, 204);
    $self->{'_blue4'} = $self->im->colorAllocate(80, 153, 255);
    $self->{'_blue5'} = $self->im->colorAllocate(128, 156, 201);

    $self->{'_lightBlue'} = $self->im->colorAllocate(127, 255, 255);
    $self->{'_darkBlue'} = $self->im->colorAllocate(10, 80, 161);
    
    $self->{'_darkGreen'} = $self->im->colorAllocate(47, 79, 47);
    $self->{'_green'}     = $self->im->colorAllocate(0, 255, 0);
    $self->{'_green1'}    = $self->im->colorAllocate(51, 160, 44);
    $self->{'_green2'}    = $self->im->colorAllocate(102, 255, 102);
    $self->{'_green3'}    = $self->im->colorAllocate(153, 212, 127);
    $self->{'_green4'}    = $self->im->colorAllocate(0, 255, 51);
    $self->{'_green5'}    = $self->im->colorAllocate(102, 153, 102);


    $self->{'_grey'}      = $self->im->colorAllocate(180, 180, 180);
    $self->{'_darkGrey'}  = $self->im->colorAllocate(102, 102, 102);
    $self->{'_lightGrey'} = $self->im->colorAllocate(215, 215, 215);

    $self->{'_magenta'}  = $self->im->colorAllocate(255, 0, 255);
    $self->{'_magenta1'} = $self->im->colorAllocate(255, 153, 255);
    $self->{'_magenta2'} = $self->im->colorAllocate(127, 0, 255);
    $self->{'_magenta3'} = $self->im->colorAllocate(204, 50, 153);
    $self->{'_magenta4'} = $self->im->colorAllocate(188, 128, 189);
    $self->{'_magenta5'} = $self->im->colorAllocate(129, 23, 136);
    

    $self->{'_maroon'} = $self->im->colorAllocate(142, 35, 107);

    $self->{'_orange'}  = $self->im->colorAllocate(255, 175, 0);
    $self->{'_orange1'} = $self->im->colorAllocate(255, 125, 0);
    
    $self->{'_red'}  = $self->im->colorAllocate(255, 0, 0);
    $self->{'_red1'} = $self->im->colorAllocate(255, 152, 153);
    $self->{'_red2'} = $self->im->colorAllocate(204, 0, 102);
    $self->{'_red3'} = $self->im->colorAllocate(153, 0, 0);
    $self->{'_red4'} = $self->im->colorAllocate(251, 128, 95);

    $self->{'_tan1'} = $self->im->colorAllocate(252, 192, 167);
    $self->{'_tan'}  = $self->im->colorAllocate(235, 199, 158);

    $self->{'_yellow'}  = $self->im->colorAllocate(255, 255, 0);
    $self->{'_yellow1'} = $self->im->colorAllocate(255, 204, 51);
    $self->{'_yellow2'} = $self->im->colorAllocate(255, 204, 102);
    $self->{'_yellow3'} = $self->im->colorAllocate(255, 204, 153);

    $self->{'_chartreuse'} = $self->im->colorAllocate(204, 236, 244);

    $self->{'_cenColor'} = $self->im->colorAllocate(0, 10, 10);
    
    $self->{'_sagecolor1'} = $self->im->colorAllocate(255, 127, 0);
    $self->{'_sagecolor2'} = $self->im->colorAllocate(127, 0, 255);
    $self->{'_sagecolor3'} = $self->im->colorAllocate(207, 181, 59);
    $self->{'_sagecolor4'} = $self->im->colorAllocate(204, 50, 153);

   
}

sub im { 

=head2 im

This method returns the internal GD::Image object

=cut

    $_[0]->{'_im'};

}

sub height {

=head2 height

This method returns the height that was used to instantiate the object

=cut

    $_[0]->{'_height'}; 

}

sub width {

=head2 width

This method returns the width that was used to instantiate the object

=cut

    $_[0]->{'_width'};

}

sub white1 { $_[0]->{'_white1'} }
sub black  { $_[0]->{'_black'} }

sub blue  { $_[0]->{'_blue'} }
sub blue1 { $_[0]->{'_blue1'} }
sub blue2 { $_[0]->{'_blue2'} }
sub blue3 { $_[0]->{'_blue3'} }
sub blue4 { $_[0]->{'_blue4'} }
sub blue5 { $_[0]->{'_blue5'} }

sub lightBlue { $_[0]->{'_lightBlue'} }
sub darkBlue  { $_[0]->{'_darkBlue'} }

sub darkGreen { $_[0]->{'_darkGreen'} }
sub green     { $_[0]->{'_green'} }
sub green1    { $_[0]->{'_green1'} }
sub green2    { $_[0]->{'_green2'} }
sub green3    { $_[0]->{'_green3'} }
sub green4    { $_[0]->{'_green4'} }
sub green5    { $_[0]->{'_green5'} }

sub grey      { $_[0]->{'_grey'} }
sub darkGrey  { $_[0]->{'_darkGrey'} }
sub lightGrey { $_[0]->{'_lightGrey'} }

sub magenta  { $_[0]->{'_magenta'} }
sub magenta1 { $_[0]->{'_magenta1'} }
sub magenta2 { $_[0]->{'_magenta2'} }
sub magenta3 { $_[0]->{'_magenta3'} }
sub magenta4 { $_[0]->{'_magenta4'} }
sub magenta5 { $_[0]->{'_magenta5'} }

sub maroon   { $_[0]->{'_maroon'} }

sub orange  { $_[0]->{'_orange'} }
sub orange1 { $_[0]->{'_orange1'} }


sub red  { $_[0]->{'_red'} }
sub red1 { $_[0]->{'_red1'} }
sub red2 { $_[0]->{'_red2'} }
sub red3 { $_[0]->{'_red3'} }
sub red4 { $_[0]->{'_red4'} }

sub tan  { $_[0]->{'_tan'} }
sub tan1 { $_[0]->{'_tan1'} }

sub white { $_[0]->{'_white'} }

sub yellow  { $_[0]->{'_yellow'} }
sub yellow1 { $_[0]->{'_yellow1'} }
sub yellow2 { $_[0]->{'_yellow2'} }
sub yellow3 { $_[0]->{'_yellow3'} }

sub chartreuse { $_[0]->{'_chartreuse'} }

sub cenColor { $_[0]->{'_cenColor'} }

sub sagecolor1 { $_[0]->{'_sagecolor1'} }
sub sagecolor2 { $_[0]->{'_sagecolor2'} }
sub sagecolor3 { $_[0]->{'_sagecolor3'} }
sub sagecolor4 { $_[0]->{'_sagecolor4'} }


=pod

=head2 white1
=head2 black

=head2 blue
=head2 blue1
=head2 blue2
=head2 blue3
=head2 blue4
=head2 blue5

=head2 lightBlue
=head2 darkBlue

=head2 darkGreen
=head2 green
=head2 green1
=head2 green2
=head2 green3
=head2 green4
=head2 green5

=head2 grey
=head2 darkGrey
=head2 lightGrey

=head2 magenta
=head2 magenta1
=head2 magenta2
=head2 magenta3
=head2 magenta4
=head2 magenta5

=head2 maroon

=head2 orange
=head2 orange1


=head2 red
=head2 red1
=head2 red2
=head2 red3
=head2 red4

=head2 tan
=head2 tan1

=head2 white

=head2 yellow
=head2 yellow1
=head2 yellow2
=head2 yellow3

=head2 chartreuse

=head2 cenColor

=head2 sagecolor1
=head2 sagecolor2
=head2 sagecolor3
=head2 sagecolor4

=cut

######################################################################
sub drawFrameWithLabelAndDate { 
######################################################################

=head2 drawFrameWithLabelAndDate

This method draws a blue frame around the image with date at the right
bottom corner and image label on the left bottom corner if there is a
label passed in.  The date and label will be printed in red

Usage:

   $gd->drawFrameWithLabelAndDate;

Optional arguments:

'date', which is a string indicating the date, otherwise the current
date will be determined and used.  The date will be printed in red in
the lower right hand corner.

'text', which is a string that can be used to label the image.  This will 
printed in the lower left hand corner of the image.

=cut

    my ($self, %args) = @_;

    my $date = $args{'date'};
    
    $self->im->rectangle(0, 0, $self->width - 1, $self->height - 1, $self->blue);

    if (!$date) {

	$date = localtime; # gives us something like : Wed Dec  3 14:52:53 2003

	# now grab the month, day, and year, and reformat

	$date =~ s/^[^ ]+ +([^ ]+) +([0-9]+) .+ ([0-9]+)$/$1 $2\, $3/;

    }

    if ($args{'text'}) { 

	$self->im->string(gdSmallFont, 5, $self->height-15, $args{'text'}, $self->red);

    }

    $self->im->string(gdSmallFont, $self->width - length($date) * 6-10, 
		      $self->height-15, $date, $self->red);	

}

######################################################################
sub drawBar {
######################################################################

=head2 drawBar

This method draws a rectangle for a given coordinate set and creates a
link for the box if there is a linkUrl passed in.  The link for the
box is in the form of text that can be placed in an image map on an
html page.  The text for that is currently printed to STDOUT.

Usage:

  $gd->drawBar(barColor  => $gd->blue,
	       numX1     => $X1,
	       numX2     => $X2,
	       numY      => $Y,
	       linkUrl   => $linkUrl,
	       barHeight => $barHeight,
	       outline   => 1,
	       arrow     => 'up');

Required Arguments:

barColor     : The color of the box
numX1        : The left-hand x-coordinate of the box
numX2        : The right-hand x-coordinate of the box
numY         : The top y coorinate of the box

Optional Arguments:

strand       : ??? - left over from use in SGDs ORF Map
linkUrl      : A url to which you would like the box to be linked
barHeight    : The height of the box - will be used to determine the bottom
               y-coordinate of the box - default is 4 pixels
outlineColor : The color in which to outline the box
onInfoText   : Information text that can used for mouseovers

arrow        : The type of arrowhead desired on the box.  One of up, down,
               left, right, which indicates the direction in which the arrow
               head should point
arrowHeight  : The height of the arrowhead

=cut

    my ($self, %args) = @_;

    my $barColor = $args{'barColor'} || $self->_handleMissingArgument('barColor'); 
    my $numX1    = $args{'numX1'}    || $self->_handleMissingArgument('numX1');
    my $numX2    = $args{'numX2'}    || $self->_handleMissingArgument('numX2');
    my $numY     = $args{'numY'}     || $self->_handleMissingArgument('numY'); 

    my $linkUrl      = $args{'linkUrl'};
    my $strand       = $args{'strand'};
    my $barHeight    = $args{'barHeight'} || '4';
    my $outlineColor = $args{'outlineColor'};
    my $onInfoText   = $args{'onInfoText'};
    my $arrow        = $args{'arrow'};
    my $arrowHeight  = $args{'arrowHeight'};
    
    my $numY1 = $numY;
    my $numY2 = $numY1 + $barHeight;
    
    $self->_drawBarWithLink($numX1, $numY1, $numX2, $numY2, 
			    $barColor, $linkUrl, $strand, 
			    $onInfoText, $outlineColor);

    if ($arrow) {
	my ($X1, $Y1, $X2, $Y2);
	if ($arrow =~ /up/i) {
	    $X1 = $numX1;
	    $Y1 = $numY1;
	    $X2 = $numX2;
	    $Y2 = $Y1;
	}
	elsif ($arrow =~ /down/i) {
	    $X1 = $numX1;
	    $Y1 = $numY2;
	    $X2 = $numX2;
	    $Y2 = $Y1;
	}
	elsif ($arrow =~ /left/) {
	    $X1 = $numX1;
	    $Y1 = $numY1;
	    $X2 = $X1;
	    $Y2 = $numY2;
	}
	else {
	    $X1 = $numX2;
	    $Y1 = $numY1;
	    $X2 = $X1;
	    $Y2 = $numY2;
	}
	$self->_drawTriangle($barColor, $X1, $Y1, 
			     $X2, $Y1, $arrow, $arrowHeight);
    }

    return $numX2+5; 
    
}


######################################################################
sub drawName {
######################################################################

=head2 drawName

This method draws a string and creates a link for it if there is a
linkUrl passed in.  The link is in the form of text that can be placed
in an image map on an html page.  The text for that is currently
printed to STDOUT.

Usage:

    $gd->drawName(name=>" = GO term with child(ren)",
		  nameColor=>$gd->black,  
		  numX1=>$numX1,
		  numY=>$y-2);

Required Arguments:

name      : The text that should be printed on the image
nameColor : The color in which the text should be written
numX1     : The X-coordinate where the text should be printed
numY      : The Y-coordinate where the text should be printed

Optional Arguments

linkUrl : A url to which you would like the text to be linked

=cut
 
    my ($self, %args) = @_;

    my $name      = $args{'name'}      || $self->_handleMissingArgument('name'); 
    my $nameColor = $args{'nameColor'} || $self->_handleMissingArgument('nameColor');
    my $numX1     = $args{'numX1'}     || $self->_handleMissingArgument('numX1');
    my $numY      = $args{'numY'}      || $self->_handleMissingArgument('numY'); 
    my $linkUrl   = $args{'linkUrl'};
        
    $self->_drawNameWithLink($name, $nameColor,
			     $linkUrl, $numX1, 
			     $numX1+length($name)*6, 
			     $numY, $numY+8);
   
    
    return $numX1+length($name)*6; 
    
}

################################################################
sub imageMap{
################################################################

=head2 imageMap

 Title    : imageMap
 Usage    : my $map = $goView->imageMap;
 Function : returns the text that constitutes an image map for the
            created image.

	    During creation of various glyphs, that have had a URL
	    passed in to which they could link, text that can be used
	    as an image map for the image, within a web page, will be
	    generated.  When all glyphs have been added to the image,
	    you can retrieve the image map text.  It then needs to be
	    wrapped in a <MAP>...</MAP> declaration, and the html that
	    displays the image will need to refer to the image, eg:

	    <MAP NAME='blah'>

	    _IMAGE_MAP_TEXT_HERE_

	    </MAP>
	    <img src='http::/some.url.here/xxx/gif' usemap='#blah'>

	    Note that the map and the usemap tag have the same name.

 Returns  : a string

=cut

#########################################################################

    return $_[0]->{IMAGE_MAP};

}

################################################################
sub _appendToMap{
################################################################

=head2 _appendToMap

This protected method appends the passed in string onto the image
map that is generated for the image that is also created by this
module

Usage:

    $self->_appendToMap($text);

=cut

################################################################

    my ($self, $text) = @_;

    $self->{IMAGE_MAP} .= $text if defined $text;
    
}


#####################################################################
sub _drawTriangle {
#####################################################################
# This method draws a triangle based on the given coordinate set.
#
    my ($self, $color, $numX1, $numY1, $numX2, $numY2, 
	$arrow, $height) = @_;

    if (!$height) {
	if ($arrow =~ /(up|down)/i) {
	    $height = $numX2 - $numX1;
	}
	else {
	    $height = $numY2 - $numY1; 
        }
    }
    my ($numX, $numY, $midX, $midY);
    if ($arrow =~ /up/i) {
	$numX = ($numX1 + $numX2)/2;
	$numY = ($numY1 + $numY2)/2 - $height;
	$midX = $numX;
	$midY = $numY + $height/2;
    }
    elsif ($arrow =~ /down/i) {
	$numX = ($numX1 + $numX2)/2;
	$numY = ($numY1 + $numY2)/2 + $height;
	$midX = $numX;
	$midY = $numY - $height/2;
    }
    elsif ($arrow =~ /left/i) {
	$numX = ($numX1 + $numX2)/2 - $height;
	$numY = ($numY1 + $numY2)/2;
	$midX = $numX - $height/2;
	$midY = $numY;
    }
    else {
	$numX = ($numX1 + $numX2)/2 + $height;
	$numY = ($numY1 + $numY2)/2;
	$midX = $numX + $height/2;
	$midY = $numY;
    }

    $self->im->line($numX1, $numY1, $numX2, $numY2, $color);
    $self->im->line($numX1, $numY1, $numX,  $numY,  $color);
    $self->im->line($numX2, $numY2, $numX,  $numY,  $color);

    $self->im->fillToBorder($midX, $midY, $color, $color);
    
}

######################################################################
sub _drawBarWithLink {
######################################################################
# This method draws a box (bar) with a link.

    my ($self, $numX1, $numY1, $numX2, $numY2, $barColor, 
	$linkUrl, $strand, $onInfoText, $outlineColor) = @_;

    $onInfoText ||= ""; # avoid warnings
    
    if (!$strand) {

	$self->im->filledRectangle($numX1, $numY1, $numX2, $numY2, 
			   $barColor);

	if ($outlineColor) {
	   $self->im->rectangle($numX1, $numY1, $numX2, $numY2, 
			      $outlineColor); 
	}

    }else {

	if (!$outlineColor) { $outlineColor = $barColor; }

	my $midY = ($numY1+$numY2)/2;

	if ($numX2 < $numX1 + 6) {
	    $numX2 = $numX1 + 6;
	}

        if ($strand =~ /^W/i || $strand == 1) {

	    $numX2 -= 4;
	    $self->im->line($numX1, $numY1, $numX1, $numY2, $outlineColor);
	    $self->im->line($numX2, $numY1, $numX2+4, $midY, $outlineColor);
	    $self->im->line($numX2, $numY2, $numX2+4, $midY, $outlineColor);

	}else {

	    $numX1 += 4;
	    $self->im->line($numX2, $numY1, $numX2, $numY2, $outlineColor);
	    $self->im->line($numX1, $numY1, $numX1-4, $midY, $outlineColor);
	    $self->im->line($numX1, $numY2, $numX1-4, $midY, $outlineColor);
	}

	$self->im->line($numX1, $numY1, $numX2, $numY1, $outlineColor);
	$self->im->line($numX1, $numY2, $numX2, $numY2, $outlineColor);	    
	
	$self->im->fillToBorder(($numX1+$numX2)/2, $midY, 
				$outlineColor, $barColor);
	
    }

    if ($linkUrl) {	
	$numX1 = int($numX1);
	$numX2 = int($numX2);
	$numY1 = int($numY1);
	$numY2 = int($numY2);
	$self->_appendToMap("<AREA SHAPE='RECT' COORDS='$numX1,$numY1,$numX2,$numY2' HREF='$linkUrl' title=\"$onInfoText\">\n");	
    }
}

######################################################################
sub _drawNameWithLink {
######################################################################
# This method draws a string with a link.

    my ($self, $name, $nameColor, $linkUrl, $nX1, $nX2, $nY1, $nY2) = @_;

    $self->im->string(gdSmallFont, $nX1, $nY1, $name, $nameColor);

    if ($linkUrl) {

	$nX1 = int($nX1);
	$nX2 = int($nX2);
	$nY1 = int($nY1);
	$nY2 = int($nY2);

	$self->_appendToMap("<AREA SHAPE=\"RECT\" COORDS=\"$nX1,$nY1,$nX2,$nY2\" HREF=\"$linkUrl\">\n");

    }

}


######################################################################
sub _handleMissingArgument {
######################################################################
# This method will die, with a message to indicate which argument is
# missing in which method, etc. if it finds a missing argument.
#

    my ($self, $args) = @_;

    my ($file, $line, $method) = (caller(1))[1..3];

    die "The argument '$args' must be passed to '$method' method.\n".

	"Please add this argument to line $line in $file."; 

}

1; # to keep Perl happy

=pod

=head1 AUTHOR

Shuai Weng (shuai@genome.stanford.edu)

=cut









