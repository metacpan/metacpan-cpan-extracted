use strict;
use warnings;

use IUP ':all';

my $MAXPLOT = 6;
my @plot = ();        # Plot controls
my ($dial1, $dial2);  # dials for zooming
my ($tgg1, $tgg2);    # auto scale on|off toggles
my ($tgg3, $tgg4);    # grid show|hide toggles
my $tgg5;             # legend show|hide toggle
my $tabs;             # tabbed control

sub delete_cb {
  my ($self, $index, $sample_index, $x, $y) = @_;
  printf("DELETE_CB(%d, %d, %g, %g)\n", $index, $sample_index, $x, $y);
  return IUP_DEFAULT;
}

sub select_cb {
my ($self, $index, $sample_index, $x, $y, $select) = @_;
  printf("SELECT_CB(%d, %d, %g, %g, %d)\n", $index, $sample_index, $x, $y, $select);
  return IUP_DEFAULT;
}

sub edit_cb {
  #(Ihandle* ih, int index, int sample_index, float x, float y, float *new_x, float *new_y)
  # xxxTODO: references
  # perhaps - return (IUP_DEFAULT, $new_x, $new_y);
  my ($self, $index, $sample_index, $x, $y) = @_;
  printf STDERR "EDIT_CB(%d, %d, %g, %g)\n", $index, $sample_index, $x, $y;  
  return (IUP_DEFAULT, $x, $y+0.001);
}

sub postdraw_cb {
  #(Ihandle* ih, cdCanvas* cnv)
  my ($self, $cnv) = @_;
  my ($ix, $iy) = $self->PlotTransform(0.003, 0.02);  
  $cnv->cdFont(undef, CD_BOLD, 10);
  $cnv->cdTextAlignment(CD_SOUTH);
  $cnv->cdText($ix, $iy, "My Inline Legend");
  return IUP_DEFAULT;
}

sub predraw_cb {
  #(Ihandle* ih, cdCanvas* cnv)
  my ($self, $cnv) = @_;
  #printf("PREDRAW_CB()\n");
  return IUP_DEFAULT;
}

