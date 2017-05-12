# IUP app example

use strict;
use warnings;

use IUP ':all';

my $img_bits1 = [
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1],
  [1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1],
  [1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1],
  [1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,0,2,0,2,0,2,2,0,2,2,2,0,0,0,2,2,2,0,0,2,0,2,2,0,0,0,2,2,2],
  [2,2,2,0,2,0,0,2,0,0,2,0,2,0,2,2,2,0,2,0,2,2,0,0,2,0,2,2,2,0,2,2],
  [2,2,2,0,2,0,2,2,0,2,2,0,2,2,2,2,2,0,2,0,2,2,2,0,2,0,2,2,2,0,2,2],
  [2,2,2,0,2,0,2,2,0,2,2,0,2,2,0,0,0,0,2,0,2,2,2,0,2,0,0,0,0,0,2,2],
  [2,2,2,0,2,0,2,2,0,2,2,0,2,0,2,2,2,0,2,0,2,2,2,0,2,0,2,2,2,2,2,2],
  [2,2,2,0,2,0,2,2,0,2,2,0,2,0,2,2,2,0,2,0,2,2,0,0,2,0,2,2,2,0,2,2],
  [2,2,2,0,2,0,2,2,0,2,2,0,2,2,0,0,0,0,2,2,0,0,2,0,2,2,0,0,0,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,2,2,2,0,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
];

