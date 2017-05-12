package Microarray::Explorer;

# The explorer class belongs to the package Microarray. It functions as 
# a web viewer for dataset objects from the same package. Following the 
# Model/View/Controller concept, the explorer class is the View/Controller, 
# whereas the dataset class is the Model.

# $Author: sherlock $
# $Revision: 1.20 $
# $Date: 2004/07/15 14:31:20 $
# $Locker: jdemeter

# License information (the MIT license)

# Copyright (c) 2003 Christian Rees, Janos Demeter, John Matese, Gavin
# Sherlock; Stanford University

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


use strict;
use CGI qw/:all/;
use GD;
use vars qw($VERSION);

use Microarray::Config;

$VERSION = "2.0";
$| = 1;

# need this global for switching row color in markup 
my $flip = 1;

### Preferences for zoom, ...   ##################
my $kMaxZoomRowHeight = 25;     # max zoom image ROW height - an arbitrary max of 25 pixels
my $kMinZoomRowHeight = 15;     # min zoom image ROW height - an arbitrary min of 15 pixels
my $kMaxZoomWidth     = 800;    # max zoom image width - an arbitrary max of 800 pixels
my $kPrefZoomColWidth = 10;     # preferred COLUMN width in Zoom window - an arbitrary 10 pixels
my $kExpImgHeight     = 100;    # the minimal height of experiment image in zoom frame
my $kZoomWindowHeight = 100;    # Number of ROWs displayed in Zoom window.

### for the radar window, ...   ##################
my $kMaxRadarHeight      = 500; # max radar image height an arbitrary max of 500 pixels
my $kPrefRadarRowHeight  = 1;   # max radar image ROW height - an arbitrary max of 1 pixels
my $kMaxRadarWidth       = 400; # max radar image width - an arbitrary max of 400 pixels
my $kPrefRadarColWidth   = 1;   # preferred COLUMN width in radar window - an arbitrary 1 pixel
my $kMaxAnnotFieldLength = 150; # max length for a field in the zoom frame to be displayed
my $kRadarMargin         = 20;  # the margin on the right side of the radar frame - affects the
                                # the size of the bracket size as well

### for the search tool ......  ##################
my $kNumberOfMaxHits = 200;     # the max number of hits - result of search - to be displayed

my $BGIMAGE = "toolbarBackground.gif";
my $BRACKET = "dashedLine.gif";

#######################################################################
# Public class methods
#######################################################################

#----------------------------------------------------------------------
sub New {
#----------------------------------------------------------------------
# This is the constructor for the Explorer class.
#
#   Usage:   $explObj = Microarray::Explorer->New( dataset        => $dataset,
#					           config         => $config',
#					           displayConfig  => $displayConfig};
#
#   Here $dataset should be a Microarray::CdtDataset object, $config is a 
#   Microarray::Config object, while $displayConfig is the name of a text file 
#   that contains info concerning how to mark up various elements of gene
#   annotations. It is expected that the displayConfig file will be found in the 
#   $config->gxDataPath directory.

    my $class = shift;

    my $self  = { };

    bless($self, $class);

    $self->_init(@_);

    return $self;

}

#######################################################################
# Public instance methods
#######################################################################

#----------------------------------------------------------------------
sub print_frameset {
#----------------------------------------------------------------------
# This subroutine will print the whole display window anew.
#
#  usage: $explorer->print_frameset();
#
#   
    my $self  = shift;

    # The title of the document

    my $title  = "geneXplorer ".$VERSION." : ".ucfirst($self->_name);

    $title .= " : ".$self->_dataset->width()." Experiments";
    $title .= " : ".$self->_dataset->height()." Genes";

    # Construct the url: 

    my $url  = $self->{'info'}->{'url'};

    $url .= $self->{'info'}->{'scriptname'};
    $url .= "?n=";
    $url .= $self->_name;
    $url .= $self->{'info'}->{'url_params'};

    # The width of the radar frame depends on the number of experiments 

    my $radarFrameWidth = (($self->_dataset->width() * $self->_radar_x) + $kRadarMargin);

    # the toolbar is 100 pixels high

    my $toolBarHeight = 100;

    print title($title);

    print frameset({-cols         => "$radarFrameWidth, *",
		    -marginheight => '0',
		    -marginwidth  => '0',
		    -frameborder  => '1',
		    -frameborder  => 'yes',
		    -resize       => 'no',
		    -border       =>  '3'},

		   frame({'-name'      => 'r',
			  -src         => $url."&a=r",
			  -marginwidth => 0,
			  -marginheight=> 0,
			  -border      => 1,
			  -scrolling   => "no"}
			 ),
		   "\n",

		   frameset({-rows         => "$toolBarHeight, *", 
			     -framespacing => '0',
			     -frameborder  => '1',
			     -frameborder  => 'no',
			     -border       => '0'},

			    frame({'-name'       => 't',
				   -src          => $url."&a=t",
				   -marginwidth  => 0,
				   -marginheight => 0,
				   -border       => 1}),
			    "\n",
			    frame({'-name'       => 'z', 
				   -src          => $url."&a=z",
				   -marginwidth  => 0,
				   -marginheight => 0,
				   -border       => 1}),
			    "\n")
		   );

}

#----------------------------------------------------------------------
sub radar {
#----------------------------------------------------------------------
# This subroutine prints out the content of the radar frame.
#
#  usage: $explorer->radar();

    my $self = shift;
 
    # Image attributes: 

    my $width  = $self->_radar_x * $self->_dataset->width;    # width of radar image in pxl
    my $height = $self->_radar_y * $self->_dataset->height(); # height of radar image in pxl

    my $imageSource =

	$self->_imgURL.$self->_name.'/'.$self->_dataset->fileBaseName.".data_matrix.".$self->_imgType;

    # The image map for the radar image

    my $radarImgLink = image_button({-src    => $imageSource,
				     -width  => $width,
				     -height => $height,
				     -align  => 'LEFT',
				     -border => '0', 
				     -hspace => '0', 
				     -vspace => '0', 
				     -vsize  => '100%',
				     -name   => 'radar'}); 

    # This section determines the bracket size in pixels for $kZoomWindowHeight rows

    my $bracketSize = $self->_radar_y * $kZoomWindowHeight; 

    # if the dataset height is less than $kZoomWindowHeight

    $bracketSize = ($bracketSize > $height) ? $height : $bracketSize;

    # and creates the javascript for the bracket

    my ($js, $style) = $self->_js_bracket($bracketSize, $height);

    # Print the html document

    print start_html(-bgcolor => 'white',
		     -script  => {-language => 'JavaScript',
				  -code     => $js},
		     -style   => {-code     => $style},
		     -onLoad  => 'init();');

    print start_form(-action  => $self->{'info'}->{'self'},
		     -target  => 'z'),

    div({-id    => "radar1",
	 -class => "radar"},
	$radarImgLink), # print the radar image	

    div({-id    => "top_bar", # upper half of bracket
	 -class => "bar"}, 
	img({-border => "0",
	     -src    => $self->_commonImageURL.$BRACKET,
	     -width  => ($kRadarMargin * 2),
	     -height => 2})),

    div({-id    => "bottom_bar", # bottom half of bracket
	 -class => "bar"}, 
	img({-border => "0",
	     -src    => $self->_commonImageURL.$BRACKET,
	     -width  => ($kRadarMargin * 2),
	     -height => 2}));

    print hidden({'-name'   => 'a', 
		  -value    => 'z', 
		  -override => 1});

    print $self->_hide_params();

    print end_form();

    print end_html();

}