sub InitPlots {
  my $theFac;

  # PLOT 0 - MakeExamplePlot1
  $plot[0]->SetAttribute("TITLE", "AutoScale");
  $plot[0]->SetAttribute("MARGINTOP", "40");
  $plot[0]->SetAttribute("MARGINLEFT", "40");
  $plot[0]->SetAttribute("MARGINBOTTOM", "50");
  $plot[0]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[0]->SetAttribute("AXS_XLABEL", "gnu (Foo)");
  $plot[0]->SetAttribute("AXS_YLABEL", "Space (m^3)");
  $plot[0]->SetAttribute("AXS_YFONTSIZE", "7");
  $plot[0]->SetAttribute("AXS_YTICKFONTSIZE", "7");
  $plot[0]->SetAttribute("LEGENDSHOW", "YES");
  $plot[0]->SetAttribute("AXS_XFONTSIZE", "10");
  $plot[0]->SetAttribute("AXS_YFONTSIZE", "10");
  $plot[0]->SetAttribute("AXS_XLABELCENTERED", "NO");
  $plot[0]->SetAttribute("AXS_YLABELCENTERED", "NO");
  
#  IupSetAttribute(plot[0], "USE_IMAGERGB", "YES");
#  IupSetAttribute(plot[0], "USE_GDI+", "YES");

  $theFac = 1.0/(100*100*100);
  $plot[0]->PlotBegin(2);
  for (my $theI=-100; $theI<=100; $theI++) {
    my $x = $theI+50;
    my $y = $theFac*$theI*$theI*$theI;
    $plot[0]->PlotAdd2D($x, $y);
  }
  $plot[0]->PlotEnd();
  $plot[0]->SetAttribute("DS_LINEWIDTH", "3");
  $plot[0]->SetAttribute("DS_LEGEND", "Line");

  $theFac = 2.0/100;
  $plot[0]->PlotBegin(2);
  for (my $theI=-100; $theI<=100; $theI++) {
    my $x = $theI;
    my $y = -$theFac*$theI;
    $plot[0]->PlotAdd2D($x, $y);
  }
  $plot[0]->PlotEnd();
  $plot[0]->SetAttribute("DS_LEGEND", "Curve 1");

  $plot[0]->PlotBegin(2);
  for (my $theI=-100; $theI<=100; $theI++)  {
    my $x = (0.01*$theI*$theI-30);
    my $y = 0.01*$theI;
    $plot[0]->PlotAdd2D($x, $y);
  }
  $plot[0]->PlotEnd();
  $plot[0]->SetAttribute("DS_LEGEND", "Curve 2");

  # PLOT 1 - MakeExamplePlot2
  $plot[1]->SetAttribute("TITLE", "No Autoscale+No CrossOrigin");
  $plot[1]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[1]->SetAttribute("MARGINTOP", "40");
  $plot[1]->SetAttribute("MARGINLEFT", "55");
  $plot[1]->SetAttribute("MARGINBOTTOM", "50");
  $plot[1]->SetAttribute("BGCOLOR", "0 192 192");
  $plot[1]->SetAttribute("AXS_XLABEL", "Tg (X)");
  $plot[1]->SetAttribute("AXS_YLABEL", "Tg (Y)");
  $plot[1]->SetAttribute("AXS_XAUTOMIN", "NO");
  $plot[1]->SetAttribute("AXS_XAUTOMAX", "NO");
  $plot[1]->SetAttribute("AXS_YAUTOMIN", "NO");
  $plot[1]->SetAttribute("AXS_YAUTOMAX", "NO");
  $plot[1]->SetAttribute("AXS_XMIN", "10");
  $plot[1]->SetAttribute("AXS_XMAX", "60");
  $plot[1]->SetAttribute("AXS_YMIN", "-0.5");
  $plot[1]->SetAttribute("AXS_YMAX", "0.5");
  $plot[1]->SetAttribute("AXS_XCROSSORIGIN", "NO");
  $plot[1]->SetAttribute("AXS_YCROSSORIGIN", "NO");
  $plot[1]->SetAttribute("AXS_XFONTSTYLE", "BOLD");
  $plot[1]->SetAttribute("AXS_YFONTSTYLE", "BOLD");
  $plot[1]->SetAttribute("AXS_XREVERSE", "YES");
  $plot[1]->SetAttribute("GRIDCOLOR", "128 255 128");
  $plot[1]->SetAttribute("GRIDLINESTYLE", "DOTTED");
  $plot[1]->SetAttribute("GRID", "YES");
  $plot[1]->SetAttribute("LEGENDSHOW", "YES");

  $theFac = 1.0/(100*100*100);
  $plot[1]->PlotBegin(2);
  for (my $theI=0; $theI<=100; $theI++) {
    my $x = $theI;
    my $y = $theFac*$theI*$theI*$theI;
    $plot[1]->PlotAdd2D($x, $y);
  }
  $plot[1]->PlotEnd();

  $theFac = 2.0/100;
  $plot[1]->PlotBegin(2);
  for (my $theI=0; $theI<=100; $theI++) {
    my $x = $theI;
    my $y = -$theFac*$theI;
    $plot[1]->PlotAdd2D($x, $y);
  }
  $plot[1]->PlotEnd();

  # PLOT 2 - MakeExamplePlot4
  $plot[2]->SetAttribute("TITLE", "Log Scale");
  $plot[2]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[2]->SetAttribute("MARGINTOP", "40");
  $plot[2]->SetAttribute("MARGINLEFT", "70");
  $plot[2]->SetAttribute("MARGINBOTTOM", "50");
  $plot[2]->SetAttribute("GRID", "YES");
  $plot[2]->SetAttribute("AXS_XSCALE", "LOG10");
  $plot[2]->SetAttribute("AXS_YSCALE", "LOG2");
  $plot[2]->SetAttribute("AXS_XLABEL", "Tg (X)");
  $plot[2]->SetAttribute("AXS_YLABEL", "Tg (Y)");
  $plot[2]->SetAttribute("AXS_XFONTSTYLE", "BOLD");
  $plot[2]->SetAttribute("AXS_YFONTSTYLE", "BOLD");

  $theFac = 100.0/(100*100*100);
  $plot[2]->PlotBegin(2);
  for (my $theI=0; $theI<=100; $theI++) {
    my $x = (0.0001+$theI*0.001);
    my $y = (0.01+$theFac*$theI*$theI*$theI);
    $plot[2]->PlotAdd2D($x, $y);
  }
  $plot[2]->PlotEnd();
  $plot[2]->SetAttribute("DS_COLOR", "100 100 200");

  # PLOT 3 - MakeExamplePlot5
  $plot[3]->SetAttribute("TITLE", "Bar Mode");
  $plot[3]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[3]->SetAttribute("MARGINTOP", "40");
  $plot[3]->SetAttribute("MARGINLEFT", "30");
  $plot[3]->SetAttribute("MARGINBOTTOM", "30");
  my @kLables = ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec");
  my @kData = (1,2,3,4,5,6,7,8,9,0,1,2);

  $plot[3]->PlotBegin(1);
  for (my $theI=0; $theI<12; $theI++) { 
    $plot[3]->PlotAdd1D($kLables[$theI], $kData[$theI]);
  }
  $plot[3]->PlotEnd();
  $plot[3]->SetAttribute("DS_COLOR", "100 100 200");
  $plot[3]->SetAttribute("DS_MODE", "BAR");

  # PLOT 4 - MakeExamplePlot6
  $plot[4]->SetAttribute("TITLE", "Marks Mode");
  $plot[4]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[4]->SetAttribute("MARGINTOP", "40");
  $plot[4]->SetAttribute("MARGINLEFT", "45");
  $plot[4]->SetAttribute("MARGINBOTTOM", "40");
  $plot[4]->SetAttribute("AXS_XAUTOMIN", "NO");
  $plot[4]->SetAttribute("AXS_XAUTOMAX", "NO");
  $plot[4]->SetAttribute("AXS_YAUTOMIN", "NO");
  $plot[4]->SetAttribute("AXS_YAUTOMAX", "NO");
  $plot[4]->SetAttribute("AXS_XMIN", "0");
  $plot[4]->SetAttribute("AXS_XMAX", "0.011");
  $plot[4]->SetAttribute("AXS_YMIN", "0");
  $plot[4]->SetAttribute("AXS_YMAX", "0.22");
  $plot[4]->SetAttribute("AXS_XCROSSORIGIN", "NO");
  $plot[4]->SetAttribute("AXS_YCROSSORIGIN", "NO");
  $plot[4]->SetAttribute("AXS_XTICKFORMAT", "%1.3f");
  $plot[4]->SetAttribute("LEGENDSHOW", "YES");
  $plot[4]->SetAttribute("LEGENDPOS", "BOTTOMRIGHT");

  $theFac = 100.0/(100*100*100);
  $plot[4]->PlotBegin(2);
  for (my $theI=0; $theI<=10; $theI++) {
    my $x = (0.0001+$theI*0.001);
    my $y = (0.01+$theFac*$theI*$theI);
    $plot[4]->PlotAdd2D($x, $y);
  }
  $plot[4]->PlotEnd();
  $plot[4]->SetAttribute("DS_MODE", "MARKLINE");
  $plot[4]->SetAttribute("DS_SHOWVALUES", "YES");

  $plot[4]->PlotBegin(2);
  for (my $theI=0; $theI<=10; $theI++) {
    my $x = (0.0001+$theI*0.001);
    my $y = (0.2-$theFac*$theI*$theI);
    $plot[4]->PlotAdd2D($x, $y);
  }
  $plot[4]->PlotEnd();
  $plot[4]->SetAttribute("DS_MODE", "MARK");
  $plot[4]->SetAttribute("DS_MARKSTYLE", "HOLLOW_CIRCLE");
  
  # PLOT 5 - MakeExamplePlot8
  $plot[5]->SetAttribute("TITLE", "Data Selection and Editing");
  $plot[5]->SetAttribute("TITLEFONTSIZE", "16");
  $plot[5]->SetAttribute("MARGINTOP", "40");

  $theFac = 100.0/(100*100*100);
  $plot[5]->PlotBegin(2);
  for (my $theI=-10; $theI<=10; $theI++) {
    my $x = (0.001*$theI);
    my $y = (0.01+$theFac*$theI*$theI*$theI);
    $plot[5]->PlotAdd2D($x, $y);
  }
  $plot[5]->PlotEnd();
  $plot[5]->SetAttribute("DS_COLOR", "100 100 200");
  $plot[5]->SetAttribute("DS_EDIT", "YES");
  $plot[5]->SetCallback("DELETE_CB", \&delete_cb);
  $plot[5]->SetCallback("SELECT_CB", \&select_cb);
  $plot[5]->SetCallback("POSTDRAW_CB", \&postdraw_cb);
  $plot[5]->SetCallback("PREDRAW_CB", \&predraw_cb);
  $plot[5]->SetCallback("EDIT_CB", \&edit_cb);
}

