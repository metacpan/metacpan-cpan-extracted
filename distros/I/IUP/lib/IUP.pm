package IUP;

use strict;
use warnings;

use Carp;

use IUP::Internal::LibraryIup;
use IUP::Constants;

our $VERSION = "0.305";

sub BEGIN {
  #warn "[DEBUG] IUP::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupOpen();
  IUP::Internal::LibraryIup::_IupImageLibOpen();
}

sub END {
  #warn "[DEBUG] IUP::END() started\n";
  IUP::Internal::LibraryIup::_IupClose();
}

sub import {
  my $pkg = shift;
  #warn "[DEBUG] IUP::import() started\n";
  return unless scalar(@_); #nothing to do

  my %tags = (
     #UPDATE when element list change
     ':basic'    => [qw/Constants Button Cbox Clipboard ColorBar ColorBrowser ColorDlg ProgressDlg Dial Dialog FileDlg Fill FontDlg Frame
                        Hbox Image Item Label List Menu MessageDlg Normalizer ProgressBar Radio Expander ScrollBox Link GridBox 
                        Sbox Separator Spin SpinBox Split Submenu Tabs Text Timer Toggle Tree User Val Vbox Zbox
                        AnimatedLabel BackgroundBox Calendar DatePick DetachBox FlatButton/], 
     ':extended' => [qw/Matrix MatrixList Cells Canvas CanvasGL Plot MglPlot LayoutDialog ElementPropertiesDialog Gauge Scintilla/],
     ':gl'       => [qw/GL::Button GL::CanvasBox GL::Expander GL::Frame GL::Label GL::Link GL::ProgressBar GL::ScrollBox GL::Separator 
                        GL::SizeBox GL::SubCanvas GL::Toggle GL::Val GL::Text GL::BackgroundBox/],
     ':all'      => [],
  );  
  @{$tags{':all'}} = ( @{$tags{':basic'}}, @{$tags{':extended'}}, @{$tags{':gl'}} );

  my %valid = map { $_ => 1 } @{$tags{':all'}};
  my %all_params = map { $_ => 1 } @_;
  my @wanted,  
  my @unknown;
  for my $m (@_) {
    if ($tags{$m}) {
      push @wanted, @{$tags{$m}};
    }
    elsif ($valid{$m}) {
      push @wanted, $m;
    }
    else {
      push @unknown, $m;
    }
  }
  croak "IUP: unexpected parameter: '" . (join "','", @unknown) . "'" if @unknown;

  my $eval_command;
  for (@wanted) {
    my @tags;
    #sort of a hack related to IUP::Constants
    push (@tags, ':all')   if ($_ eq 'Constants') && $all_params{':all'};
    push (@tags, ':basic') if ($_ eq 'Constants') && $all_params{':basic'};
    my $t = scalar(@tags) ? 'qw('.join(' ',@tags).')' : '';
    $eval_command .= "use IUP::$_ $t;\n";
  }
  if ($eval_command) {
    my $c = caller;
    my $code = "package $c;$eval_command";
    #warn "$code\n";
    eval($code);    
    croak "IUP: import() failed\n$@" if $@;
  }
}

### the main IUP control functions

sub MainLoop {
  #int IupMainLoop(void); [in C]
  #iup.MainLoop() -> ret: number [in Lua]
  return IUP::Internal::LibraryIup::_IupMainLoop();
}

sub MainLoopLevel {
  #int IupMainLoopLevel(void); [in C]
  #iup.MainLoopLevel() -> ret: number [in Lua]
  return IUP::Internal::LibraryIup::_IupMainLoopLevel();
}

sub LoopStep {
  #int IupLoopStep(void); [in C]
  #iup.LoopStep() -> ret: number [in Lua]
  return IUP::Internal::LibraryIup::_IupLoopStep();
}

sub LoopStepWait {
  #int IupLoopStepWait(void); [in C]
  #iup.LoopStepWait() -> ret: number [in Lua]
  return IUP::Internal::LibraryIup::_IupLoopStepWait();
}

sub ExitLoop {
  #void IupExitLoop(void); [in C]
  #iup.ExitLoop() [in Lua]
  IUP::Internal::LibraryIup::_IupExitLoop();
}

