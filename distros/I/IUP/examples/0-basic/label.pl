# IUP::Label and IUP::Link example
#
# Creates three labels, one using all attributes except for image, other
# with normal text and the last one with an image.

use strict;
use warnings;

use IUP ':all';

# Defines a star image;
my $img_star = IUP::Image->new( pixels=>
  [[ 1,1,1,1,1,1,2,1,1,1,1,1,1 ],
   [ 1,1,1,1,1,1,2,1,1,1,1,1,1 ],
   [ 1,1,1,1,1,2,2,2,1,1,1,1,1 ],
   [ 1,1,1,1,1,2,2,2,1,1,1,1,1 ],
   [ 1,1,2,2,2,2,2,2,2,2,2,1,1 ],
   [ 2,2,2,2,2,2,2,2,2,2,2,2,2 ],
   [ 1,1,1,2,2,2,2,2,2,2,1,1,1 ],
   [ 1,1,1,1,2,2,2,2,2,1,1,1,1 ],
   [ 1,1,1,1,2,2,2,2,2,1,1,1,1 ],
   [ 1,1,1,2,2,1,1,2,2,2,1,1,1 ],
   [ 1,1,2,2,1,1,1,1,1,2,2,1,1 ],
   [ 1,2,2,1,1,1,1,1,1,1,2,2,1 ],
   [ 2,2,1,1,1,1,1,1,1,1,1,2,2 ],
  ], 
  1=>"0 0 0", 2=>"0 198 0" #colors
);

# Creates a label and sets all the attributes of label lbl, except for image;
my $lbl = IUP::Label->new( TITLE => "This label has the following attributes set:\nBGCOLOR = 255 255 0\nFGCOLOR = 0 0 255\nFONT = COURIER_NORMAL_14\nTITLE = All text contained here\nALIGNMENT = ACENTER", 
                  BGCOLOR => "255 255 0",
                  FGCOLOR => "0 0 255",
                  FONT => "COURIER_NORMAL_14",
                  ALIGNMENT => "ACENTER" );

# Creates a label to explain that the label on the right has an image;
my $lbl_explain = IUP::Label->new( TITLE=>"The label on the right has the image of a star" );

# Creates a label whose title is not important, cause it will have an image;
my $lbl_star = IUP::Label->new( TITLE=>"Does not matter", IMAGE=>$img_star );

# Creates a clickable label (= IupLink)
my $lbl_link = IUP::Link->new( TITLE=>"This is a link not label", URL=>'http://www.tecgraf.puc-rio.br/iup' );

# Creates dialog with these three labels;
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( MARGIN=>"10x10", child=>[ $lbl, IUP::Hbox->new( child=>[$lbl_explain, $lbl_star] ), $lbl_link ]),
                            GAP=>3, TITLE=>"IupLabel Example" );

# Shows dialog in the center of the screen;
$dlg->ShowXY ( IUP_CENTER, IUP_CENTER );
IUP->MainLoop;