sub tabs_get_index {
  my $curr_tab = IUP->GetByName($tabs->GetAttribute("VALUE"));
  my $ss = $curr_tab->GetAttribute("TABTITLE");
  $ss = int(substr($ss, 5)); # Skip "Plot "
  return $ss;
}

# Some processing required by current tab change: the controls at left
# will be updated according to current plot props
sub tabs_tabchange_cb {
  #(Ihandle* self, Ihandle* new_tab)
  my ($self, $new_tab) = @_;
  my $ii = 0;

  my $ss = $new_tab->GetAttribute("TABTITLE");
  $ss = substr($ss, 5); # Skip "Plot "
  $ii = int($ss);  

  # autoscaling
  # X axis
  if ($plot[$ii]->GetAttribute("AXS_XAUTOMIN") && $plot[$ii]->GetAttribute("AXS_XAUTOMAX")) {
    $tgg2->VALUE("ON");
    $dial2->ACTIVE("NO");
  }
  else {
    $tgg2->VALUE("OFF");
    $dial2->ACTIVE("YES");
  }
  # Y axis
  if ($plot[$ii]->GetAttribute("AXS_YAUTOMIN") && $plot[$ii]->GetAttribute("AXS_YAUTOMAX")) {
    $tgg1->VALUE("ON");
    $dial1->ACTIVE("NO");
  }
  else {
    $tgg1->VALUE("OFF");
    $dial1->ACTIVE("YES");
  }

  # grid
  if ($plot[$ii]->GetAttribute("GRID")) {
    $tgg3->VALUE("ON");
    $tgg4->VALUE("ON");
  }
  else
  {
    # X axis
    if ($plot[$ii]->GetAttribute("GRID") eq 'V') {
      $tgg3->VALUE("ON");
    }
    else {
      $tgg3->VALUE("OFF");
    }
    # Y axis
    if ($plot[$ii]->GetAttribute("GRID") eq 'H') {
      $tgg4->VALUE("ON");
    }
    else {
      $tgg4->VALUE("OFF");
    }
  }

  # legend
  if ($plot[$ii]->GetAttribute("LEGENDSHOW")) {
    $tgg5->VALUE("ON");
  }
  else {
    $tgg5->VALUE("OFF");
  }

  return IUP_DEFAULT;
}

