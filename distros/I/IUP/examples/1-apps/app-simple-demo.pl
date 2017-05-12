#example used for screenshot - IUP.pod

 use IUP ':all';
 
 # demo callback handler
 sub my_cb {
   my $self = shift;
   IUP->Message("Hello from callback handler");
 }
 
 # create the main dialog
 sub init_dialog {
   my $menu = IUP::Menu->new( child=>[
                IUP::Item->new(TITLE=>"Message", ACTION=>\&my_cb ),
                IUP::Item->new(TITLE=>"Quit", ACTION=>sub { IUP_CLOSE } ),
              ]);
 
   my $frm1 = IUP::Frame->new( TITLE=>"IUP::Button", child=>
                IUP::Vbox->new( child=>[
                  IUP::Button->new( TITLE=>"Test Me", ACTION=>\&my_cb ),
                  IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf", TITLE=>"Text" ),
                  IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf" ),
                  IUP::Button->new( ACTION=>\&my_cb, IMAGE=>"IUP_Tecgraf", IMPRESS=>"IUP_Tecgraf" ),
                ])
              );

   my $frm2 = IUP::Frame->new( TITLE=>"IUP::Label", child=>
                IUP::Vbox->new( child=>[
                  IUP::Label->new( TITLE=>"Label Text" ),
                  IUP::Label->new( SEPARATOR=>"HORIZONTAL" ),
                  IUP::Label->new( IMAGE=>"IUP_Tecgraf" ),
                ])
              );
 
   my $frm3 = IUP::Frame->new( TITLE=>"IUP::Radio", child=>
                IUP::Vbox->new( child=>
                  IUP::Radio->new( child=>
                    IUP::Vbox->new( child=>[
                      IUP::Toggle->new( TITLE=>"Toggle Text", ACTION=>\&my_cb ),
                      IUP::Toggle->new( TITLE=>"Toggle Text", ACTION=>\&my_cb ),
                    ])
                  )
                )
              );
 
   my $frm4 = IUP::Frame->new( TITLE=>"IUP::Val", child=>IUP::Val->new( MIN=>0, MAX=>100 ) );

   my $frm5 = IUP::Frame->new( TITLE=>"IUP::ProgressBar", child=>IUP::ProgressBar->new( MIN=>0, MAX=>100, VALUE=>50 ) );

   my $hbox1 = IUP::Hbox->new( child=>[ $frm1, $frm2, $frm3 ] );
   my $hbox2 = IUP::Hbox->new( child=>[ $frm4, $frm5 ] );
   my $vbox1 = IUP::Vbox->new( child=>[ $hbox1, $hbox2 ], MARGIN=>"5x5", ALIGNMENT=>"ARIGHT", GAP=>"5" );
 
   return IUP::Dialog->new( MENU=>$menu, TITLE=>"Custom Dialog Sample", child=>$vbox1 );
 }

 # main program
 my $dlg = init_dialog();
 $dlg->Show();
 IUP->MainLoop();
