# IUP::Hbox example
#
# Creates a dialog with buttons placed side by side, with the purpose
# of showing the organization possibilities of elements inside an IUP::Hbox.
# The ALIGNMENT attribute is explored in all its possibilities to obtain
# the given effect.

use strict;
use warnings;

use IUP ':all';

my $fr1 = IUP::Frame->new( TITLE=>"Alignment = ATOP", child=>
            IUP::Hbox->new( child=>[
              IUP::Fill->new(),
              IUP::Button->new(TITLE=>"1", SIZE=>"30x30"),
              IUP::Button->new(TITLE=>"2", SIZE=>"30x40"),
              IUP::Button->new(TITLE=>"3", SIZE=>"30x50"),
              IUP::Fill->new(),
            ], ALIGNMENT=>"ATOP" )
          );

my $fr2 = IUP::Frame->new( TITLE=>"Alignment = ACENTER", child=>
            IUP::Hbox->new( child=>[
              IUP::Fill->new(),
              IUP::Button->new(TITLE=>"1", SIZE=>"30x30", ACTION=>""),
              IUP::Button->new(TITLE=>"2", SIZE=>"30x40", ACTION=>""),
              IUP::Button->new(TITLE=>"3", SIZE=>"30x50", ACTION=>""),
              IUP::Fill->new(),
            ], ALIGNMENT=>"ACENTER" )
          );

my $fr3 = IUP::Frame->new( TITLE=>"Alignment = ABOTTOM", child=>
            IUP::Hbox->new( child=>[
              IUP::Fill->new(),
              IUP::Button->new(TITLE=>"1", SIZE=>"30x30", ACTION=>""),
              IUP::Button->new(TITLE=>"2", SIZE=>"30x40", ACTION=>""),
              IUP::Button->new(TITLE=>"3", SIZE=>"30x50", ACTION=>""),
              IUP::Fill->new(),
            ], ALIGNMENT=>"ABOTTOM" )
          );

my $dlg = IUP::Dialog->new( 
            child=>IUP::Frame->new( child=>IUP::Vbox->new( child=>[$fr1,$fr2,$fr3] ), TITLE=>"HBOX" ),
            TITLE=>"Alignment",
            SIZE=>140 );

$dlg->Show();

IUP->MainLoop;