# show/hide V grid
sub tgg3_cb {
  my ($self, $v) = @_;
  my $ii = tabs_get_index();

  if ($v) {
    if ($tgg4->GetAttribute("VALUE")) {
      $plot[$ii]->SetAttribute("GRID", "YES");
    }
    else {
      $plot[$ii]->SetAttribute("GRID", "VERTICAL");
    }
  }
  else {
    if (!$tgg4->GetAttribute("VALUE")) {
      $plot[$ii]->SetAttribute("GRID", "NO");
    }
    else {
      $plot[$ii]->SetAttribute("GRID", "HORIZONTAL");
    }
  }

  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}


# show/hide H grid
sub tgg4_cb {
  my ($self, $v) = @_;
  my $ii = tabs_get_index();

  if ($v) {
    if ($tgg3->GetAttribute("VALUE")) {
      $plot[$ii]->SetAttribute("GRID", "YES");
    }
    else {
      $plot[$ii]->SetAttribute("GRID", "HORIZONTAL");
    }
  }
  else
  {
    if (!$tgg3->GetAttribute("VALUE")) {
      $plot[$ii]->SetAttribute("GRID", "NO");
    }
    else {
      $plot[$ii]->SetAttribute("GRID", "VERTICAL");
    }
  }

  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}


# show/hide legend
sub tgg5_cb {
  my ($self, $v) = @_;
  my $ii = tabs_get_index();

  $plot[$ii]->SetAttribute("LEGENDSHOW", $v ? "YES" : "NO");
  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}