#----------------------------------------------------------------------
sub toolbar {
#----------------------------------------------------------------------
# This sub creates the toolbar frame. 
#
#   usage: $explorer->toolbar();

    my $self = shift;

    # GeneXplorer logo

    my $geneXplorer = b("&nbsp;gene".font({-color=>'#FF8800'},"X")."plorer ".$VERSION);

    $geneXplorer    = font({-face    => 'verdana,arial,sans-serif',
			    -size    => 2,
			    -bgcolor => 'beige'}, $geneXplorer);

    chomp($geneXplorer);

    # to diplay the info pointed to:

    my $js_info = "function info(txt) { window.frame[1].form[0].text[0].value=(txt) };\n";

    # print the html table containing the various tools

    print start_html(-background=>$self->_commonImageURL.$BGIMAGE, 
		     -script =>$js_info,
		     -bgcolor=>'white');
    print center(
		 table({-cellpadding => '3',
			-cellspacing => '0',
			-vspace      => '0',
			-hspace      => '0',
			-border      => '0'},

		       Tr ({-valign => 'middle',
			    -align  => 'center',
			    -height => '10'},
			   $geneXplorer),
		       
		       Tr({-nowrap => '',
			   -valign => 'middle',
			   -align  => 'center',
			   -height => '10'},
			  $self->_infobox),     # make the infobox
		       
		       Tr({-nowrap => '',
			   -valign => 'middle',
			   -align  => 'center',
			   -height => '10'},
			  $self->_searchTool, # make the search tool
			  $self->_changeTool)  # make the change scale tool
		       
		       )
		 );

    print end_html();

}

#----------------------------------------------------------------------
sub zoom {
#----------------------------------------------------------------------
# This subroutine creates the content of the zoom frame when called from 
# the radar frame. 
#
#   usage: $explorer->zoom();

    my $self = shift;

    # Need to find out which genes to display 

    my $x = ($self->_radar_x) ? $self->_radar_x : $self->_setZoom_x;
    my $y = ($self->_radar_y) ? $self->_radar_y : $self->_setZoom_y;

    my $xClick = int (param('radar.x') / $x);
    my $yClick = int (param('radar.y') / $y); # The click was on ROW: yClick 

    # if possible, choose a few ROWs above the click

    my $yStart = (($yClick - 2) > 0) ? ($yClick - 2) : 0;

    # and if there are enough ROWs, display $kZoomWindowHeight

    my $yEnd   = $yStart + $kZoomWindowHeight;
    my $height = $self->_dataset->height();

    $yEnd   = ($yEnd < $height) ? $yEnd : $height - 1;

    # Make a message for the zoom frame

    my $message = " Zoom ";
    $message = $self->_message($message);

    # create the content of the frame

    $self->_make_zoom_image([$yStart..$yEnd], $message, '');

}

#----------------------------------------------------------------------
sub search_feature {
#----------------------------------------------------------------------
# This method takes a query string and the names of feature field
# to search. This way, one can search for gene symbols, gene names and/or 
# GenBank accession numbers or any other field in the feature description.
#
# usage: $explorer->search("myWords", $field); 
#           
#                   "myWords" - can have multiple words separated by space
#                              (they are combined using 'AND')
#                   $field   - has to be one value of %kDespcriptions

    my $self = shift;

    # check the parameters passed in

    my $query = _untaint(param('q'));
    my $field = _untaint(param('f'));

    # make sure the words are long enough

    my @query = sort {length($a) <=> length($b)} split(/\s+/, $query);

    if (length($query[0]) < 2) {

	print $self->_start_html;
	print $self->_message("&nbsp;Please use at least two letter long words in your search!");
	return;

    }

    # create message for zoom window

    my $message  = "<B style=\"color:black;background-color:#ffff66\">";

    $message .= $query;
    $message .= "</B>"; 

    # find the hits
 
    my $hits    = $self->_get_search_hits(\@query, $field);
    my $numHits = $#$hits + 1;

    if ($numHits > 0) {

	my $add_message;

	if ( $numHits > $kNumberOfMaxHits ) { 

	    @$hits = @$hits[0..($kNumberOfMaxHits - 1)]; 
	    $add_message = " Only the first $kNumberOfMaxHits are shown."; 
	}

	$message = "&nbsp;Search for $message returned ".$numHits." hits.".$add_message."\n";

    }else {

	$message = "&nbsp;The search for $message did not return any hits. Please try again.";

    }

    $message = $self->_message($message);

    if ($numHits <= 0) {
	print $self->_start_html;
	print $message;
	return;
    }

    # Create the content for zoom window to display hits

    $self->_make_zoom_image($hits, $message, '');

}

#----------------------------------------------------------------------
sub neighbors {
#----------------------------------------------------------------------
# This method generates the html and png image for the display
# of the most correlated gene expression vectors versus a seed vector.
# When a gene is clicked on in the zoom window, the most highly correlated
# are retrived and their expression is displayed in the zoom frame.

    my $self = shift;

    # the vector we want to correlate all others against 

    my $seed = param('seed') ? param('seed') : int( param('radar.y') / $self->_radar_y );

    # the correlated genes indeces are returned in @idx, the correlations in @corrs

    my (@idx, @corrs);

    $self->_dataset->correlations($seed, \@idx, \@corrs);

    # since we want the seed as well, we stuff it in the array (on the 'left' side)

    unshift (@idx, $seed);

    # it's correlated perfectly to itself ( = 1)

    unshift (@corrs, 1);

    # create message for the zoom window

    my $message = "<B style=\"color:black;background-color:#ffff66\">";

    $message = "&nbsp;Neighbors for: ".$message.$self->_dataset->getFeature($idx[0],"NAME")."</B>";
    $message = $self->_message($message);

    # call the sub to make the content of the zoom frame

    $self->_make_zoom_image(\@idx, $message, \@corrs);

}

#######################################################################
# Private methods
#######################################################################

#----------------------------------------------------------------------
sub _init {
#----------------------------------------------------------------------

    my $self = shift;

    my $init_href = shift;

    $self->{'dataset'}       = $$init_href{'dataset'} || die "You need to provide a valid dataset object to Explorer!";
    $self->{'config'}        = $$init_href{'config'}  || die "You need to provide a valid config object to Explorer!";
    $self->{'displayConfig'} = $$init_href{'displayConfig'} || die "You need to provide a valid displayConfig file to Explorer!";

    # init the info fields of the explorer object

    $self->_info;

}

#----------------------------------------------------------------------
sub _info {
#----------------------------------------------------------------------
# This procedure stores the variables pertinent to the current explorer
# object, run under the CGI of a certain webserver.
   
    my $self = shift;

    $self->{'info'}->{'self'} = url();
    $self->{'info'}->{'url'} = _get_path(url());
    $self->{'info'}->{'path'} = $0;    # absolute script path 
    $self->{'info'}->{'scriptname'} = _path_remove($0); # script name

    $self->_setZoom_x( param('zx') );
    $self->_setZoom_y( param('zy') );
    $self->_setRadar_x( param('rx') );
    $self->_setRadar_y( param('ry') );
    $self->{'info'}->{'url_params'} = "&zx=".$self->_zoom_x."&zy=".$self->_zoom_y."&rx=".$self->_radar_x."&ry=".$self->_radar_y; 
    $self->_load_displayConfig;
}

