# IUP::Image example
#
# Creates a button, a label, a toggle and a radio using an image.
# Uses an image for the cursor as well.

use strict;
use warnings;

use IUP ':all';
use FindBin;

# Load an image from file
my $img_x = IUP::Image->new( file=>"$FindBin::Bin/logotec.png" );

# Defines a cursor image
my $img_cursor = IUP::Image->new( pixels=>
  [[ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,1,2,2,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,1,1,2,0,0,2,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,2,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
   [ 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ],
  ], colors=>[ "0 0 0", "255 0 0", "128 0 0" ], HOTSPOT=>"21:10" 
);

# Creates a button and associates image img_x to it
my $btn = IUP::Button->new( IMAGE=>$img_x );

# Creates a label and associates image img_x to it
my $lbl = IUP::Label->new( IMAGE=>$img_x );

# Creates toggle and associates image img_x to it
my $tgl = IUP::Toggle->new( IMAGE=>$img_x );

# Creates toggles and associates images to them
my $tgl_radio_1 = IUP::Toggle->new( IMAGE=>"IUP_BR" );      #imglib demonstration
my $tgl_radio_2 = IUP::Toggle->new( IMAGE=>"IUP_Lua" );     #imglib demonstration
my $tgl_radio_3 = IUP::Toggle->new( IMAGE=>"IUP_Tecgraf" ); #imglib demonstration

# Creates label showing image size
my $lbl_size = IUP::Label->new( TITLE=>'"X" image width = '.$img_x->WIDTH.', "X" image height = '.$img_x->HEIGHT );

# Creates frames around the elements
my $frm_btn = IUP::Frame->new( child=>$btn, TITLE=>"button", SIZE=>"EIGHTHxEIGHTH" );
my $frm_lbl = IUP::Frame->new( child=>$lbl, TITLE=>"label" , SIZE=>"EIGHTHxEIGHTH" );
my $frm_tgl = IUP::Frame->new( child=>$tgl, TITLE=>"toggle", SIZE=>"EIGHTHxEIGHTH" );

my $frm_tgl_radio = IUP::Frame->new( TITLE=>"radio", SIZE=>"EIGHTHxEIGHTH", child=>
                      IUP::Radio->new( child=>
                        IUP::Vbox->new( child=>[ $tgl_radio_1, $tgl_radio_2, $tgl_radio_3 ] )
                      )        
                    );  

# Creates dialog dlg with an hbox containing a button, a label, and a toggle
my $dlg = IUP::Dialog->new( CURSOR=>$img_cursor, TITLE=>"IUP::Image Example", SIZE=>"400x200", child=>
            IUP::Vbox->new( MARGIN=>"5x5", GAP=>5, child=>[
              IUP::Hbox->new( child=>[$frm_btn, $frm_lbl, $frm_tgl, $frm_tgl_radio] ),
              IUP::Fill->new(),
              IUP::Hbox->new( child=>[IUP::Fill->new(), $lbl_size, IUP::Fill->new()] ),
            ] )
          );

# Shows dialog in the center of the screen
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