# autoscale Y
sub tgg1_cb {
  my ($self, $v) = @_;
  my $ii = tabs_get_index();

  if ($v) {
    $dial1->SetAttribute("ACTIVE", "NO");
    $plot[$ii]->SetAttribute("AXS_YAUTOMIN", "YES");
    $plot[$ii]->SetAttribute("AXS_YAUTOMAX", "YES");
  }
  else {
    $dial1->SetAttribute("ACTIVE", "YES");
    $plot[$ii]->SetAttribute("AXS_YAUTOMIN", "NO");
    $plot[$ii]->SetAttribute("AXS_YAUTOMAX", "NO");
  }

  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}


# autoscale X
sub tgg2_cb {
  my ($self, $v) = @_;
  my $ii = tabs_get_index();

  if ($v) {
    $dial2->SetAttribute("ACTIVE", "NO");
    $plot[$ii]->SetAttribute("AXS_XAUTOMIN", "YES");
    $plot[$ii]->SetAttribute("AXS_XAUTOMAX", "YES");
  }
  else {
    $dial2->SetAttribute("ACTIVE", "YES");
    $plot[$ii]->SetAttribute("AXS_XAUTOMIN", "NO");
    $plot[$ii]->SetAttribute("AXS_XAUTOMAX", "NO");
  }

  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}


# Y zoom
sub dial1_btndown_cb {
  my ($self, $angle) = @_;
  my $ii = tabs_get_index();

  $plot[$ii]->SetAttribute("OLD_YMIN", $plot[$ii]->GetAttribute("AXS_YMIN"));
  $plot[$ii]->SetAttribute("OLD_YMAX", $plot[$ii]->GetAttribute("AXS_YMAX"));

  return IUP_DEFAULT;
}

