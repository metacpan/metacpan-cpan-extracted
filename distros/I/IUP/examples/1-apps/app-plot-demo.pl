use strict;
use warnings;

use IUP ':all';

my $mainplot;
my $mainfunc;
my ($dial1, $dial2);  # dials for zooming
my ($tgg1, $tgg2);    # auto scale on|off toggles
my ($tgg3, $tgg4);    # grid show|hide toggles
my $tgg5;             # legend show|hide toggle

sub delete_cb {
  my ($self, $index, $sample_index, $x, $y) = @_;
  printf STDERR "DELETE_CB(%d, %d, %g, %g)\n", $index, $sample_index, $x, $y;
  return IUP_DEFAULT;
}

sub select_cb {
  my ($self, $index, $sample_index, $x, $y, $select) = @_;
  printf STDERR "SELECT_CB(%d, %d, %g, %g, %d)\n", $index, $sample_index, $x, $y, $select;
  return IUP_DEFAULT;
}

sub edit_cb {
  # xxxTODO: references
  # perhaps - return (IUP_DEFAULT, $new_x, $new_y);
  my ($self, $index, $sample_index, $x, $y, $new_x, $new_y) = @_;
  printf STDERR "EDIT_CB(%d, %d, %g, %g, %g, %g)\n", $index, $sample_index, $x, $y, $new_x, $new_y;
  return IUP_DEFAULT;
}

sub postdraw_cb {
  my ($self, $cnv) = @_;
  #my ($ix, $iy) = $self->PlotTransform(0.003, 0.02);  
  #$cnv->cdFont(undef, CD_BOLD, 10);
  #$cnv->cdTextAlignment(CD_SOUTH);
  #$cnv->cdText($ix, $iy, "My Inline Legend");
  return IUP_DEFAULT;
}

sub predraw_cb {
  my ($self, $cnv) = @_;
  #printf STDERR "PREDRAW_CB()\n";
  return IUP_DEFAULT;
}

sub InitPlot {
  my $theFac;  
  $mainplot->SetAttribute(
    TITLE => "Sample Plot",
    AXS_XORIGIN=>0,
    AXS_YORIGIN=>0,
    #TITLEFONTSIZE => 1.2,
    TITLEFONTSTYLE => 'BOLD',
    MARGINTOP => "40",
    OPENGL=>"YES",
  );

  $theFac = 100.0/(100*100*100);
  my (@x, @y);
  for (my $theI=-10; $theI<=10; $theI++) {
    push @x, (0.001*$theI);
    push @y, (0.01+$theFac*$theI*$theI*$theI);
  }
  $mainplot->PlotBegin(2)->PlotAdd2D(\@x, \@y)->PlotEnd;
  #$mainplot->SetAttribute("DS_COLOR", "100 100 200");
  #$mainplot->SetAttribute("DS_EDIT", "YES");
  $mainplot->SetCallback("DELETE_CB", \&delete_cb);
  $mainplot->SetCallback("SELECT_CB", \&select_cb);
  $mainplot->SetCallback("POSTDRAW_CB", \&postdraw_cb);
  $mainplot->SetCallback("PREDRAW_CB", \&predraw_cb);
  $mainplot->SetCallback("EDIT_CB", \&edit_cb);
}

# show/hide V grid
sub tgg3_cb {
  my ($self, $v) = @_;
  if ($v) {
    #checked
    $mainplot->GRID( ($tgg4->VALUE eq 'ON') ? "YES" : "VERTICAL" );
  }
  else {
    #unchecked
    $mainplot->GRID( ($tgg4->VALUE eq 'OFF') ? "NO" : "HORIZONTAL" );
  }
  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}


# show/hide H grid
sub tgg4_cb {
  my ($self, $v) = @_;  
  if ($v) {
    #checked
    $mainplot->GRID( ($tgg3->VALUE eq 'ON') ? "YES" : "HORIZONTAL" );
  }
  else {
    #unchecked
    $mainplot->GRID( ($tgg3->VALUE eq 'OFF') ? "NO" : "VERTICAL" );
  }
  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}

# show/hide legend
sub tgg5_cb {
  my ($self, $v) = @_;
  $mainplot->LEGENDSHOW($v ? "YES" : "NO");
  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}

# autoscale Y
sub tgg1_cb {
  my ($self, $v) = @_;

  if ($v) {
    $dial1->SetAttribute("ACTIVE", "NO");
    $mainplot->SetAttribute("AXS_YAUTOMIN", "YES");
    $mainplot->SetAttribute("AXS_YAUTOMAX", "YES");
  }
  else {
    $dial1->SetAttribute("ACTIVE", "YES");
    $mainplot->SetAttribute("AXS_YAUTOMIN", "NO");
    $mainplot->SetAttribute("AXS_YAUTOMAX", "NO");
  }
  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}

