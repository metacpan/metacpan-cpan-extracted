# IUP::Dialog example
#
# extremely simple dialog creation

use strict;
use warnings;

use IUP ':all';

sub msg {
  IUP->Message("Click!");
}

my $vbox = IUP::Vbox->new( GAP=>5, child=>[
                             IUP::Label->new(TITLE=>"Label before buttons:"), 
                             IUP::Button->new(TITLE=>"Test button1", ACTION=>\&msg),
                             IUP::Button->new(TITLE=>"Test button2", ACTION=>\&msg),
                             IUP::Button->new(TITLE=>"Test button3", ACTION=>\&msg),
                           ]);

my $dlg  = IUP::Dialog->new( child=>$vbox, MARGIN=>"10x10", TITLE=>"Hi!", SIZE=>"150x");

$dlg->Show();

IUP->MainLoop;
