# IUP::Text (formating) example

use strict;
use warnings;

use IUP ':all';

#xxxFIXME not finished yet but somehow works

sub text2multiline {
  my ($self, $attribute) = @_;
  my $mltline = $self->GetDialogChild("mltline");
  my $text = $self->GetDialogChild("text");
  warn "t2m: $attribute=", $text->VALUE, "\n";
  $mltline->SetAttribute($attribute, $text->VALUE);
}

sub multiline2text {
  my ($self, $attribute) = @_;
  my $mltline = $self->GetDialogChild("mltline");
  my $text = $self->GetDialogChild("text");
  $text->VALUE($mltline->GetAttribute($attribute));
}

sub btn_append_cb {
  my $self = shift;
  text2multiline($self, "APPEND"); 
  return IUP_DEFAULT;
}

sub btn_insert_cb {
  my $self = shift;
  text2multiline($self, "INSERT"); 
  return IUP_DEFAULT;
}

sub btn_clip_cb {
  my $self = shift;
  text2multiline($self, "CLIPBOARD"); 
  return IUP_DEFAULT;
}

sub btn_key_cb {
  my $self = shift;
  my $mltline = $self->GetDialogChild("mltline");
  my $text = $self->GetDialogChild("text");
  $mltline->SetFocus();
  IUP->Flush();
  #xxxFIXME
  #IupSetfAttribute(NULL, "KEY", "%d", iupKeyNameToCode(IupGetAttribute(text, "VALUE")));
  return IUP_DEFAULT;
}

sub btn_caret_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "CARET"); 
  }
  else {
    multiline2text($self, "CARET");
  }
  return IUP_DEFAULT;
}

sub btn_readonly_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "READONLY"); 
  }
  else {
    multiline2text($self, "READONLY");
  }
  return IUP_DEFAULT;
}

sub btn_selection_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "SELECTION"); 
  }
  else {
    multiline2text($self, "SELECTION");
  }
  return IUP_DEFAULT;
}

sub btn_selectedtext_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "SELECTEDTEXT"); 
  }
  else {
    multiline2text($self, "SELECTEDTEXT");
  }
  return IUP_DEFAULT;
}

sub btn_overwrite_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "OVERWRITE"); 
  }
  else {
    multiline2text($self, "OVERWRITE");
  }
  return IUP_DEFAULT;
}

sub btn_active_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "ACTIVE"); 
  }
  else {
    multiline2text($self, "ACTIVE");
  }
  return IUP_DEFAULT;
}

sub btn_remformat_cb {
  my $self = shift;
  text2multiline($self, "REMOVEFORMATTING"); 
  return IUP_DEFAULT;
}

sub btn_nc_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "NC"); 
  }
  else {
    multiline2text($self, "NC");
  }
  return IUP_DEFAULT;
}

sub btn_value_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "VALUE"); 
  }
  else {
    multiline2text($self, "VALUE");
  }
  return IUP_DEFAULT;
}

sub btn_tabsize_cb {
  my $self = shift;
  my $opt = IUP->GetByName("text2multi");
  if ($opt->VALUE eq 'ON') {
    text2multiline($self, "TABSIZE"); 
  }
  else {
    multiline2text($self, "TABSIZE");
  }
  return IUP_DEFAULT;
}

sub k_f2 {
  printf("K_F2\n");
  return IUP_DEFAULT;
}

sub file_open {
  my ($rv, $filename) = IUP->GetFile();
  warn "filename=$filename\n";
  return IUP_DEFAULT;
}

sub k_any {
  my ($self, $c) = @_;
  warn "K_ANY (c=$c, printable=", IUP->isPrintable($c), ")\n";
  printf ">> CARET(%s)\n", $self->GetAttribute("CARET");
  if ($c == K_cA) {
    return IUP_IGNORE;
  }
  elsif ($c == K_F2) {
    k_f2();
    return IUP_IGNORE;
  }
  elsif ($c == K_cO) {
    file_open();
    return IUP_IGNORE;
  }
  return IUP_CONTINUE;
}

