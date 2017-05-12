# IUP::Frame Example
#
# Draws a frame around a button. Note that FGCOLOR is added to the
# frame but it is inherited by the button.

use strict;
use warnings;

use IUP ':all';

# Creates frame with a label;
my $frame = IUP::Frame->new(
              child=>IUP::Hbox->new( child=>[
                IUP::Fill->new(),
                IUP::Label->new( TITLE=>"IUP::Frame Test - with quite a long label text" ),
                IUP::Fill->new(),
              ] ) );
            
$frame->SetAttribute(
  MARGIN =>"20x20",
  FGCOLOR=>"255 0 0",
  SIZE   =>"EIGHTHxEIGHTH",
  TITLE  =>"This is the frame",
  FGCOLOR=>"255 0 0"
);

# Creates dialog;
my $dialog = IUP::Dialog->new( child=>$frame );

# Sets dialog's title;
$dialog->TITLE("IUP::Frame");

$dialog->ShowXY(IUP_CENTER,IUP_CENTER); # Shows dialog in the center of the screen

IUP->MainLoop;