my $img_bits2= [
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,2,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,2,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,2,2,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [3,3,3,0,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [3,3,3,0,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [3,3,3,0,3,0,3,0,3,3,0,3,3,3,1,1,0,3,3,3,0,0,3,0,3,3,0,0,0,3,3,3],
  [3,3,3,0,3,0,0,3,0,0,3,0,3,0,1,1,3,0,3,0,3,3,0,0,3,0,3,3,3,0,3,3],
  [3,3,3,0,3,0,3,3,0,3,3,0,3,3,1,1,3,0,3,0,3,3,3,0,3,0,3,3,3,0,3,3],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [3,3,3,0,3,0,3,3,0,3,3,0,3,0,1,1,3,0,3,0,3,3,0,0,3,0,3,3,3,0,3,3],
  [3,3,3,0,3,0,3,3,0,3,3,0,3,3,1,1,0,0,3,3,0,0,3,0,3,3,0,0,0,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,0,3,3,3,3,3,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,0,3,3,3,0,3,3,3,3,3,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,0,0,0,3,3,3,3,3,3,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,1,1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
  [2,2,2,2,2,2,2,3,3,3,3,3,3,3,1,1,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,2,3,3,3,3,3,3,3,3,1,1,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
];

# global elements
my $img1 = IUP::Image->new( pixels=>$img_bits1, 0=>"0 0 0", 1=>"BGCOLOR", 2=>"255 0 0" );
my $img2 = IUP::Image->new( pixels=>$img_bits2, 0=>"0 0 0", 1=>"0 255 0", 2=>"BGCOLOR", 3=>"255 0 0" );
my $mdiFrame; #global window
my @elements;

# global counters
my $line = 0;
my $id = 1;

sub getfocus_cb {
  my $self = shift;
  printf STDERR "$line-getfocus(%s#%s)\n",
         $self->GetClassName(), 
         ($self->GetAttribute("CINDEX") || 'n.a.');
  $line++;
  return IUP_DEFAULT;
}

sub killfocus_cb {
  my $self = shift;
  printf STDERR "$line-killfocus(%s#%s)\n",
         $self->GetClassName(), 
         ($self->GetAttribute("CINDEX") || 'n.a.');         
  $line++;
  return IUP_DEFAULT;
}

sub action {
  my $self = shift;
  printf STDERR "$line-action(%s#%s) Value=%s\n", 
         $self->GetClassName(), 
         ($self->GetAttribute("CINDEX") || 'n.a.'),
         ($self->GetAttribute("VALUE") || 'n.a.');
  $line++;
  return IUP_DEFAULT;
}

sub set_callbacks {
  my $ctrl = shift;
  $ctrl->SetCallback("GETFOCUS_CB", \&getfocus_cb);
  $ctrl->SetCallback("KILLFOCUS_CB", \&killfocus_cb);  
  $ctrl->SetCallback("ACTION", \&action) if $ctrl->IsValidCallbackName('ACTION');  
  my $child; #passing undef to GetNextChild gives the first child 
  while($child = $ctrl->GetNextChild($child)) {
    set_callbacks($child);  
  }
}

sub createDialog {
  my $frm_1 = IUP::Frame->new( child=>
                IUP::Vbox->new( child=>[
                  IUP::Button->new( TITLE=>"Button Text", CINDEX=>1 ),
                  IUP::Button->new( TITLE=>"", CINDEX=>2, BGCOLOR=>"255 128 0", RASTERSIZE=>"30x30" ),
                  IUP::Button->new( TITLE=>"", IMAGE=>$img1, CINDEX=>3 ),
                  IUP::Button->new( TITLE=>"", IMAGE=>$img1, CINDEX=>4, FLAT=>"YES" ),
                  IUP::Button->new( TITLE=>"", IMAGE=>$img1, IMPRESS=>$img2, CINDEX=>5 ),
                ]), TITLE=>"IupButton" );

  my $frm_2 = IUP::Frame->new( child=>
                IUP::Vbox->new( child=>[
                  IUP::Label->new( TITLE=>"Label Text\nLine 2\nLine 3", CINDEX=>1 ),
                  IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL", CINDEX=>2 ),
                  IUP::Label->new( TITLE=>"", IMAGE=>$img1, CINDEX=>3 ),
                ]), TITLE=>"IupLabel" );

  my $frm_3 = IUP::Frame->new( child=>
                IUP::Vbox->new( child=>[
                  IUP::Toggle->new( TITLE=>"Toggle Text", VALUE=>"ON", CINDEX=>1 ),
                  IUP::Toggle->new( TITLE=>"3State Text", VALUE=>"NOTDEF", CINDEX=>2, '3STATE'=>"YES" ),
                  IUP::Toggle->new( TITLE=>"", IMAGE=>$img1, IMPRESS=>$img2, CINDEX=>3 ),
                  IUP::Frame->new( child=>
                    IUP::Radio->new( TITLE=>"IupRadio", child=>
                      IUP::Vbox->new( child=>[
                        IUP::Toggle->new( TITLE=>"Toggle Text", CINDEX=>4 ),
                        IUP::Toggle->new( TITLE=>"Toggle Text", CINDEX=>5 ),
                      ]),                      
                    ),
                  )
                ]), TITLE=>"IupToggle" );

  my $text_1 = IUP::Text->new(
                 VALUE=>"IupText Text",
                 #SIZE=>"80x",
                 CINDEX=>1 );

  my $ml_1 = IUP::Text->new(
               MULTILINE=>1,
               VALUE=>"IupMultiline Text\nSecond Line\nThird Line",
               #SIZE=>"50x30",
               #EXPAND=>"YES",
               #SIZE=>"80x60",
               CINDEX=>1 );
               
  my $frm_4 = IUP::Frame->new( TITLE=>"IupText/IupMultiline", child=>IUP::Vbox->new( child=>[$text_1, $ml_1,]) );

  my $list_1 = IUP::List->new(
                 EXPAND=>"YES",
                 #SIZE=>"50x40",
                 VALUE=>1,
                 MULTIPLE=>"YES",
                 1=>"Item 1 Text",
                 2=>"Item 2 Text",
                 3=>"Item 3 Text Big Item",
                 4=>"Item 4 Text",
                 5=>"Item 5 Text",
                 6=>"Item 6 Text",
                 CINDEX=>1 );        

  my $list_2 = IUP::List->new(
                 DROPDOWN=>"YES",
                 EXPAND=>"YES",
                 VISIBLE_ITEMS=>3,
                 SIZE=>"50x",
                 VALUE=>2,
                 1=>"Item 1 Text",
                 2=>"Item 2 Text Big Item",
                 3=>"Item 3 Text",
                 4=>"Item 4 Text",
                 5=>"Item 5 Text",
                 6=>"Item 6 Text",
                 CINDEX=>2 );

  my $list_3 = IUP::List->new(
                 EDITBOX=>"YES",
                 EXPAND=>"YES",
                 SIZE=>"50x40",
                 VALUE=>"Test Value",
                 1=>"Item 1 Text",
                 2=>"Item 2 Text Big Item",
                 3=>"Item 3 Text",
                 4=>"Item 4 Text",
                 5=>"Item 5 Text",
                 6=>"Item 6 Text",
                 CINDEX=>3 );

  my $list_4 = IUP::List->new(
                 EDITBOX=>"YES",
                 DROPDOWN=>"YES",
                 EXPAND=>"YES",
                 VISIBLE_ITEMS=>3,
                 SIZE=>"50x10",
                 VALUE=>"Test Value",
                 1=>"Item 1 Text",
                 2=>"Item 2 Text Big Item",
                 3=>"Item 3 Text",
                 4=>"Item 4 Text",
                 5=>"Item 5 Text",
                 6=>"Item 6 Text",
                 CINDEX=>4 );
 
  my $frm_5 = IUP::Frame->new( child=>IUP::Vbox->new( child=>[$list_1, $list_2, $list_3, $list_4] ), TITLE=>"IupList" );

  my $hbox_1 = IUP::Hbox->new( child=>[$frm_1, $frm_2, $frm_3, $frm_4, $frm_5] );

  my $cnv_1 = IUP::Canvas->new( BGCOLOR=>"128 255 0" );

  my $vbox_1 = IUP::Vbox->new( child=>[$hbox_1, $cnv_1], MARGIN=>"5x5", ALIGNMENT=>"ARIGHT", GAP=>5 );
 
  set_callbacks($vbox_1);  
  
  my $dlg = IUP::Dialog->new( child=>$vbox_1, TITLE=>"MDI Child $id" );
  $id++;
  
#  $dlg->SetAttribute(
#          SHRINK=>"YES",
#          SIZE=>"500x200",
#          BGCOLOR=>"255 0 255",
#          FONT=>"Times New Roman:ITALIC:10",
#          FONT=>IUP_TIMES_BOLD_14,
#          COMPOSITED=>"YES",
#          OPACITY=>192 );
  
  return $dlg;
}

sub mdi_tilehoriz {
  my $self = shift;
  $self->GetDialog->MDIARRANGE("TILEHORIZONTAL");
  return IUP_DEFAULT;
}

sub mdi_tilevert {
  my $self = shift;
  $self->GetDialog->MDIARRANGE("TILEVERTICAL");
  return IUP_DEFAULT;
}

sub mdi_cascade {
  my $self = shift;
  $self->GetDialog->MDIARRANGE("CASCADE");
  return IUP_DEFAULT;
}

sub mdi_icon {
  my $self = shift;
  $self->GetDialog->MDIARRANGE("ICON");
  return IUP_DEFAULT;
}

sub mdi_next {
  my $self = shift;
  $self->GetDialog->MDIACTIVATE("NEXT");
  return IUP_DEFAULT;
}

sub mdi_previous {
  my $self = shift;
  $self->GetDialog->MDIACTIVATE("PREVIOUS");
  return IUP_DEFAULT;
}

sub mdi_closeall {
  my $self = shift;
  $self->GetDialog->MDICLOSEALL(undef);
  return IUP_DEFAULT;
}

sub mdi_activate {
  my $self = shift;
  printf STDERR "$line-mdi_activate(%s)\n", $self->GetName();
  $line++;
  return IUP_DEFAULT;
}

sub mdi_new {
  my $self = shift;
  my $dlg = createDialog();
  $dlg->SetAttribute( MDICHILD=>"YES", PARENTDIALOG=>$mdiFrame);
  $dlg->SetCallback( MDIACTIVATE_CB=>\&mdi_activate );
  #$dlg->PLACEMENT("MAXIMIZED");
  $dlg->Show();
  return IUP_DEFAULT;
}

sub createMenu {
  my $mnu = IUP::Menu->new( name=>"mnu", child=>[
              IUP::Submenu->new( TITLE=>"MDI", child=>
                IUP::Menu->new( child=>
                  IUP::Item->new( TITLE=>"New", ACTION=>\&mdi_new ),
                ),
              ),                
              IUP::Submenu->new( TITLE=>"Window", , child=> 
                IUP::Menu->new( name=>"winmenu", child=>[
                  IUP::Item->new( TITLE=>"Tile Horizontal", ACTION=>\&mdi_tilehoriz ), 
                  IUP::Item->new( TITLE=>"Tile Vertical", ACTION=>\&mdi_tilevert ), 
                  IUP::Item->new( TITLE=>"Cascade", ACTION=>\&mdi_cascade ), 
                  IUP::Item->new( TITLE=>"Icon Arrange", ACTION=>\&mdi_icon ), 
                  IUP::Item->new( TITLE=>"Close All", ACTION=>\&mdi_closeall ), 
                  IUP::Separator->new(),
                  IUP::Item->new( TITLE=>"Next", ACTION=>\&mdi_next ), 
                  IUP::Item->new( TITLE=>"Previous", ACTION=>\&mdi_previous ), 
                ]),
              ),
            ]);  
  return $mnu;
}

sub createFrame {
  my $menu = shift;
  my $mdiMenu = IUP->GetByName("winmenu");
  my $cnv = IUP::Canvas->new( MDICLIENT=>"YES", MDIMENU=>$mdiMenu );
  my $dlg = IUP::Dialog->new( name=>"mdiFrame", child=>$cnv, 
                              MENU=>$menu, TITLE=>"MDI Frame", 
                              MDIFRAME=>"YES", RASTERSIZE=>"800x600" );
  return $dlg;
}

### main ###

if (IUP->GetGlobal('DRIVER') ne 'Win32') {
  IUP->Message('BEWARE: MDI demo app works just with MS Windows GUI driver!');
}
else {
  $mdiFrame = createFrame( createMenu() );
  #$mdiFrame->PLACEMENT("MAXIMIZED");
  $mdiFrame->ShowXY(IUP_CENTER, IUP_CENTER);
  IUP->MainLoop();
}