sub action {
  # unsed at the moment
  my ($self, $c, $after) = @_;
  warn "ACTION (c=$c, after=$after)\n";
  if (IUP->isPrintable($c)) {
    printf "ACTION (printable '%s')\n", IUP->KeyCodeToName($c); #xxxCHECKLATER we do not support KeyCodeToName
  }
  if ($c == K_i) {
    return IUP_IGNORE;   # OK
  }
  if ($c == K_cD) {
    return IUP_IGNORE;   # Sound a beep in Windows
  }
  if ($c == K_h) {
    return K_j;
  }
  return IUP_DEFAULT;
}

sub caret_cb {
  my ($self, $lin, $col, $pos) = @_;
  warn "CARET_CB ($lin, $col, $pos)\n";
  printf ">> CARET(%s - %s)\n", $self->CARET, $self->CARETPOS;
  return IUP_DEFAULT;
}

sub getfocus_cb {
  warn "GETFOCUS_CB\n";
  return IUP_DEFAULT;
}

sub help_cb {
  warn "HELP_CB\n";
  return IUP_DEFAULT;
}
     
sub killfocus_cb {
  warn "KILLFOCUS_CB\n";
  return IUP_DEFAULT;
}

sub leavewindow_cb {
  warn "LEAVEWINDOW_CB\n";
  return IUP_DEFAULT;
}

sub enterwindow_cb {
  warn "ENTERWINDOW_CB\n";
  return IUP_DEFAULT;
}

sub btn_def_esc_cb {
  warn "DEFAULTESC\n";
  return IUP_DEFAULT;
}

sub btn_def_enter_cb {
  warn "DEFAULTENTER\n";
  return IUP_DEFAULT;
}

sub dropfiles_cb {
  my ($self, $filename, $num, $x, $y) = @_;
  printf "DROPFILES_CB (%s, %d, x=%d, y=%d)\n", $filename, $num, $x, $y;
  return IUP_DEFAULT;
}

sub button_cb {
  my ($self, $but, $pressed, $x, $y, $status) = @_;
  printf "BUTTON_CB (but=%c (%d), x=%d, y=%d [%s])\n", $but, $pressed, $x, $y, $status;
  my $pos = $self->ConvertXYToPos($x, $y);
  my ($lin, $col) = $self->TextConvertPosToLinCol($pos);
  printf ">> (lin=%d, col=%d, pos=%d)\n", $lin, $col, $pos;
  return IUP_DEFAULT;
}

sub motion_cb {
  my ($self, $x, $y, $status) = @_;
  printf "MOTION_CB (x=%d, y=%d [%s])\n", $x, $y, $status;
  my $pos = $self->ConvertXYToPos($x, $y);
  my ($lin, $col) = $self->TextConvertPosToLinCol($pos);  
  printf ">> (lin=%d, col=%d, pos=%d)\n", $lin, $col, $pos;
  return IUP_DEFAULT;
}