#----------------------------------------------------------------------
sub _imgURL {
#----------------------------------------------------------------------
# This method returns the url to the image directory
    my $self = shift;
    return '/'.$self->{'config'}->gxRootWord.'/';
}

#----------------------------------------------------------------------
sub _imgType {
#----------------------------------------------------------------------
# This method returns the image type based on the GD version (see
# Microarray::Config)

    my $self = shift;
    return Microarray::Config->ImageType;
}


#----------------------------------------------------------------------
sub _imgPath {
#----------------------------------------------------------------------
# This method returns the full path to the image directory
    my $self = shift;
    return $self->{'config'}->gxHtmlPath;
}

#----------------------------------------------------------------------
sub _tmpPath {
#----------------------------------------------------------------------
# This method returns the full path to the temp directory
    my $self = shift;
    return $self->{'config'}->tmpPath;
}

#----------------------------------------------------------------------
sub _tmpURL {
#----------------------------------------------------------------------
# This method returns the url for the temp directory

    my $self = shift;
    return $self->{'config'}->tmpUrl;
}

#----------------------------------------------------------------------
sub _commonImageDir {
#----------------------------------------------------------------------
# This method returns the full path for the common images directory

    my $self = shift;
    return $self->{'config'}->gxImagesPath;
}

#----------------------------------------------------------------------
sub _commonImageURL {
#----------------------------------------------------------------------
# This method returns the url for the common images directory

    my $self = shift;
    return $self->{'config'}->gxImagesURL;
}

#----------------------------------------------------------------------
sub _displayConfig {
#----------------------------------------------------------------------
# This subroutine returns the path to the displayConfig file

    my $self = shift;
    $self->{'displayConfig'} = $self->{'config'}->gxDataPath.$self->{'displayConfig'};
    return $self->{'displayConfig'};
}

#----------------------------------------------------------------------
sub _zoom_y {
#----------------------------------------------------------------------
# The height of a row in the zoom frame in pixels

    my $self = shift;
    return $self->{'info'}->{'zy'};
}

#----------------------------------------------------------------------
sub _zoom_x {
#----------------------------------------------------------------------
# The width of a column in the zoom frame in pixels

    my $self = shift;
    return $self->{'info'}->{'zx'};
}

#----------------------------------------------------------------------
sub _radar_y {
#----------------------------------------------------------------------
# The height of a row in the radar frame in pixels

    my $self = shift;
    return $self->{'info'}->{'ry'};
}

#----------------------------------------------------------------------
sub _radar_x {
#----------------------------------------------------------------------
# The height of a row in the radar frame in pixels

    my $self = shift;
    return $self->{'info'}->{'rx'};
}

#----------------------------------------------------------------------
sub _setZoom_y {
#----------------------------------------------------------------------
# In the zoom frame the height of one image row is set to between 
# $kMaxZoomHeight and $kMinZoomHeight pixels.

    my $self = shift;
    my $zy;

    # if zoom height is provided - use what is given
    if ( @_ ) { 
	$zy = shift; # row height in pixels
	$zy = ($zy > $kMaxZoomRowHeight) ? $kMaxZoomRowHeight : $zy;
	$zy = ($zy < $kMinZoomRowHeight) ? $kMinZoomRowHeight : $zy;
    }    

    # if zoom height is unspecified it is set to the default minimum
    else{ 
	$zy = $kMinZoomRowHeight; 
    } 
    $zy = int ($zy);
    $self->{'info'}->{'zy'} = $zy;
}

#----------------------------------------------------------------------
sub _setZoom_x {
#----------------------------------------------------------------------
# In the zoom frame the width of one image column is set to between 10 
# pixels and $kMaxZoomWidth/(number of columns) pixels.

    my $self = shift;

    my $zx; # column width in pixels
    my $ds_width    = $self->_dataset->width(); 
    my $max_col_width = $kMaxZoomWidth / $ds_width; # a column can be only
                                                    # this wide
    if (@_) { # if there is a request ...
	$zx  = shift; 
	# if requested column width is bigger than the limit
	$zx = ($zx > $max_col_width) ? $max_col_width : $zx;
    }

    # if zoom image column width is unspecified it is set to the default
    else{
	$zx = ($max_col_width > $kPrefZoomColWidth) ? $kPrefZoomColWidth : $max_col_width; 
    } 
    $zx = int ($zx);
    $self->{'info'}->{'zx'} = $zx;
}

#----------------------------------------------------------------------
sub _setRadar_x {
#----------------------------------------------------------------------
# In the radar frame the width of one image column is set to between 2 pixels
# and $kMaxRadarWidth/(number of columns in dataset) pixels.


    my $self = shift;
    my $rx; # column width on radar in pixels
    my $ds_width = $self->_dataset->width(); # number of columns
    my $max_col_width = $kMaxRadarWidth / $ds_width; # max width of a column

    if (@_) { # if there is a request ...
	$rx = shift;
	# if requested column width is bigger than the limit
	$rx = ($rx > $max_col_width) ? $max_col_width : $rx;
    }
    # if undefined it is set to a default of 100/(# of expts), but at least 1
    else{
	$rx = ($max_col_width > $kPrefRadarColWidth) ? $kPrefRadarColWidth : $max_col_width; 
    } 
    $rx = sprintf("%2.2f", $rx);
    $self->{'info'}->{'rx'} = $rx;
}

#----------------------------------------------------------------------
sub _setRadar_y {
#----------------------------------------------------------------------
# In the radar frame the height of one image row is set

    my $self = shift;
    my $ry;
    my $ds_height  = $self->_dataset->height();
    my $max_row_height = $kMaxRadarHeight / $ds_height;

    if ( @_ ) { # if there is a request ...
	$ry = shift;
	# if requested row height is bigger than the limit
	$ry = ($ry > $max_row_height) ? $max_row_height : $ry;
    }    

    # if not specified set to the preferred or to the limit
    else{
	$ry = ($max_row_height > $kPrefRadarRowHeight) ? $kPrefRadarRowHeight : $max_row_height; 
    } 
    $ry = sprintf("%2.2f", $ry);
    $self->{'info'}->{'ry'} = $ry;
}

#----------------------------------------------------------------------
sub _start_html{
#----------------------------------------------------------------------

    my $self = shift;
    print <<EOM;
<HTML>
<HEAD>
<STYLE TYPE="text/css">
.img1 { vertical-align: bottom; }
.font1 { font-size: 75%; }
</STYLE>
<BODY BGCOLOR='white'>
EOM
    return;
}

#----------------------------------------------------------------------
sub _make_zoom_image {
#----------------------------------------------------------------------
# This subroutine crates the content of the zoom frame. It expects an 
# - array reference that contains the indeces of data matrix rows to display; 
# - string that contains an html-formatted message for the frame to display;
# - array reference  

    my $self = shift;

    my ($rows_ra, $message, $corr_ra) = @_;

    my $js = script({-language => "JavaScript"}, 
		    "function info(txt) { parent.t.document.infobox.text.value=(txt) };")."\n";

    # This section creates a table with each row showing data for a gene 
    # get image rows requested 

    my $row_images = $self->_make_row_image ($rows_ra);

    # mark up the image rows and and create html table using feature info

    my $html_table = $self->_make_html_table($rows_ra, $row_images, $corr_ra);

    $self->_makeExptImageMap();
    
    $self->_start_html;

    print $js;

    print $message;

    print $self->{'exptMap'};

    print table({-border      => 0,
		 -cellspacing => 2,
		 -cellpadding => 0,
		 -align       => 'LEFT'},
		Tr(
		   $self->{'exptImage'}, "\n",
		   td({-colspan => 1,
		       -align   => 'left'}, 
		      $self->_contrast_legend
		      ), "\n"
		   ), "\n",
		Tr(
		   td({-colspan => 2,
		       -valign  => 'top'}, $html_table
		      ), "\n"
		   ), "\n"
		)."\n";

    print end_html();

}