sub dial1_btnup_cb {
  my ($self, $angle) = @_;
  my $ii = tabs_get_index();
  my ($x1, $x2, $xm);
  my $ss;

  $x1 = $plot[$ii]->GetAttribute("OLD_YMIN");
  $x2 = $plot[$ii]->GetAttribute("OLD_YMAX");

  $ss = $plot[$ii]->GetAttribute("AXS_YMODE");
  if ( $ss && substr($ss,3,1) eq '2' ) {
    # LOG2:  one circle will zoom 2 times
    $xm = 4.0 * abs($angle) / 3.141592;
    if ($angle>0.0) {
      $x2 /= $xm; $x1 *= $xm;
    }
    else {
      $x2 *= $xm; $x1 /= $xm;
    }
  }
  if ( $ss && substr($ss,3,1) eq '1' ) {
    # LOG10:  one circle will zoom 10 times
    $xm = 10.0 * abs($angle) / 3.141592;
    if ($angle>0.0) {
      $x2 /= $xm; $x1 *= $xm;
    }
    else {
      $x2 *= $xm; $x1 /= $xm;
    }
  }
  else {
    # LIN: one circle will zoom 2 times
    $xm = ($x1 + $x2) / 2.0;
    $x1 = $xm - ($xm - $x1)*(1.0-$angle*1.0/3.141592);
    $x2 = $xm + ($x2 - $xm)*(1.0-$angle*1.0/3.141592);
  }

  if ($x1<$x2) {
    $plot[$ii]->SetAttribute("AXS_YMIN", $x1);
    $plot[$ii]->SetAttribute("AXS_YMAX", $x2);
  }

  $plot[$ii]->SetAttribute("REDRAW", undef);
  return IUP_DEFAULT;
}


# X zoom
sub dial2_btndown_cb {
  my ($self, $angle) = @_;
  my $ii = tabs_get_index();

  $plot[$ii]->SetAttribute("OLD_XMIN", $plot[$ii]->GetAttribute("AXS_XMIN"));
  $plot[$ii]->SetAttribute("OLD_XMAX", $plot[$ii]->GetAttribute("AXS_XMAX"));

  return IUP_DEFAULT;
}

sub dial2_btnup_cb {
  my ($self, $angle) = @_;
  my $ii = tabs_get_index();
  my ($x1, $x2, $xm);

  $x1 = $plot[$ii]->GetAttribute("OLD_XMIN");
  $x2 = $plot[$ii]->GetAttribute("OLD_XMAX");

  $xm = ($x1 + $x2) / 2.0;

  $x1 = $xm - ($xm - $x1)*(1.0-$angle*1.0/3.141592); # one circle will zoom 2 times
  $x2 = $xm + ($x2 - $xm)*(1.0-$angle*1.0/3.141592);

  $plot[$ii]->SetAttribute("AXS_XMIN", $x1);
  $plot[$ii]->SetAttribute("AXS_XMAX", $x2);

  $plot[$ii]->SetAttribute("REDRAW", undef);

  return IUP_DEFAULT;
}

sub bt1_cb {
  my $self = shift;
  my $filename = "testfile"; #BEWARE: no spaces
  my $ii = tabs_get_index();

  use IUP::Canvas::FileVector;
  my $cnv2 = IUP::Canvas::FileVector->new(format=>"EMF", filename=>"$filename.emf", width=>'800', height=>600);
  $plot[$ii]->PlotPaintTo($cnv2);
  $cnv2->cdKillCanvas();
  
  IUP->Message("Warning", "Exported to '$filename.emf'!");
  return IUP_DEFAULT;
}

### main ###

my @vboxr; #tabs containing the plots
my ($dlg, $vboxl, $hbox, $lbl1, $lbl2, $lbl3, $bt1, $boxinfo, $boxdial1, $boxdial2, $f1, $f2);

# create plots
for (my $ii=0; $ii<$MAXPLOT; $ii++) {
  $plot[$ii] = IUP::PPlot->new();
}

# left panel: plot control
# Y zooming
$dial1 = IUP::Dial->new( TYPE=>"VERTICAL", ACTIVE=>"NO", SIZE=>"20x52" );
$dial1->SetCallback( BUTTON_PRESS_CB  =>\&dial1_btndown_cb,
                     MOUSEMOVE_CB     =>\&dial1_btnup_cb,
                     BUTTON_RELEASE_CB=>\&dial1_btnup_cb );