sub TextTest {

#?  Iup->SetGlobal("UTF8AUTOCONVERT", "NO");

  my $text = IUP::Text->new();
  $text->SetAttribute("EXPAND", "HORIZONTAL");
#?  $text->SetAttribute("VALUE", "Single Line Text");
  $text->SetAttribute("CUEBANNER", "Enter Attribute Value Here");
  $text->SetAttribute("NAME", "text");
  $text->SetAttribute("TIP", "Attribute Value");

  my $opt = IUP::Toggle->new( TITLE=>"Set/Get", VALUE=>"ON", name=>"text2multi" );

  my $mltline = IUP::Text->new( MULTILINE=>"YES", NAME=>"mltline" );

  $mltline->SetCallback("DROPFILES_CB",   \&dropfiles_cb);
  $mltline->SetCallback("BUTTON_CB",      \&button_cb);
#? $mltline->SetCallback("MOTION_CB",      \&motion_cb);
  $mltline->SetCallback("HELP_CB",        \&help_cb);
  $mltline->SetCallback("GETFOCUS_CB",    \&getfocus_cb); 
  $mltline->SetCallback("KILLFOCUS_CB",   \&killfocus_cb);
  $mltline->SetCallback("ENTERWINDOW_CB", \&enterwindow_cb);
  $mltline->SetCallback("LEAVEWINDOW_CB", \&leavewindow_cb);
#?  $mltline->SetCallback("ACTION",         \&action);
  $mltline->SetCallback("K_ANY",          \&k_any);
  #$mltline->SetCallback("K_F2", \&k_f2); #xxxCHECKLATER we do not support K_xxx callbacks
  $mltline->SetCallback("CARET_CB",       \&caret_cb);
#?  $mltline->SetAttribute("WORDWRAP", "YES");
#?  $mltline->SetAttribute("BORDER", "NO");
#?  $mltline->SetAttribute("AUTOHIDE", "YES");
#?  $mltline->SetAttribute("BGCOLOR", "255 0 128");
#?  $mltline->SetAttribute("FGCOLOR", "0 128 192");
#?  $mltline->SetAttribute("PADDING", "15x15");
#?  $mltline->SetAttribute("VALUE", "First Line\nSecond Line Big Big Big\nThird Line\nmore\nmore\nΓ§Γ£ΓµΓ΅Γ³Γ©"); # UTF-8
  $mltline->SetAttribute("VALUE", "First Line\nSecond Line Big Big Big\nThird Line\nmore\nmore\nηγυασι"); # Windows-1252
  $mltline->SetAttribute("TIP", "First Line\nSecond Line\nThird Line");
#?  $mltline->SetAttribute("FONT", "Helvetica, 14");
#?  $mltline->SetAttribute("MASK", IUP_MASK_FLOAT);
#?  $mltline->SetAttribute("FILTER", "UPPERCASE");
#?  $mltline->SetAttribute("ALIGNMENT", "ACENTER");
#?  $mltline->SetAttribute("CANFOCUS", "NO");

  # Turns on multiline expand and text horizontal expand
  $mltline->SetAttribute("SIZE", "80x40");
  $mltline->SetAttribute("EXPAND", "YES");

#?  $mltline->SetAttribute("FONT", "Courier, 16");
#?  $mltline->SetAttribute("FONT", "Arial, 12");
#?  $mltline->SetAttribute("FORMATTING", "YES");

  my $formatting = 0;
  if ($formatting) { # just to make easier to comment this section
    # formatting before Map
    my $formattag;
    $mltline->SetAttribute("FORMATTING", "YES");
    $formattag = IUP::User->new();
    $formattag->SetAttribute("ALIGNMENT", "CENTER");
    $formattag->SetAttribute("SPACEAFTER", "10");
    $formattag->SetAttribute("FONTSIZE", "24");
    $formattag->SetAttribute("SELECTION", "3,1:3,50");
    $mltline->SetAttribute("ADDFORMATTAG_HANDLE", $formattag);

    $formattag = IUP::User->new();
    $formattag->SetAttribute("BGCOLOR", "255 128 64");
    $formattag->SetAttribute("UNDERLINE", "SINGLE");
    $formattag->SetAttribute("WEIGHT", "BOLD");
    $formattag->SetAttribute("SELECTION", "3,7:3,11");
    $mltline->SetAttribute("ADDFORMATTAG_HANDLE", $formattag);
  }

  # Creates buttons
#?  my $btn_append = IUP::Button->new( TITLE=>"APPEND ηγυασι" )   # Windows-1252
#?  my $btn_append = IUP::Button->new( TITLE=>"APPEND Γ§Γ£ΓµΓ΅Γ³Γ©" );  # UTF-8
  my $btn_append = IUP::Button->new( TITLE=>"&APPEND" );
  my $btn_insert = IUP::Button->new( TITLE=>"INSERT" );
  my $btn_caret = IUP::Button->new( TITLE=>"CARET" );
  my $btn_readonly = IUP::Button->new( TITLE=>"READONLY" );
  my $btn_selection = IUP::Button->new( TITLE=>"SELECTION" );
  my $btn_selectedtext = IUP::Button->new( TITLE=>"SELECTEDTEXT" );
  my $btn_nc = IUP::Button->new( TITLE=>"NC" );
  my $btn_value = IUP::Button->new( TITLE=>"VALUE" );
  my $btn_tabsize = IUP::Button->new( TITLE=>"TABSIZE" );
  my $btn_clip = IUP::Button->new( TITLE=>"CLIPBOARD" );
  my $btn_key = IUP::Button->new( TITLE=>"KEY" );
  my $btn_def_enter = IUP::Button->new( TITLE=>"Default Enter" );
  my $btn_def_esc = IUP::Button->new( TITLE=>"Default Esc" );
  my $btn_active = IUP::Button->new( TITLE=>"ACTIVE" );
  my $btn_remformat = IUP::Button->new( TITLE=>"REMOVEFORMATTING" );
  my $btn_overwrite = IUP::Button->new( TITLE=>"OVERWRITE" );

  $btn_append->SetAttribute( TIP => "First Line\nSecond Line\nThird Line" );

  #Registers callbacks
  $btn_append->SetCallback("ACTION", \& btn_append_cb);
  $btn_insert->SetCallback("ACTION", \& btn_insert_cb);
  $btn_caret->SetCallback("ACTION", \& btn_caret_cb);
  $btn_readonly->SetCallback("ACTION", \& btn_readonly_cb);
  $btn_selection->SetCallback("ACTION", \& btn_selection_cb);
  $btn_selectedtext->SetCallback("ACTION", \& btn_selectedtext_cb);
  $btn_nc->SetCallback("ACTION", \& btn_nc_cb);
  $btn_value->SetCallback("ACTION", \& btn_value_cb);
  $btn_tabsize->SetCallback("ACTION", \& btn_tabsize_cb);
  $btn_clip->SetCallback("ACTION", \& btn_clip_cb);
  $btn_key->SetCallback("ACTION", \& btn_key_cb);
  $btn_def_enter->SetCallback("ACTION", \& btn_def_enter_cb);
  $btn_def_esc->SetCallback("ACTION", \& btn_def_esc_cb);
  $btn_active->SetCallback("ACTION", \& btn_active_cb);
  $btn_remformat->SetCallback("ACTION", \& btn_remformat_cb);
  $btn_overwrite->SetCallback("ACTION", \& btn_overwrite_cb);

  my $lbl = IUP::Label->new( TITLE=>"&Multiline:", PADDING=>"2x2");

  # Creates dlg
  my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( [
                                $lbl,
                                $mltline, 
                                IUP::Hbox->new( [$text, $opt] ),
                                IUP::Hbox->new( [$btn_append, $btn_insert, $btn_caret, $btn_readonly, $btn_selection] ),
                                IUP::Hbox->new( [$btn_selectedtext, $btn_nc, $btn_value, $btn_tabsize, $btn_clip, $btn_key] ),
                                IUP::Hbox->new( [$btn_def_enter, $btn_def_esc, $btn_active, $btn_remformat, $btn_overwrite] ),
                              ] ),
                                TITLE=>"IupText Test",
                                MARGIN=>"10x10",
                                GAP=>5,
                                DEFAULTENTER=>$btn_def_enter,
                                DEFAULTESC=>$btn_def_esc,
                                SHRINK=>"YES" );  

  if ($formatting) { # just to make easier to comment this section
    $dlg->Map(); # formatting after Map
    my $formattag = IUP::User->new();
    $formattag->SetAttribute( ITALIC=>"YES", STRIKEOUT=>"YES", SELECTION=>"2,1:2,12" );
    $mltline->SetAttribute( ADDFORMATTAG_HANDLE=>$formattag );
  }

  # Shows dlg in the center of the screen
  $dlg->ShowXY(IUP_CENTER, IUP_CENTER);
  $mltline->SetFocus();
}

### main ###

TextTest();
IUP->MainLoop();