#--------------------------------------------------------------------
sub _make_row_image {
#--------------------------------------------------------------------
# This method takes as input an array reference that should contain an 
# ordered index of rows requested from the matrix image. 
# The image (matrix image) is broken up into individual row images and 
# and the ones pointed to by the array indeces are passed on for saving 
# and upon saving returned to the calling function

    my $self = shift;
    my $index_aref = shift;

    my $source_image = $self->_dataset->image("matrix");
    my $width = $self->_dataset->width();
    my ($height, @row_images);

    # the height for the ROW images = 1
    $height = 1;
    # break up the source image into image rows
    for (my $i = 0; $i <= $#$index_aref; $i++ ) {
	my $image_row = new GD::Image($width, $height);
	$image_row->copy($source_image, 0, 0, 0, $$index_aref[$i], $width, $height);
	push (@row_images, $image_row);
    }
    $self->_save_img_files($index_aref, \@row_images);
}

#----------------------------------------------------------------------
sub _save_img_files{
#----------------------------------------------------------------------
# This subroutine saves the image files that are passed in in the form of 
# an array reference. In addition it expects another array reference that
# is an index file specifying which rows of the matrix image the array images 
# came from.

    my $self = shift;
    my ($ids_ra, $images_ra) = @_;
    my (@image_files);

    my $imgSuffix = $self->_imgType;

    for (my $i = 0; $i <= $#$ids_ra; $i++) {
	my $img_file = $self->_name.$$ids_ra[$i].'.'.$imgSuffix; # name of row image
	$img_file =~ s/\//_/g;                  # substitute underscores for slashes in dataset name
	my $path = $self->_tmpPath.$img_file;   # path to row image in temp directory
	my $image = $$images_ra[$i]->$imgSuffix(); # the row image object
	if ((!(-e $path)) || (-z $path)) {      # if image file does not exist
	    open( OUT,">$path" ) || warn "Cannot print temp image: $!\n";
	    binmode OUT;
	    print OUT $image;
	    close(OUT);
	}
	push (@image_files, $img_file);
    }
    return \@image_files;
}

#----------------------------------------------------------------------
sub _makeExptImageMap {
#----------------------------------------------------------------------
##This will create the content of the infobox: when the mouse is over some
## experiment in the zoom frame this will display the name of the 
## appropriate experiment.

    my $self = shift;
    return if ((defined $self->{'exptImage'}) && (defined $self->{'exptMap'}));
    my ($x1, $y1, $x2, @map, $area, $map, $onMouseOver, $imgWidth, $exptImage, $expImgHeight, $height);
    # The next section creates the experiment image map
    # first, determine the size of the image
    ($imgWidth, $expImgHeight) = $self->_dataset->image("expt_info")->getBounds();
    $imgWidth = $self->_dataset->width() * $self->_zoom_x;
    $height = ($expImgHeight > $kExpImgHeight) ? $expImgHeight : $kExpImgHeight;
    
    # then make the html for the image
    $exptImage = img({-src    => $self->_imgURL.$self->_name.'/'.$self->_dataset->fileBaseName.".expt_info.".$self->_imgType,
		      -width  => $imgWidth,
		      -ismap  => '',
		      -usemap => '#EXPT',
		      -border => '0'});

    $exptImage = td({-colspan => '1',
		     -valign  => 'bottom',
		     -align   => 'left',
		     -height  => $height}, $exptImage
		    )."\n";

    $self->{'exptImage'} = $exptImage;

    # and create the image map  
    my $script_name = $self->{'info'}->{'scriptname'};
    $y1 = 0;

    for (my $i=0; $i < $self->_dataset->width; $i++){
	$x1 = int ($i * $self->_zoom_x);
	$x2 = int ( ($i * $self->_zoom_x) + $self->_zoom_x);

	my $text = $self->_dataset->experiment($i, "NAME");
	$text =~ s/\"//g;
	$onMouseOver = "onMouseOver=\"javascript:info('EXPT: ".$text."')\"";
	$area  = "<AREA SHAPE=\"RECT\" COORDS=\"$x1, $y1, $x2, $expImgHeight\" HREF=\"#\" ";
	$area .= $onMouseOver.">\n";
	push @map, $area;
    }
    $map = "<MAP NAME=\"EXPT\">@map</MAP>";
    $self->{'exptMap'} = $map;
}

#----------------------------------------------------------------------
sub _row_image_markup {
#----------------------------------------------------------------------
## This subroutine will mark up the row image in the zoom window:
## - for the infobox: when the mouse is over some gene in the zoom frame 
##   the name of the appropriate gene is shown.
## - for the correlations display when a gene is clicked on


    my $self      = shift;
    my $i         = shift;  # which row in the matrix image
    my $image_ref = shift;  # the row image
    my $width     = shift;  # the width of the image display
    my ($onMouseOver, $area);

    # display the row image
    $image_ref = img({-src    => $self->_tmpURL.$image_ref,
		      -height => $self->_zoom_y,
		      -width  => $width,
		      -border => '0'});

    # the javascript to display the content of the infoBox for the row
    $onMouseOver = $self->_dataset->getFeature($i, "NAME");
    $onMouseOver =~ s/\"//g;
    $onMouseOver = "onMouseOver=\"javascript:info('GENE: ".$onMouseOver."')\"";
    
    # construct the url for corr in case the row is clicked on
    $area  = "\n<a HREF=\"".$self->{'info'}->{'scriptname'};
    $area .= "?n=".$self->_name."&a=c&seed=$i".$self->{'info'}->{'url_params'}.'" ';
    $area .= $onMouseOver.">\n".$image_ref."</a>";
}

#--------------------------------------------------------------------
sub _make_html_table {
#--------------------------------------------------------------------
# This method takes a list of vector indices and returns a completely
# marked up HTML version. The markup is done according to a displayConfig
# file that is associated with this explorer object / dataset.

    my $self      = shift;
    my $index_ref = shift; # the indeces of the rows in data matrix that are requested
    my $image_ra  = shift; # the corresponding row images  
    my $corr_ra   = shift; # the corresponding correlation values (may be empty)
    my ($row, @rows, $row_table, $row_image);
    my $imgWidth = $self->_dataset->width() * $self->_zoom_x;

    # for every row, do the markup
    for (my $i=0; $i <= $#$index_ref; $i++) {	
	# if there is correlation value for this row 
	if ($corr_ra) {
	    $row = $self->_feature_markup( $$index_ref[$i], $$corr_ra[$i] );
	}
	# if there is no corralation to display
	else{
	    $row = $self->_feature_markup( $$index_ref[$i] );
	}	    
	# markup the image row
	$row_image = $self->_row_image_markup($$index_ref[$i], $$image_ra[$i], $imgWidth);
	# make a row in an html table
	push @rows, Tr(
		       td(
			  $row_image
			  ), "\n",
		       td({-height=>$self->_zoom_y}, 
			  $row
			  ), "\n",
		       )."\n";
    }
    # make the table from the marked up row
    $row_table = table({-border      => '0',
			-cellborder  => '0',
			-cellpadding => '0',
			-cellspacing => '0'},
		       @rows)."\n";
}

