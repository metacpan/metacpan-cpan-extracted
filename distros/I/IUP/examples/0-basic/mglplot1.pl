# IUP::MglPlot example

package MyDlg;
use strict;
use warnings;
use IUP ':all';

sub new {
  my $class = shift;
  my $p = _create_pplot(TITLE=>"Simple Data", MARGINBOTTOM=>30, MARGINLEFT=>30, AXS_YMIN=>0, GRID=>"YES");
  my $d = IUP::Dialog->new(TITLE=>"Easy Plotting", SIZE=>"HALFxHALF", child=>$p);
  my $h = { p=>$p, d=>$d };
  bless $h, $class;
}

sub _create_pplot {
  my %args = @_;
  # if we explicitly supply ranges, then auto must be switched off for that direction.
  $args{AXS_YAUTOMIN} = "YES";
  $args{AXS_XAUTOMIN} = "YES";
  $args{AXS_YAUTOMAX} = "YES";
  $args{AXS_XAUTOMAX} = "YES";
  $args{AXS_YAUTOMIN} = "NO" if defined $args{AXS_YMIN};
  $args{AXS_YAUTOMAX} = "NO" if defined $args{AXS_YMAX};
  $args{AXS_XAUTOMIN} = "NO" if defined $args{AXS_XMIN};
  $args{AXS_XAUTOMAX} = "NO" if defined $args{AXS_XMAX};

  return IUP::MglPlot->new(%args);
}

sub add_series {
  my ($self, $xvalues, $yvalues) = (shift, shift, shift);
  my $plot = $self->{p};
  my %options = @_;
  $plot->PlotBegin(2)->PlotAdd2D($xvalues, $yvalues)->PlotEnd;
  $plot->SetAttribute(DS_MODE=>delete $options{DS_MODE}) if $options{DS_MODE};
  $plot->SetAttribute(%options);
}

sub show {
  my $self = shift;
  $self->{d}->Show();
  IUP->MainLoop();
}

package main;
use strict;
use warnings;

my $gui = MyDlg->new;
$gui->add_series([0,5,10], [0,1.6,8], DS_MODE=>"MARKLINE", DS_MARKSTYLE=>"CIRCLE");
$gui->add_series([1,7.9,9], [1.9,6,8], DS_MODE=>"MARKLINE", DS_MARKSTYLE=>"CIRCLE");
$gui->show;