$lbl1 = IUP::Label->new( TITLE=>"+", EXPAND=>"NO" );
$lbl2 = IUP::Label->new( TITLE=>"-", EXPAND=>"NO" );
$boxinfo = IUP::Vbox->new( child=>[$lbl1, IUP::Fill->new(), $lbl2],
                           ALIGNMENT=>"ACENTER", SIZE=>"20x52",
                           GAP=>"2", MARGIN=>"4", EXPAND=>"YES" );
$boxdial1 = IUP::Hbox->new( child=>[$boxinfo, $dial1], ALIGNMENT=>"ACENTER" );
$tgg1 = IUP::Toggle->new( TITLE=>"Y Autoscale", ACTION=>\&tgg1_cb, VALUE=>"ON" );
$f1 = IUP::Frame->new( child=>IUP::Vbox->new( child=>[$boxdial1, $tgg1] ), TITLE=>"Y Zoom" );

# X zooming
$dial2 = IUP::Dial->new( TYPE=>"HORIZONTAL", ACTIVE=>"NO", SIZE=>"64x16", 
                         BUTTON_PRESS_CB  =>\&dial2_btndown_cb,
                         MOUSEMOVE_CB     =>\&dial2_btnup_cb,
                         BUTTON_RELEASE_CB=>\&dial2_btnup_cb );
$lbl1 = IUP::Label->new( TITLE=>"-", EXPAND=>"NO" );
$lbl2 = IUP::Label->new( TITLE=>"+", EXPAND=>"NO" );
$boxinfo = IUP::Hbox->new( child=>[$lbl1, IUP::Fill->new(), $lbl2],
                           ALIGNMENT=>"ACENTER", SIZE=>"64x16", GAP=>"2",
                           MARGIN=>"4", EXPAND=>"HORIZONTAL" );
$boxdial2 = IUP::Vbox->new( child=>[$dial2, $boxinfo], ALIGNMENT=>"ACENTER" );
$tgg2 = IUP::Toggle->new( TITLE=>"X Autoscale", ACTION=>\&tgg2_cb );
$f2 = IUP::Frame->new( child=>IUP::Vbox->new( child=>[$boxdial2, $tgg2] ), TITLE=>"X Zoom" );

$lbl1 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );
$tgg3 = IUP::Toggle->new( TITLE=>"Vertical Grid", ACTION=>\&tgg3_cb );
$tgg4 = IUP::Toggle->new( TITLE=>"Horizontal Grid", ACTION=>\&tgg4_cb );
$lbl2 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );
$tgg5 = IUP::Toggle->new( TITLE=>"Legend", ACTION=>\&tgg5_cb );
$lbl3 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );

$bt1 = IUP::Button->new( TITLE=>"Export EMF", ACTION=>\&bt1_cb );
$vboxl = IUP::Vbox->new( child=>[$f1, $f2, $lbl1, $tgg3, $tgg4, $lbl2, $tgg5, $lbl3, $bt1] );
$vboxl->SetAttribute( GAP=>"4", EXPAND=>"NO" );

# right panel: tabs with plots
for (my $ii=0; $ii<$MAXPLOT; $ii++) {
  $vboxr[$ii] = IUP::Vbox->new( child=>$plot[$ii] ); # each plot a tab
  $vboxr[$ii]->SetAttribute("TABTITLE", "Plot $ii"); # name each tab
}

$tabs = IUP::Tabs->new( child=>\@vboxr, TABCHANGE_CB=>\&tabs_tabchange_cb ); # create tabs

# dialog
$hbox = IUP::Hbox->new( child=>[$vboxl, $tabs] );
$hbox->SetAttribute( MARGIN=>"4x4", GAP=>"10" );
  
$dlg = IUP::Dialog->new( child=>$hbox, SIZE=>"500x240", TITLE=>"IupPlot Example" );

InitPlots(); # It must be able to be done independent of dialog Mapping

tabs_tabchange_cb($tabs, $vboxr[0]);

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
$dlg->SetAttribute("SIZE", undef);

if (IUP->MainLoopLevel == 0) {
  IUP->MainLoop;
}