#--------------------------------------------------------------------
sub _searchTool {
#--------------------------------------------------------------------
# This sub creates the searchtool for the toolbar and returns it as 
# html, as a table cell.

    my $self = shift;
    my (@keys_used, %desc_used, $searchform, $cell1);

    @keys_used = $self->_dataset->getFeatureKeys(); # get the keys used here and sort by (future) value
    unshift @keys_used, "ALL";                      # add ALL to search all
                                                    # and sort by (future) value
    @keys_used = sort {$self->{'style'}->{$a}->{'display'} cmp $self->{'style'}->{$b}->{'display'}} @keys_used;

    foreach (@keys_used) {                          # descriptions for used keys
	$desc_used{$_} = $self->{'style'}->{$_}->{'display'};
    }

    # make the html form 
    $searchform  = start_form(-action => $self->{'info'}->{'self'},
			      -target => 'z');
    $searchform .= "<td>";    
    $searchform .= b("Search for ");    
    $searchform .= textfield(-size      => '8',
			     -maxlength => '20',
			     -name      => 'q');    
    $searchform .= b(" in ");
    $searchform .= popup_menu(-values  => \@keys_used,
			      -labels  => \%desc_used,
			      -name    => 'f',
			      -default => 'ALL');
    $searchform .= submit(-label => 'go');

    $searchform .= hidden(-name     => 'a', 
			  -value    => 's', 
			  -override => 1);    
    $searchform .= $self->_hide_params();
    $searchform .= "</td>";
    $searchform .= end_form();
    $searchform  = font({-face => 'verdana,arial,sans-serif',
			 -size => 2}, $searchform
			);
    chomp($searchform);
    return $searchform;
}

#----------------------------------------------------------------------
sub _changeTool {
#----------------------------------------------------------------------
# This subroutine will create the change radar scale tool for the toolbar 
# and returns it as html, as a table cell.

    my $self = shift;
    my (%change_scale, @scale_values, $changeform, %display);
    # labels for changing radar frame scale
    %change_scale = ( "0.5" => " 50%",
		      "1"   => "100%",
		      "2"   => "200%",
		      "4"   => "400%");

    foreach (sort keys %change_scale){
	# display the percentages
	$display{sprintf("%2.2f", $_ * $self->_radar_x)} = $change_scale{$_};
	# submit the new rx values
	push (@scale_values, sprintf("%2.2f", $_ * $self->_radar_x));
    }

    # make the html form for this tool - it is formatted as a table cell
    $changeform  = start_form(-action => $self->{'info'}->{'self'},
			      -target => '_top');    
    $changeform .= "<td>";
    $changeform .= "Radar ";
    $changeform .= popup_menu(-values  => \@scale_values,
			      -labels  => \%display,
			      -name    => 'rx',
			      -default => '1');
    $changeform .= " wide ";
    $changeform .= submit(-label => 'change');
    $changeform .= $self->_hide_params();
    $changeform .= "</td>";
    $changeform .= end_form();
    $changeform  = font({-face => 'verdana,arial,sans-serif',
			 -size => 2}, $changeform
			);
    chomp($changeform);
    return $changeform;
}

#----------------------------------------------------------------------
sub _infobox {
#----------------------------------------------------------------------
# This sub creates the infobox tool for the toolbar and returns it as 
# html, as a table cell.

    my $self = shift;
    my $infobox;
    
    # the html form for this tool 
    $infobox  = start_form({-name => 'infobox'},
			   ""
			   );
    $infobox .= "<td colspan=\"2\">"; # It is a 2 column wide cell
    $infobox .= textfield({-size  => '100',
			   -name  => 'text',
			   -value => 'Put your mouse over elements to see more information here'}
			  );
    $infobox .= "</td>";
    $infobox .= end_form;
    chomp($infobox);
    return $infobox;
}

#--------------------------------------------------------------------
sub _feature_markup {
#--------------------------------------------------------------------
# This subroutine will markup as html the annotations for a row in the 
# zoom table

    my $self        = shift;
    my $feature_num = shift;              # the index of the row to markup in the feature table
    my $corr        = @_ ? shift : undef; # if there is a corr value provided
    my ($data, $spacer, $fieldsUsed, $row, $field);

    # flag for flipping the row background color
    $flip = $flip ? 0 : 1;
    # the fields that are actually used for this dataset
    $fieldsUsed = $self->_style_keys;
    # first format the spacer that will separate the individual fields
    $spacer = $self->_markup_cell("&nbsp;", 'NUM', $flip);    
    # if there is a correlation value, mark it up
    $row .= $self->_markup_cell($corr, 'CORR', $flip) if ($corr);
    $row .= $spacer;
    # mark up each field
    foreach $field (@$fieldsUsed) {
	# the piece of the that needs markup
	$data = $self->_dataset->getFeature($feature_num, $field);
	if (length($data) > $kMaxAnnotFieldLength){ # if the data is too long to display
	    $data  = substr($data, 0, $kMaxAnnotFieldLength); 
	    $data .= "... "; 
	}
	$row .= $self->_markup_cell($data, $field, $flip);
	$row .= $spacer;
    }
    return $row;
}

#---------------------------------------------------------------------------------------    
sub _markup_cell {
#---------------------------------------------------------------------------------------
# This function returns a TABLE DATA marked up piece of HTML.
# usage: markup_cell ( the piece of data to markup, the type of data, flag to format bkground in table )
      
    my $self    = shift;
    my $data    = shift;
    my $colname = shift;
    my $flip    = shift;
    my ($color, $bgcolor, $url, $content, $href, $cell, $height, $width, $name, $image, 
	%anchor_attr, $target, $font_face, $font_size, $font_color, $bold);

    $color   = exists($self->{'style'}->{$colname}->{color})   ? $self->{'style'}->{$colname}->{color}   : "white";
    $bgcolor = exists($self->{'style'}->{$colname}->{bgcolor}) ? $self->{'style'}->{$colname}->{bgcolor} : ($flip ? "white" : "#EEEEEE");
    $url     = $self->{'style'}->{$colname}->{'url'};
    # if data empty or no data was found, return minimal cell content immediately
    if (!defined($data) || $data =~ /$colname/i) {
	$cell = td({-height  => $self->_zoom_y,
		    -nowrap  => '',
		    -bgcolor => $bgcolor},
		   ,"");	
	return $cell;
    }
#    print $data, br, $colname, br;
    $target     = exists($self->{'style'}->{$colname}->{target})     ? $self->{'style'}->{$colname}->{target}     : undef;    
    $font_face  = exists($self->{'style'}->{$colname}->{font_face})  ? $self->{'style'}->{$colname}->{font_face}  : undef;
    $font_size  = exists($self->{'style'}->{$colname}->{font_size})  ? $self->{'style'}->{$colname}->{font_size}  : 1;
    $font_color = exists($self->{'style'}->{$colname}->{font_color}) ? $self->{'style'}->{$colname}->{font_color} : "black";
    $bold       = exists($self->{'style'}->{$colname}->{bold});

    $content = $data;
    
    # if an image was defined for this field, we make an HTML element (the images
    # have to be in the common image dir
    if ($self->{'style'}->{$colname}->{image}){	
	if ($colname eq "CORR") { # format the bar for correlations
	    $height = $self->_zoom_y - 2;
	    $width  = ($data - 0.4) * 40; # only corrs above 0.5 are given, but make sure something is shown
	    $image = img({-border      => 0, 
			  -height      => $height,
			  -width       => $width,
			  -alt         => "correlation = ".$data,
			  -name        => $data,
			  -onmouseover => "javascript:info('CORR: ".$data."')",
			  -src         => $self->_commonImageURL.$self->{'style'}->{$colname}->{image}}
			 );	    
	} 
	else {
	    $image = img({-border => 0, 
			  -src    => $self->_commonImageURL.$self->{'style'}->{$colname}->{image}}
			 );
	}
    }

    # build a URL when present in the displayConfig file
    if ($self->{'style'}->{$colname}->{url_append}  || $self->{'style'}->{$colname}->{url_replace}) {
	if ($self->{'style'}->{$colname}->{url_append}){
	    $href = "http://".$url.$data;	    
	} 
	elsif ($self->{'style'}->{$colname}->{url_replace}){
	    $url  =~ s/XXX/$data/;
	    $href = "http://".$url;
	}
	$anchor_attr{'-href'} = $href;
	if ($target){
	    $anchor_attr{'-target'} = $target;
	}
	# if an image has been defined, replace the text with it
	if ($image){ 
	    $content = a(\%anchor_attr, "\n".$image);
	} 
	else {
	    $content = a(\%anchor_attr, $data);
	}
    }

    # if an image, but no link was requested, make only the image table cell content
    # this case more exceptional, we use it for the correlation display bars
    if ($image && !$href) { 
	$content = $image;
    }
    
    # if bold was requested, add <b> tags
    if ($bold && !$image) {
	$content = b($content);
    }
    if ($font_face || $font_size) {
	$content = font(
			{-face => $font_face, 
			 -size => $font_size}, 
			$content
			);
    }
    $cell = td(
	       {-height  => $self->_zoom_y,
		-bgcolor => $bgcolor,
		-nowrap  => ''},
	       "\n", $content
	       )."\n";
}