# autoscale X
sub tgg2_cb {
  my ($self, $v) = @_;

  if ($v) {
    $dial2->SetAttribute("ACTIVE", "NO");
    $mainplot->SetAttribute("AXS_XAUTOMIN", "YES");
    $mainplot->SetAttribute("AXS_XAUTOMAX", "YES");
  }
  else {
    $dial2->SetAttribute("ACTIVE", "YES");
    $mainplot->SetAttribute("AXS_XAUTOMIN", "NO");
    $mainplot->SetAttribute("AXS_XAUTOMAX", "NO");
  }
  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}


# Y zoom
sub dial1_btndown_cb {
  my ($self, $angle) = @_;
  warn "***DEBUG*** dial1_btndown_cb: ", $mainplot->GetAttribute("AXS_YMIN"), ":", $mainplot->GetAttribute("AXS_YMAX"), "\n";
  $mainplot->SetAttribute("OLD_YMIN", $mainplot->GetAttribute("AXS_YMIN"));
  $mainplot->SetAttribute("OLD_YMAX", $mainplot->GetAttribute("AXS_YMAX"));
  return IUP_DEFAULT;
}

sub dial1_btnup_cb {
  my ($self, $angle) = @_;
  my ($x1, $x2, $xm);
  my $ss;

  $x1 = $mainplot->GetAttribute("OLD_YMIN");
  $x2 = $mainplot->GetAttribute("OLD_YMAX");

  $ss = $mainplot->GetAttribute("AXS_YMODE");
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
    $mainplot->SetAttribute("AXS_YMIN", $x1);
    $mainplot->SetAttribute("AXS_YMAX", $x2);
  }

  $mainplot->REDRAW(1);
  return IUP_DEFAULT;
}


# X zoom
sub dial2_btndown_cb {
  my ($self, $angle) = @_;
  $mainplot->SetAttribute("OLD_XMIN", $mainplot->GetAttribute("AXS_XMIN"));
  $mainplot->SetAttribute("OLD_XMAX", $mainplot->GetAttribute("AXS_XMAX"));
  return IUP_DEFAULT;
}

sub dial2_btnup_cb {
  my ($self, $angle) = @_;
  my ($x1, $x2, $xm);

  $x1 = $mainplot->GetAttribute("OLD_XMIN");
  $x2 = $mainplot->GetAttribute("OLD_XMAX");

  $xm = ($x1 + $x2) / 2.0;

  $x1 = $xm - ($xm - $x1)*(1.0-$angle*1.0/3.141592); # one circle will zoom 2 times
  $x2 = $xm + ($x2 - $xm)*(1.0-$angle*1.0/3.141592);

  $mainplot->SetAttribute("AXS_XMIN", $x1);
  $mainplot->SetAttribute("AXS_XMAX", $x2);

  $mainplot->REDRAW(1);

  return IUP_DEFAULT;
}

sub bt1_cb {
  my $self = shift;
  my $filename = "testfile"; #BEWARE: no spaces

  use IUP::Canvas::FileVector;
  
  my $cnv1 = IUP::Canvas::FileVector->new(format=>"SVG", filename=>"$filename.svg", width=>300, height=>210, resolution=>4);
  $mainplot->PlotPaintTo($cnv1);
  $cnv1->cdKillCanvas();
  
  my $cnv2 = IUP::Canvas::FileVector->new(format=>"EMF", filename=>"$filename.emf", width=>'800', height=>600);
  $mainplot->PlotPaintTo($cnv2);
  $cnv2->cdKillCanvas();
  
  IUP->Message("Warning", "Exported to '$filename.emf' + '$filename.svg'!");
  return IUP_DEFAULT;
}

sub bt2_cb {
  my $self = shift;
  warn "Auto\n";
  $mainplot->SetAttribute("AXS_XAUTOMIN", "YES");
  $mainplot->SetAttribute("AXS_XAUTOMAX", "YES");
  $mainplot->REDRAW(1);
}

sub bt3_cb {
  my $self = shift;
  warn "Draw '", $mainfunc->VALUE, "'\n";
  my @xvalues;  
  my @yvalues;  
  my $y;
  for (my $x=-10; $x<=10; $x+=0.1) {    
    $y = eval $mainfunc->VALUE;
    if ($@) {
      my $msg = $@;
      $msg =~ s/[\r\n]*"/"/g;
      IUP->Message("ERROR", $msg);
      last;
    }
    push @xvalues, $x;
    push @yvalues, $y;
  }

  $mainplot->CLEAR(1);
  $mainplot->PlotSet2D($mainplot->PlotNewDataSet(2), \@xvalues, \@yvalues);  
  $mainplot->SetAttribute("TITLE", 'func: $y='.$mainfunc->VALUE);
  $mainplot->SetAttribute("AXS_XAUTOMIN", "YES");
  $mainplot->SetAttribute("AXS_XAUTOMAX", "YES");
  $mainplot->REDRAW(1);
}


