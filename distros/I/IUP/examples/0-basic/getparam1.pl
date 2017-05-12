# IupGetParam Example in IupLua;
# Shows a dialog with all possible fields.;

use IUP ':all';

IUP->SetLanguage("ENGLISH");

sub param_action {
  my ($self, $param_index) = @_;
  if ($param_index == -1) {
    warn "OK\n";
  }
  elsif ($param_index == -2) {
    warn "Map\n";
  }
  elsif ($param_index == -3) {
    warn "Cancel\n";
  }
  else {
    print "PARAM[$param_index]",
          " typ=", $self->GetParamParam($param_index)->GetAttribute('TYPE'),
          " val=", $self->GetParamValue($param_index),
          "\n";
  }
  return 1;
}

my $ret;
# set initial values;
my $pboolean = 1;
my $pinteger = 3456;
my $preal = 3.543;
my $pinteger2 = 192;
my $preal2 = 0.5;
my $pangle = 90;
my $pstring = "string text";
my $plist = 1;
my $pfile_name = "test.jpg";
my $pcolor = "255 0 128";
my $pstring2 = "first line\nsecond line";

($ret, $pboolean, $pinteger, $preal, $pinteger2, $preal2, $pangle, $pstring, $plist, $pfile_name, $pcolor, $pstring2) =
    IUP->GetParam("Title", \&param_action,
        "Boolean: %b[No,Yes]{Boolean Tip}\n".
        "Integer: %i{Integer Tip}\n".
        "Real 1: %r{Real Tip}\n".
        "Sep1 %t\n".
        "Integer: %i[0,255]{Integer Tip 2}\n".
        "Real 2: %r[-1.5,1.5]{Real Tip 2}\n".
        "Sep2 %t\n".
        "Angle: %a[0,360]{Angle Tip}\n".
        "String: %s{String Tip}\n".
        "List: %l|item1|item2|item3|{List Tip}\n".
        "File: %f[OPEN|*.bmp;*.jpg|CURRENT|NO|NO]{File Tip}\n".
        "Color: %c{Color Tip}\n".
        "Sep3 %t\n".
        "Multiline: %m{Multiline Tip}\n",
        $pboolean, $pinteger, $preal, $pinteger2, $preal2, $pangle, $pstring, $plist, $pfile_name, $pcolor, $pstring2);

IUP->Message("IupGetParam",
        "Boolean Value-> ".$pboolean."\n".
        "Integer-> ".$pinteger."\n".
        "Real 1-> ".$preal."\n".
        "Integer-> ".$pinteger2."\n".
        "Real 2-> ".$preal2."\n".
        "Angle-> ".$pangle."\n".
        "String-> ".$pstring."\n".
        "List Index-> ".$plist."\n".
        "File-> ".$pfile_name."\n".
        "Color-> ".$pcolor."\n".
        "String-> ".$pstring2) if ($ret != 0);