#--------------------------------------------------------------------
sub _style_keys {
#--------------------------------------------------------------------
# This subroutine will return the a list of the column names that are 
# actually used in the feature table for annotation of the dataset. They
# are returned as elements of an array in the order they are to be 
# displayed (that is determined by the order they are listed in the 
# displayConfig file).

    my $self = shift;
    my (@keyStyles, @feature_keys, @ordered_style_keys);

    # load displayConfig file if needed
    $self->_load_displayConfig() unless (defined($self->{'style'}));
    # all potential columns
    @keyStyles = keys %{ $self->{'style'} };
    # the ones used for annotation 
    @feature_keys = $self->_dataset->getFeatureKeys();
    # put the ones used in an ordered array
    foreach (@feature_keys) {
	$ordered_style_keys[$self->{'style'}->{$_}->{'order'}] = $_;
    }
    return (\@ordered_style_keys);
}

#--------------------------------------------------------------------
sub _load_displayConfig {
#--------------------------------------------------------------------
# This subroutine parses a markup displayConfig file that can be user defined.
# The displayConfig file contains information on the rendering and linking of
# the fields within an HTML table. This information is used in the 
# _table_html_markup function.
# The displayConfig file is expected as a test file containing records in the
# following format:
#
# # comment line
# colname = name of the column from feature info file
# display = how the colname should be displayed in the seach box
# bgcolor = background color of table cell 
# color   = text color
# url     = a URL to use for building a link with the column content
# image   = an image that replaces the cell content
# url_append  = One value that gets appended to the URL (or self, see below)
# url_replace = what value/text should be put into the placeholder 
#               positions in the URL string. The values have to be '|' delimited.
#               The placeholders have to be three uppercase letters, 
#               starting with Z and descending (ZZZ, YYY, XXX, WWW etc.)
#               There can be multiple replacement values for each URL.
#               They will be put in in the given order.
#               A special replacement value is 'self', which is the column value.
# url_target  = target window for the URL to be build.
# font        = desired font for display
# //    
#
    my $self = shift;
    my (%tmphash, @sections, $counter, $displayConfig);

    $displayConfig = $self->_displayConfig;
    if (!$displayConfig) {
    # if no displayConfig file is defined use the keys that are in the feature table
	my @feature_keys = $self->_dataset->getFeatureKeys;
	foreach (@feature_keys ) {
	    $self->{'style'}->{ $_ }->{bgcolor} = "white"; 
	    # and display them accordingly
	    $self->{'style'}->{ $_ }->{'display'} = $_;
	}
	return;
    }
    # read in the displayConfig file
    open (IN, $displayConfig) || die("Could not open displayConfig $displayConfig: ", $!, "!");
    $/ = '//';    # temporarily set the line end delimiter to '//'. 
                  # This is the divider between sections in our file
    @sections = (<IN>);
    close(IN);
    $/ = "\n";    # set the line end delimiter back to newline
    $counter = 0; # counter, because we need to store the order in which
                  # the markup is encountered in the displayConfig file

    # get rid of characters, lines not needed, for each key
    foreach (@sections) {
	my @rows = split(/\n/, $_);
	foreach (@rows){
	    chomp;    # no newline
	    s/#.*//;  # no comment
	    s/\/\///; # no record delimiter
	    s/^\s+//; # no leading white
	    s/\s+$//; # no trailing white
#	    s/ //g;
	    next unless length; # anything left?
	    my ($var, $value) = split(/\s*=\s*/, $_, 2);
#	    print '_var_', $var, '_value_', $value, br;
	    $tmphash{$var} = $value; 
	}
	my $colname = $tmphash{'colname'};
	delete $tmphash{'colname'};  # remove this key/value pair from hash
	foreach (keys %tmphash) {
	    $self->{'style'}->{ $colname }->{$_} = $tmphash{$_}; 
	}
	# if display was not specified, use column name
	if (!exists $self->{'style'}->{ $colname }->{'display'}){ 
	    $self->{'style'}->{ $colname }->{'display'} = $colname;
	}
	# store the number at which this columname occured in the file
	# this will later determine the output order
	$self->{'style'}->{ $colname }->{'order'} = $counter++;
	undef %tmphash;
    }
}

#--------------------------------------------------------------------
sub _hide_params {
#--------------------------------------------------------------------
# This sub will hide the parameters form the url
    my $self = shift;
    my $hidden_fields;

    $hidden_fields  = hidden({'-name' => 'rx', -value => $self->_radar_x });
    $hidden_fields .= hidden({'-name' => 'ry', -value => $self->_radar_y });
    $hidden_fields .= hidden({'-name' => 'zx', -value => $self->_zoom_x  });
    $hidden_fields .= hidden({'-name' => 'zy', -value => $self->_zoom_y  });
    $hidden_fields .= hidden({'-name' => 'n',  -value => $self->_name });

    return $hidden_fields;
}