sub Flush {
  #void IupFlush(void); [in C]
  #iup.Flush() [in Lua]
  IUP::Internal::LibraryIup::_IupFlush();
}

### helper functions

sub Close {
  #void IupClose(void); [in C]
  #iup.Close() [in Lua]
  IUP::Internal::LibraryIup::_IupClose();
}

sub Open {
  #int IupOpen(int *argc, char ***argv); [in C]
  #[There is no equivalent in Lua]
  IUP::Internal::LibraryIup::_IupOpen();
}

sub GetAllDialogs {
  #int IupGetAllDialogs(char** names, int max_n); [in C]
  #iup.GetAllDialogs(max_n: number) -> (names: table, n: number) [in Lua]
  my ($pkg, $max_n) = @_;
  IUP::Internal::LibraryIup::_IupGetAllDialogs($max_n);
}

sub GetAllNames {
  #int IupGetAllNames(char** names, int max_n); [in C]
  #iup.GetAllNames(max_n: number) -> (names: table, n: number) [in Lua]
  my ($pkg, $max_n) = @_;
  IUP::Internal::LibraryIup::_IupGetAllNames($max_n);
}

sub GetFocus {
  #Ihandle* IupGetFocus(void); [in C]
  #iup.GetFocus() -> elem: ihandle [in Lua]
  my $ih = IUP::Internal::LibraryIup::_IupGetFocus();
  return IUP->GetByIhandle($ih);
}

sub GetByName {
  # BEWARE: different name form the oricinal C API
  #Ihandle *IupGetHandle(const char *name); [in C]
  #iup.GetHandle(name: string) -> ih: ihandle [in Lua]
  my ($pkg, $name) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGetHandle($name);
  return IUP->GetByIhandle($ih);
}