### main ###

### left panel: plot control
# Y zooming
$dial1 = IUP::Dial->new( TYPE=>"VERTICAL", ACTIVE=>"NO", SIZE=>"20x52",
                         BUTTON_PRESS_CB  =>\&dial1_btndown_cb,
                         MOUSEMOVE_CB     =>\&dial1_btnup_cb,
                         BUTTON_RELEASE_CB=>\&dial1_btnup_cb );
$tgg1 = IUP::Toggle->new( TITLE=>"Y Autoscale", ACTION=>\&tgg1_cb, VALUE=>"ON" );
my $boxinfo = IUP::Vbox->new( child=>[ 
                                IUP::Label->new( TITLE=>"-", EXPAND=>"NO" ),
                                IUP::Fill->new(),
                                IUP::Label->new( TITLE=>"+", EXPAND=>"NO" )
                              ],
                              ALIGNMENT=>"ACENTER", SIZE=>"20x52",
                              GAP=>"2", MARGIN=>"4", EXPAND=>"YES" );
my $boxdial1 = IUP::Hbox->new( child=>[$boxinfo, $dial1], ALIGNMENT=>"ACENTER" );
my $f1 = IUP::Frame->new( child=>IUP::Vbox->new( child=>[$boxdial1, $tgg1] ), TITLE=>"Y Zoom" );

# X zooming
$dial2 = IUP::Dial->new( TYPE=>"HORIZONTAL", ACTIVE=>"NO", SIZE=>"64x16", 
                         BUTTON_PRESS_CB  =>\&dial2_btndown_cb,
                         MOUSEMOVE_CB     =>\&dial2_btnup_cb,
                         BUTTON_RELEASE_CB=>\&dial2_btnup_cb );
$tgg2 = IUP::Toggle->new( TITLE=>"X Autoscale", ACTION=>\&tgg2_cb, VALUE=>"ON" );
my $boxinfoxxx = IUP::Hbox->new( child=>[ 
                                IUP::Label->new( TITLE=>"-", EXPAND=>"NO" ),
                                IUP::Fill->new(),
                                IUP::Label->new( TITLE=>"+", EXPAND=>"NO" )
                              ],
                              ALIGNMENT=>"ACENTER", SIZE=>"64x16", GAP=>"2",
                              MARGIN=>"4", EXPAND=>"HORIZONTAL" );
my $boxdial2 = IUP::Vbox->new( child=>[$dial2, $boxinfoxxx], ALIGNMENT=>"ACENTER" );
my $f2 = IUP::Frame->new( child=>IUP::Vbox->new( child=>[$boxdial2, $tgg2] ), TITLE=>"X Zoom" );

# checkboxes + buttons
$tgg3 = IUP::Toggle->new( TITLE=>"Vertical Grid", ACTION=>\&tgg3_cb );
$tgg4 = IUP::Toggle->new( TITLE=>"Horizontal Grid", ACTION=>\&tgg4_cb );
$tgg5 = IUP::Toggle->new( TITLE=>"Legend", ACTION=>\&tgg5_cb );
my $lbl1 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );
my $lbl2 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );
my $lbl3 = IUP::Label->new( TITLE=>"", SEPARATOR=>"HORIZONTAL" );
my $bt1 = IUP::Button->new( TITLE=>"Export EMF", ACTION=>\&bt1_cb );
my $bt2 = IUP::Button->new( TITLE=>"Autofocus", ACTION=>\&bt2_cb );

my $vboxl = IUP::Vbox->new( child=>[$f1, $f2, $lbl1, $tgg3, $tgg4, $lbl2, $tgg5, $lbl3, $bt1, $bt2], GAP=>"4", EXPAND=>"NO" );

### right panel: plot control
$mainplot = IUP::Plot->new();
#$mainplot = IUP::MglPlot->new();
$mainfunc = IUP::Text->new( VALUE=>'sin($x)', VISIBLECOLUMNS=>50, VISIBLELINES=>3, MULTILINE=>'YES', EXPAND=>'YES');

### the main dialog
my $hbox1 = IUP::Hbox->new( child=>[$vboxl, $mainplot], MARGIN=>"4x4", GAP=>"10" );
my $hbox2 = IUP::Hbox->new( child=>[
                              IUP::Label->new( TITLE=>'$y =' ),
                              $mainfunc,
                               IUP::Button->new( TITLE=>"Draw", ACTION=>\&bt3_cb ),
                           ], MARGIN=>"4x4", GAP=>"2" );
 
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new([$hbox1, $hbox2]), SIZE=>"500x300", TITLE=>"IupPlot Example" );

InitPlot(); # It must be able to be done independent of dialog Mapping

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
$dlg->SetAttribute("SIZE", undef); # autofit trick

### the main loop
IUP->MainLoop;