#----------------------------------------------------------------------
sub _get_search_hits {
#----------------------------------------------------------------------
# This subroutine retrives the hits based on the search query entered in
# the searchbox.
#    \@hits = _get_search_hits (\@query, $field)
#
#        where - @query contains the words used for searching, they will
#                        be combined by logical 'AND'
#              - $field selected field for search

    my $self = shift;
    my ($query, $field) = @_;

    my (@hit_bitvec, $resultvec, @hits, @query);

    # if the user submitted a multi word query we search each element separately
    # here we extract the space separated words from the query parameter field 
    @query = @$query;	

    for (my $i=0; $i <= $#query; $i++){ # for each query word

	# initialize a bitvector (one bit for each gene in dataset) by setting the last bit
	vec( $hit_bitvec[$i], $self->_dataset->height + 1, 1) = 1;
	# dataset->search() returns an index of features that matched the search term
	@hits = $self->_dataset->search($query[$i], $field);

	for(my $j=0; $j <= $#hits; $j++){
	    # set the nth bit in the vector to store the hit information
	    vec($hit_bitvec[$i], $hits[$j], 1) = 1;
	}
	undef (@hits);
    }

    # initialize the result bitvector with the bitvector for the first search term
    $resultvec = $hit_bitvec[0];
    # logically AND all consecutive bitvectors
    for (my $k=1; $k <= $#hit_bitvec; $k++) {
	$resultvec = $resultvec & $hit_bitvec[$k];
    }

    # read the resultvector back out into an array
    for (my $l=0; $l <= $self->_dataset->height; $l++) {
	if (vec($resultvec,$l,1)) {
	    push @hits, $l;
	}	    
    }
    return \@hits;
}

#--------------------------------------------------------------------
sub _contrast_legend {
#--------------------------------------------------------------------
# This sub will display the appropriate scalebar. Once is created, it 
# is reused.
# The scale is made as a table with 2 rows; one row contains the values,
# the other the corresponding images (pixels).

    my $self = shift; 

    return if (defined $self->{'scale'});

    my ($scaleImage, $table, $width, $height, @pixelnames, @pixels, 
	$pixels, $step, $colScheme, @rows, @bla, $contrast);

    # define a few constants and load the scale image
    $contrast = $self->_dataset->contrast;
    $colScheme = $self->_dataset->colorScheme;
    $scaleImage = $self->_load_image($self->_commonImageDir.'scale_'.$colScheme.'.'.$self->_imgType);
    ($width, $height) = $scaleImage->getBounds();

    # break up the image into pixels
    for (my $i = 0; $i < $width; $i++){
	$pixels[$i] = GD::Image->new(1, 1);
	$pixels[$i]->copy($scaleImage, 0, 0, $i, 0, 1, 1);
	push (@pixelnames, 'pixel'.$colScheme.$i);
    }
    # save the pixels and get their path in $pixels
    $pixels = $self->_save_img_files(\@pixelnames, \@pixels);

    # find out the fold change numbers 
    $step = $contrast / 4;
    $rows[0] = "&nbsp;1:1 "; # this is the center - no change    
    for (my $i = $step; $i <= $contrast; $i += $step) {
	push    @rows, "&nbsp;&gt; ".sprintf("%2.1f", 2**$i)." "; # * step increase
	unshift @rows, "&nbsp;&lt; 1/".sprintf("%2d", 2**$i)." "; # 1/step decrease
    }

    # format the output as a table
    for (my $i = 0; $i <= $#rows; $i++) {
	push (@bla, td({-cellpadding => '5',
			-height      => '14',
			-width       => '50',
			-bgcolor     => 'white',
			-border      => 3,
			-align       => 'center'},
		       font({-face   => 'verdana,arial,sans-serif',
			     -size   => '1'}
			    ),
		       $rows[$i]
		       )."\n"
	      );
	$$pixels[$i] = td({-background => $self->_tmpURL.$$pixels[$i],
			   -height     => '15'}
			  )."\n";
    }
    $table = table({-border      => '0',
		    -cellspacing => '0',
		    -cellpadding => '0'},
		   Tr(
		      b(@bla)
		      ), "\n",
		   Tr(
		      @$pixels
		      ), "\n"
		   )."\n";
    $self->{'scale'} = $table;
}

#--------------------------------------------------------------------
sub _load_image {
#--------------------------------------------------------------------
# this sub will load an image, file name should contain the full path

    my ($self, $filename) = @_;
    open(IN, $filename) || die "cannot open image within explorer: $filename! $!\n";
    my $image = ($self->_imgType eq 'gif') ? GD::Image->newFromGif(*IN) : GD::Image->new(*IN);
    return $image;
}

#--------------------------------------------------------------------
sub _dataset {
#--------------------------------------------------------------------
    
    my $self = shift;
    return $self->{dataset};
}

#----------------------------------------------------------------------
sub _name {
#----------------------------------------------------------------------
# Returns the name of the dataset.

    my $self = shift;
    return $self->_dataset->name();
}

#--------------------------------------------------------------------
sub _get_path {
#--------------------------------------------------------------------
# Returns the URL of the script. (Removes everything after the last '/') 
    my $url = shift;
    $url =~ /(.*\/).+$/;
    return $1;
}

#--------------------------------------------------------------------
sub _path_remove {
#--------------------------------------------------------------------
# Removes the path info (everything up to the last '/')
    my $file = shift;
    my $position = rindex $file, "/";
    my $name = substr $file, $position + 1;	
    return $name;
}