sub GetByIhandle {
  my ($pkg, $ih, $flag) = @_;
  $flag = 1 unless defined $flag; # default = 1 (create corresponding perl object if necessary)
  my $mapping = {
    #UPDATE when element list change
    animatedlabel   => 'IUP::AnimatedLabel',     # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupanimatedlabel.html
    backgroundbox   => 'IUP::BackgroundBox',     # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupbackgroundbox.html
    button          => 'IUP::Button',
    calendar        => 'IUP::Calendar',          # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupcalendar.html
    canvas          => 'IUP::Canvas',
    cbox            => 'IUP::Cbox',
    cells           => 'IUP::Cells',
    clipboard       => 'IUP::Clipboard',
    colorbar        => 'IUP::ColorBar',
    colorbrowser    => 'IUP::ColorBrowser',
    colordlg        => 'IUP::ColorDlg',
    constants       => 'IUP::Constants',
    datepick        => 'IUP::DatePick',          # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupdatepick.html
    detachbox       => 'IUP::DetachBox',         # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupdetachbox.html
    dial            => 'IUP::Dial',
    dialog          => 'IUP::Dialog',
    expander        => 'IUP::Expander',
    filedlg         => 'IUP::FileDlg',
    fill            => 'IUP::Fill',
    flatbutton      => 'IUP::FlatButton',        # https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupflatbutton.html
    fontdlg         => 'IUP::FontDlg',
    frame           => 'IUP::Frame',
    gauge           => 'IUP::Gauge',
    glbackgroundbox => 'IUP::GL::BackgroundBox', # https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iupglbackgroundbox.html
    glbutton        => 'IUP::GL::Button',
    glcanvas        => 'IUP::CanvasGL',
    glcanvasbox     => 'IUP::GL::CanvasBox',
    glexpander      => 'IUP::GL::Expander',
    glframe         => 'IUP::GL::Frame',
    gllabel         => 'IUP::GL::Label',
    gllink          => 'IUP::GL::Link',
    glprogressbar   => 'IUP::GL::ProgressBar',
    glscrollbox     => 'IUP::GL::ScrollBox',
    glseparator     => 'IUP::GL::Separator',
    glsizebox       => 'IUP::GL::SizeBox',
    glsubcanvas     => 'IUP::GL::SubCanvas',
    gltext          => 'IUP::GL::Text',          # https://webserver2.tecgraf.puc-rio.br/iup/en/gl/iupgltext.html
    gltoggle        => 'IUP::GL::Toggle',
    glval           => 'IUP::GL::Val',
    gridbox         => 'IUP::GridBox',
    hbox            => 'IUP::Hbox',
    image           => 'IUP::Image',
    imagergb        => 'IUP::Image',
    imagergba       => 'IUP::Image',
    item            => 'IUP::Item',
    label           => 'IUP::Label',
    link            => 'IUP::Link',
    list            => 'IUP::List',
    matrix          => 'IUP::Matrix',
    matrixlist      => 'IUP::MatrixList',
    menu            => 'IUP::Menu',
    messagedlg      => 'IUP::MessageDlg',
    mglplot         => 'IUP::MglPlot',
    multiline       => 'IUP::MultiLine',         # NOT-USED https://webserver2.tecgraf.puc-rio.br/iup/en/elem/iupmultiline.html
    normalizer      => 'IUP::Normalizer',
    olecontrol      => 'IUP::IUP::OLE',          # NOT-USED https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iupole.html
    plot            => 'IUP::Plot',              # https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iup_plot.html
    progressbar     => 'IUP::ProgressBar',
    progressdlg     => 'IUP::ProgressDlg',
    radio           => 'IUP::Radio',
    sbox            => 'IUP::Sbox',
    scintilla       => 'IUP::Scintilla',
    scrollbox       => 'IUP::ScrollBox',
    separator       => 'IUP::Separator',
    spin            => 'IUP::Spin',
    spinbox         => 'IUP::SpinBox',
    split           => 'IUP::Split',
    submenu         => 'IUP::Submenu',
    tabs            => 'IUP::Tabs',
    text            => 'IUP::Text',
    timer           => 'IUP::Timer',
    toggle          => 'IUP::Toggle',
    tree            => 'IUP::Tree',
    tuioclient      => 'IUP::Tuio',              # NOT-USED https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iuptuio.html
    user            => 'IUP::User',
    val             => 'IUP::Val',
    vbox            => 'IUP::Vbox',
    webbrowser      => 'IUP::WebBrowser',        # NOT-USED https://webserver2.tecgraf.puc-rio.br/iup/en/ctrl/iupweb.html
    zbox            => 'IUP::Zbox',
  };
  return unless $ih;
  my $e = IUP::Internal::LibraryIup::_translate_ih($ih);
  return $e if defined $e;
  if ($flag == 1) {
    my $c = IUP::Internal::LibraryIup::_IupGetClassName($ih);
    return unless $c;
    my $p = $mapping->{$c};
    eval { require $p};
    return unless $p;
    return $p->new_from_ihandle($ih);
  }
  return;
}

sub GetIhClassName {
  my ($pkg, $ih) = @_;
  return IUP::Internal::LibraryIup::_IupGetClassName($ih);
}

sub Help {
  #int IupHelp(const char* url); [in C]
  #iup.Help(url: string) [in Lua]
  my ($pkg, $url) = @_;
  return IUP::Internal::LibraryIup::_IupHelp($url);
}

sub LoadLED {
  #char *IupLoad(const char *filename); [in C]
  #iup.Load(filename: string) -> error: string [in Lua]
  #char *IupLoadBuffer(const char *buffer); [in C] (since 3.0)
  #iup.LoadBuffer(buffer: string) -> error: string [in Lua]
  my ($pkg, $led) = @_;
  if (ref($led) eq 'SCALAR') {
    my $ledtxt = $$led;
    return IUP::Internal::LibraryIup::_IupLoadBuffer($$led);
  }
  else {
    if (-f $led) {
      return IUP::Internal::LibraryIup::_IupLoad($led);
    }
    else {
      carp "[warning] non-existing file '$led'";
      return;
    }
  }
}

sub GetClassAttributes {
  #int IupGetClassAttributes(const char* classname, char** names, int max_n); [in C]
  #iup.GetClassAttributes(classname: string, max_n: number) -> (names: table, n: number) [in Lua]
  my ($pkg, $classname, $max_n) = @_;
  return IUP::Internal::LibraryIup::_IupGetClassAttributes($classname, $max_n);	
}

