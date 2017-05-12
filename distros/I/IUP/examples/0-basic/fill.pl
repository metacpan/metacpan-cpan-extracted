# IUP::Fill Example
#
# Uses the IUP::Fill element to horizontally centralize a button 
# and to justify it to the left and right.

use strict;
use warnings;

use IUP ':all';

# Creates frame with left aligned button
my $frame_left = IUP::Frame->new( TITLE=>"Left aligned", child=>
                   IUP::Hbox->new( child=>[
                     IUP::Button->new( TITLE=>"Ok" ),
                     IUP::Fill->new(),
                   ] )
                 );

# Creates frame with centered button;
my $frame_center = IUP::Frame->new( TITLE=>"Centered", child=>
                     IUP::Hbox->new( child=>[
                       IUP::Fill->new(),
                       IUP::Button->new( TITLE=>"Ok" ),
                       IUP::Fill->new(),
                     ] )
                   );

# Creates frame with right aligned button;
my $frame_right = IUP::Frame->new( TITLE=>"Right aligned", child=>
                    IUP::Hbox->new( child=>[
                      IUP::Fill->new(),
                      IUP::Button->new( TITLE=>"Ok" ),
                    ] )
                  );

# Creates dialog with these three frames;
my $dialog = IUP::Dialog->new( SIZE=>150, MARGIN=>"5x5", TITLE=>"IUP::Fill",
                               child=>IUP::Vbox->new([$frame_left, $frame_center, $frame_right]) );

# Shows dialog in the center of the screen;
$dialog->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