#--------------------------------------------------------------------	
sub _untaint {
#--------------------------------------------------------------------
# Removes shell characters from a string.
    my $value = shift;
    $value =~ s/[!@\$%\^&\*\(\)?#|~]//g;    
    return $value;
}

#----------------------------------------------------------------------
sub _message {
#----------------------------------------------------------------------
# a small sub to return marked up message for display
     
    my $self = shift;
    my $message = shift;

    $message = table({-cellpadding => 3},
		     Tr(
			td({-colspan => '2',
			    -height  => '20',
			    -bgcolor => 'beige'},
			   font({-face => 'arial,sans-serif',
				 -size => 3}, b($message)
				), "\n"
			   ), "\n"
			), "\n"
		     )."\n";

    return $message;
}

#--------------------------------------------------------------------
sub _js_bracket {
#--------------------------------------------------------------------
# This sub creates the javascript to display the bracket in the radar 
# frame at the position where the image was clicked on. The bracket is
# displayed on the right edge of the window.

    my $self     = shift;
    my $window_y = shift;  # the distance between the bars (bracket in pixels
    my $height   = shift;  # heigth of the image in pixels
    my $offset   = 3 * $self->_radar_y;
    my $js = <<"EOM";
<!--

var _dom = 0;

function getObj(name)
{
  if (document.getElementById)
  {
        this.obj = document.getElementById(name);
        this.style = document.getElementById(name).style;
  }
  else if (document.all)
  {
        this.obj = document.all[name];
        this.style = document.all[name].style;
  }
  else if (document.layers)
  {
        this.obj = document.layers[name];
        this.style = document.layers[name];
  }
}

function mousehandler(e){
  if(document.all) e=window.event; // for IE
  var window_y = $window_y;
  var dataset_height = $height;

  if(_dom == 2){
    var y1 = new getObj('top_bar');
    var y2 = new getObj('bottom_bar');
    var radar2 = new getObj('radar1');
    var y3 = e.pageY; 
    var radar_y = radar2.style.top;

    if ((y3 < radar_y) || (y3 > (dataset_height + radar_y))) {return false;}

    y3 = y3 - radar_y;
    y3 = y3 - $offset;
    if (y3 < 0) {y3 = 0;}
    y1.style.top= y3 + radar_y - 1;
	 
    var y3 = e.pageY;
    y3 = y3 - radar_y - $offset;
    y3 = y3 + window_y;
    if (y3 >= dataset_height) {y3 = dataset_height - 1;}
    y2.style.top= y3 + radar_y + 1;

    return false;
  } 
  else {
    var y1 = new getObj('top_bar');
    var y2 = new getObj('bottom_bar');
    var radar1 = new getObj('radar1');
    var y3 = e.clientY;
    var radar_y = radar1.style.top;

    if ((y3 < radar_y) || (y3 > (dataset_height + radar_y))) {return false;}

    y3 = y3 - radar_y;

    y3 = y3 - 5;
    if (y3 < 0) {y3 = 0;}

    if (_dom==3) { y3 += 12; }
    y1.style.top = (y3 + radar1.style.top - 12) + "px";

    var y3 = e.clientY;
    y3 = y3 - radar_y;

    y3 = y3 + window_y;
    if (y3 >= dataset_height) {y3 = dataset_height - 1;}

    if (_dom==3) { y3 += 12; }
    y2.style.top = (y3 + radar1.style.top - 12) + "px";
  }

  e.cancelBubble = true;  // for IE5
  e.returnValue  = true; // for IE5
  return true;
}

function init(){
  _dom=document.all?3:(document.getElementById?1:(document.layers?2:0));
  document.onmousedown = mousehandler;
  if(_dom==2){                         // for NN4
    document.captureEvents(Event.MOUSEDOWN);
    var div = document.layers.radar1;
    div.document.onmousedown = mousehandler;
    var radar1 = new getObj('radar1');
    var y1 = new getObj('top_bar');
    var y2 = new getObj('bottom_bar');
    var radar_y = document.layers.radar1.top;
    y1.style.top= radar1.style.top - 1;
    y2.style.top= $window_y + radar1.style.top;
  } else {
    var y1 = new getObj('top_bar');
    var y2 = new getObj('bottom_bar');
    var radar1 = new getObj('radar1');
    var radar_y = radar1.style.top;
    y1.style.top = (0 + radar_y - 12) + "px";
    if (_dom==3) { radar_y += 13; }
    y2.style.top = ($window_y + radar_y - 13) + "px";
  }

}
// -->

EOM

    my $style = << "EOS"; # postition the various elements in the frame
<!--

.radar { position: absolute; top: 0px; left : 0px; VISIBILITY: visible; }
.bar   { position: absolute; top: 1px; right: 0px; VISIBILITY: visible; }
.bar2  { position: absolute; top: 1px; right: 0px; VISIBILITY: visible; }

// -->

EOS
    return $js, $style;
}

1; # return a true value to make perl happy

__END__

#####################################################################
#
#  POD Documentation from here on down
#
#####################################################################

=pod

=head1 Name

Microarray::Explorer - class for viewing clustered expression data over the web

=head1 Abstract

The Explorer class belongs to the package Microarray. It functions as
a web viewer for dataset objects from the same package. Following the
Model/View/Controller concept, the explorer class is the
View/Controller, whereas the dataset class is the Model.

=head2 Intended Behaviour

Explorer will display the dataset object in a web browser in a
frameset of 3 frames.

    The frames are:   - radar frame   - left side of the window
                      - toolbar frame - top of right side of window  
                      - zoom frame    - lower part of right side of window

=head3 Radar frame

The radar frame displays the whole dataset as an image map. The genes
(clones, ...) are shown are the rows of the image, while the
experiments are shown as the columns. Clicking the image will have 2
effects:

                - the expression patterns for the next XXX genes starting at
                  position of the click are displayed in the zoom frame

                - the top of a small bracket on the right side of the radar
                  frame is positioned at the height of the click and the bracket
                  shows the XXX genes selected and magnified on the zoom frame.

The size of the image is maximized both horizontally and vertically.

=head3 Toolbar frame

The toolbar allows actions on either the radar frame or the zoom
frame.

For the radar frame it allows a simple customization: changing the
width of the radar image. Selecting any of the allowed percentages
changes the current width of the image proprotionately.

For the zoom frame, it provides a search tool. The various fields of
annotations or all of them for the genes can be searched for a
string. The string can be entered in a text field. The string may
contain more than one terms, spaces are interpreted as term
separators. The terms are conbined using logical 'AND'.  The hits
resulting from the search are displayed in the zoom frame, as
expression patterns.  The number of hits displayed in the zoom window
is limited to 200 hits and the length of each term in te search string
should be at least 2 characters long.

In addition, the toolbar frame contains an Info Box that displays
various textual information dependent on the position of the mouse
pointer over the zoom frame.  It can display:

             - gene information in the NAME field when the mouse is positioned 
               over an image row

             - experiment info, if positioned above the experiment image map
              
             - correlation of a genes expression pattern to that of the top
               gene in to zoom window displaying correlations, when the pointer
                is above is above the correlation image.

=head3 Zoom frame

The zoom frame displays expression patterns and annotations for genes
in the dataset. It can display genes selected from:

             - radar frame; it displays a given number of genes starting from the 
               genes whose image was clicked on

             - the toolbar; the result of the search performed using the searchtool
               is displayed here

             - the zoom frame itself; when a row is clicked on in the radar frame,
               the genes with the highest correlation in their expression pattern 
               are displayed

Information about various elements in the zoom frame is displayed in
the Info Box in the toolbar, dependent on the position of the mouse:

             - experiment info
             - gene info
             - correlation value

=head1 Class Methods

=head2 New

This is the constructor for the Explorer class.

Usage:   $explObj = Microarray::Explorer->New( dataset        => $dataset,
					           config         => $config,
					           displayConfig  => $displayConfig};

Here $dataset should be a Microarray::CdtDataset object, $config is a
Microarray::Config object, while $displayConfig is the name of a text
file that contains info concerning how to mark up various elements of
gene annotations.  It is expected that the displayConfig will be found
in the $config->gxDataPath directory.

=head1 Instance Methods

=head2 print_frameset

This subroutine will print the whole display window anew.
 
  usage: $explorer->print_frameset();

=head2 radar

This subroutine creates the content of the radar frame.
 
  usage: $explorer->radar();

=head2 toolbar

This sub creates the toolbar frame

  usage: $explorer->toolbar();

=head2 zoom

This subroutine creates the content of the zoom frame when called from
the radar frame.

  usage: $explorer->zoom();

=head2 search_feature

This method takes a a string of query words and the name of the
feature field to search.  This way, one can search for gene symbols,
gene names and/or GenBank accession numbers or any or all fields in
the feature description.

 usage: $explorer->search_feature("myWords", $field); 

               "myWords" - can have multiple words separated by space
                               (they are combined using logical 'AND')
               $field    - has to be one value of %kDespcriptions

The resulting hits are displayed in the zoom frame. If the number of
hits is too high, only kNumberOfMaxHits are displayed. The words in
the query string have to be separated by spaces and the length of the
words has to be more than 1 character.

=head2 neighbors

This method generates the html and images to display the most
correlated gene expression vectors versus a seed vector. When a gene
is clicked on in the zoom window, the most highly correlated gens are
retrieved and their expression patterns are displayed in the zoom
frame.

  usage: $explorer->neighbors();

The gene that was clicked on in the zoom frame is determined from the
cgi parameter 'seed'. The 'seed' gene is displayed as the first row on
the zoom image, with a perfect correlation of 1. The genes with the
highest correlations are displayed in the order of the value of their
correlation. All genes with correlation > 0.5 are displayed. The
correlation value is graphically indicated by the length of the orange
bar positioned on the right side of the expression pattern of the
gene, and the value can be displayed in the info bos by positioning
the mouse above the orange bar of a gene of interest.

=head1 Authors

Original work: Christian Rees

Re-write: Janos Demeter
jdemeter@genome.stanford.edu

=cut