sub GetClassCallbacks {
  #int IUP::GetClassCallbacks(const char* classname, char** names, int max_n); [in C]
  #iup.GetClassCallbacks(classname: string[, max_n: number]) -> (names: table, n: number) [in Lua] 
  my ($pkg, $classname, $max_n) = @_;
  return IUP::Internal::LibraryIup::_IupGetClassCallbacks($classname, $max_n);	
}

sub SetClassDefaultAttribute {
  #void IupSetClassDefaultAttribute(const char* classname, const char *name, const char *value); [in C]
  #iup.SetClassDefaultAttribute(classname, name, value: string) [in Lua]
  my ($pkg, $classname, $name, $value) = @_;
  IUP::Internal::LibraryIup::_IupSetClassDefaultAttribute($classname, $name, $value);
}

sub CopyClassAttributes {
  #void IupCopyClassAttributes(Ihandle* src_ih, Ihandle* dst_ih); [in C]
  #iup.CopyClassAttributes(src_ih, dst_ih: ihandle) [in Lua]
  my ($pkg, $src, $dst) = @_;
  return IUP::Internal::LibraryIup::_IupCopyClassAttributes($src->ihandle, $dst->ihandle);
}

sub GetAllClasses {
  #int IupGetAllClasses(char** names, int max_n); [in C]
  #iup.GetAllClasses([max_n: number]) -> (names: table, n: number) [in Lua]
  my ($pkg, $max_n) = @_;
  return IUP::Internal::LibraryIup::_IupGetAllClasses($max_n);	
}

sub SetIdle {
  my ($pkg, $func) = @_;
  return IUP::Internal::LibraryIup::_SetIdle($func);
}

### accessing global attributes

sub GetGlobal {
  #char *IupGetGlobal(const char *name); [in C]
  #iup.GetGlobal(name: string) -> value: string [in Lua]
  my ($pkg, $name) = @_;
  return IUP::Internal::LibraryIup::_IupGetGlobal($name);
}

sub SetGlobal {
  #void IupSetGlobal(const char *name, const char *value); [in C]
  #iup.SetGlobal(name: string, value: string) [in Lua] 
  #void IupStoreGlobal(const char *name, const char *value); [in C]
  #iup.StoreGlobal(name: string, value: string) [in Lua] 
  my ($pkg, $name, $value) = @_;
  IUP::Internal::LibraryIup::_IupStoreGlobal($name, $value);
}

sub GetLanguage {
  #char* IupGetLanguage(void); [in C] 
  #iup.GetLanguage() -> (language: string) [in Lua] 
  return IUP::Internal::LibraryIup::_IupGetLanguage();
}

sub SetLanguage {
  #void IupSetLanguage(const char *lng); [in C] 
  #iup.SetLanguage(lng: string) [in Lua]
  my ($pkg, $lng) = @_;
  IUP::Internal::LibraryIup::_IupSetLanguage($lng);
}

sub Version {
  #char* IupVersion(void); [in C]
  #iup.Version() -> (version: string) [in Lua]
  return IUP::Internal::LibraryIup::_IupVersion();
}

sub VersionNumber {
  #int IupVersionNumber(void); [in C]
  #iup.VersionNumber() -> (version: number) [in Lua]
  return IUP::Internal::LibraryIup::_IupVersionNumber();
}

sub VersionDate {
  return IUP::Internal::LibraryIup::_IupVersionDate();
}

### simple dialogues

sub GetColor {
  my ($pkg, $x, $y, $r, $g, $b) = @_;
  # returns array: ($retval, $new_r, $new_g, $new_b)
  return IUP::Internal::LibraryIup::_IupGetColor($x, $y, $r, $g, $b);
}

sub GetFile {
  my ($pkg, $filename_filter) = @_;
  # returns array: ($retval, $filename)
  return IUP::Internal::LibraryIup::_IupGetFile($filename_filter);
}

