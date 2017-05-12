#example used for screenshot - IUP.pod

use strict;
use warnings;
use IUP ':all';

# demo callback handler
sub my_cb {
  my $self = shift;
  IUP->Message("Hello");
}

# create the main dialog
sub init_dialog {
  my $menu = IUP::Menu->new( child=>[
               IUP::Submenu->new( TITLE=>"IupSubmenu 1", child=>IUP::Menu->new( child=>[
                 IUP::Item->new( TITLE=>"IupItem 1 Checked", ACTION=>\&my_cb, VALUE=>"ON" ),
                 IUP::Separator->new(),
                 IUP::Item->new( TITLE=>"IupItem 2 Disabled", ACTION=>\&my_cb, ACTIVE=>"NO" ),
               ])),
               IUP::Item->new(TITLE=>"IupItem 3", ACTION=>\&my_cb ),
               IUP::Item->new(TITLE=>"IupItem 4", ACTION=>\&my_cb ),
             ]);

  my $frm1 = IUP::Frame->new( TITLE=>"IupButton", child=>
               IUP::Vbox->new( child=>[
                 IUP::Button->new( TITLE=>"Button Text", ACTION=>\&my_cb ),
                 IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf", TITLE=>"Text" ),
                 IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf" ),
                 IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf", IMPRESS=>"IUP_Tecgraf" ),
               ])
             );

  my $frm2 = IUP::Frame->new( TITLE=>"IupLabel", child=>
               IUP::Vbox->new( child=>[
                 IUP::Label->new( TITLE=>"Label Text" ),
                 IUP::Label->new( SEPARATOR=>"HORIZONTAL" ),
                 IUP::Label->new( IMAGE=>"IUP_Tecgraf" ),
               ])
             );

  my $frm3 = IUP::Frame->new( TITLE=>"IupToggle", child=>
               IUP::Vbox->new( child=>[
                 IUP::Toggle->new( TITLE=>"Toggle Text", ACTION=>\&my_cb, VALUE=>"ON" ),
                 IUP::Toggle->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf", IMPRESS=>"IUP_Tecgraf", VALUE=>"ON" ),
                 IUP::Frame->new( TITLE=>"IupRadio", child=>
                   IUP::Radio->new( child=>
                     IUP::Vbox->new( child=>[
                       IUP::Toggle->new( TITLE=>"Toggle Text", ACTION=>\&my_cb ),
                       IUP::Toggle->new( TITLE=>"Toggle Text", ACTION=>\&my_cb ),
                     ])
                   )
                 )
               ])
             );

  my $frm4 = IUP::Frame->new( TITLE=>"IupText", child=>
               IUP::Vbox->new( child=>[
                 IUP::Text->new( ACTION=>\&my_cb, VALUE=>"Single Line Text", SIZE=>"80x" ),
                 IUP::Text->new( MULTILINE=>"YES", VALUE=>"Multiline Text\nSecond Line\nThird Line",
                                 ACTION=>\&my_cb, EXPAND=>"YES", SIZE=>"80x60" )
               ])
             );

  my $frm5 = IUP::Frame->new( TITLE=>"IupList", child => 
               IUP::Vbox->new( child=>[
                 IUP::List->new( ACTION=>\&my_cb, EXPAND=>"YES", VALUE=>"1",
                                 1=>"Item 1 Text", 2=>"Item 2 Text", 3=>"Item 3 Text" ),
                 IUP::List->new( ACTION=>\&my_cb, DROPDOWN=>"YES", EXPAND=>"YES", VALUE=>"2",
                                 1=>"Item 1 Text", 2=>"Item 2 Text", 3=>"Item 3 Text" ),
                 IUP::List->new( ACTION=>\&my_cb, EDITBOX=>"YES",  EXPAND=>"YES", VALUE=>"3",
                                 1=>"Item 1 Text", 2=>"Item 2 Text", 3=>"Item 3 Text" ),
               ])
             );

  my $frm6 = IUP::Frame->new( TITLE=>"IupVal", child=>IUP::Val->new( MIN=>0, MAX=>100 ) );

  my $frm7 = IUP::Frame->new( TITLE=>"IupProgressBar", child=>IUP::ProgressBar->new( MIN=>0, MAX=>100, VALUE=>50 ) );

  my $frm8 = IUP::Frame->new( TITLE=>"IupTabs",
                              child=>IUP::Tabs->new( child=>[
                                  IUP::Label->new( TABTITLE=>"Tab Title 0", EXPAND=>"HORIZONTAL"),
                                  IUP::Label->new( TABTITLE=>"Tab Title 1", EXPAND=>"HORIZONTAL"),
                                  IUP::Label->new( TABTITLE=>"Tab Title 2", EXPAND=>"HORIZONTAL"),
                              ]));
  
  my $frm9 = IUP::Frame->new( TITLE=>"IupCanvas", child=>IUP::Canvas->new( SIZE=>"x50", SCROLLBAR=>"HORIZONTAL", BGCOLOR=>"128 255 0" ) );

  my $hbox1 = IUP::Hbox->new( child=>[ $frm1, $frm2, $frm3, $frm4, $frm5] );
  my $hbox2 = IUP::Hbox->new( child=>[ $frm6, $frm7, $frm8] );
  my $vbox1 = IUP::Vbox->new( child=> [$hbox1, $hbox2, $frm9], MARGIN=>"5x5", ALIGNMENT=>"ARIGHT", GAP=>"5" );

  return IUP::Dialog->new( MENU=>$menu, TITLE=>"Iup Sample", child=>$vbox1, SIZE=>"400x" );
}

# main program
my $dlg = init_dialog();
$dlg->Show();
IUP->MainLoop();