sub GetParam {
  #int IupGetParam(const char* title, Iparamcb action, void* user_data, const char* format,...); [in C]
  #iup.GetParam(title: string, action: function, format: string,...) -> (status: boolean, ...) [in Lua]
  my ($pkg, $title, $action, $format, @initial_values) = @_;
  require IUP::Dialog;
  my $dlg = IUP::Dialog->new_no_ihandle();
  # we do not have ihandle of the new dialog at this point
  # we are gonna set ihandle during the first callback invocation (see XS code)
  my ($status, @output_values) = IUP::Internal::LibraryIup::_IupGetParam($title, $action, $dlg, $format, @initial_values);
  return ($status, @output_values);
}

sub ListDialog {  
  my ($pkg, $title, $list, $initial_selection, $max_lin, $max_col) = @_;
  if (defined $initial_selection && 'ARRAY' eq ref($initial_selection)) {
    #multiselect
    return IUP::Internal::LibraryIup::_IupListDialog_multi($title, $list, $initial_selection, $max_lin, $max_col);
  }
  else {
    #singleselect
    return IUP::Internal::LibraryIup::_IupListDialog_single($title, $list, $initial_selection, $max_lin, $max_col);
  }
  die;
}

sub GetText {
  my $pkg = shift;
  if (scalar @_ == 1) {
    return IUP::Internal::LibraryIup::_IupGetText('', $_[0]);
  }
  elsif (scalar @_ == 2) {
    return IUP::Internal::LibraryIup::_IupGetText($_[0], $_[1]);
  }
  carp('Warning: wrong params - IUP->GetText($title, $msg)');
  return;
}

sub Alarm {
  my ($pkg, $t, $m, $b1, $b2, $b3) = @_;
  return IUP::Internal::LibraryIup::_IupAlarm($t, $m, $b1, $b2, $b3);
}

sub Message {
  my $pkg = shift;
  if (scalar @_ == 1) {
    return IUP::Internal::LibraryIup::_IupMessage('', $_[0]);
  }
  elsif (scalar @_ == 2) {
    return IUP::Internal::LibraryIup::_IupMessage($_[0], $_[1]);
  }
  carp('Warning: wrong params - IUP->Message($title, $msg)');
  return;
}

#### new since iup-3.4

sub PlayInput {
  my ($pkg, $filename) = @_;
  return IUP::Internal::LibraryIup::_IupPlayInput($filename);
}

sub RecordInput {
  my ($pkg, $filename, $mode) = @_;
  return IUP::Internal::LibraryIup::_IupRecordInput($filename, $mode);
}

#### keyboard related macros
sub isXkey      { shift; return IUP::Internal::LibraryIup::_isXkey(@_); };
sub isShiftXkey { shift; return IUP::Internal::LibraryIup::_isShiftXkey(@_); };
sub isCtrlXkey  { shift; return IUP::Internal::LibraryIup::_isCtrlXkey(@_); };
sub isAltXkey   { shift; return IUP::Internal::LibraryIup::_isAltXkey(@_); };
sub isSysXkey   { shift; return IUP::Internal::LibraryIup::_isSysXkey(@_); };
sub isPrintable { shift; return IUP::Internal::LibraryIup::_isPrintable(@_); };

#### mouse related macros
sub isShift     { shift; return IUP::Internal::LibraryIup::_isShift(@_); };
sub isControl   { shift; return IUP::Internal::LibraryIup::_isControl(@_); };
sub isButton1   { shift; return IUP::Internal::LibraryIup::_isButton1(@_); };
sub isButton2   { shift; return IUP::Internal::LibraryIup::_isButton2(@_); };
sub isButton3   { shift; return IUP::Internal::LibraryIup::_isButton3(@_); };
sub isButton4   { shift; return IUP::Internal::LibraryIup::_isButton4(@_); };
sub isButton5   { shift; return IUP::Internal::LibraryIup::_isButton5(@_); };
sub isDouble    { shift; return IUP::Internal::LibraryIup::_isDouble(@_); };
sub isAlt       { shift; return IUP::Internal::LibraryIup::_isAlt(@_); };
sub isSys       { shift; return IUP::Internal::LibraryIup::_isSys(@_); };

1;