# IUP::PPlot example

use strict;
use warnings;

use IUP ':all';
use Scalar::Util 'looks_like_number';

#xxxTODO maybe add AxsBounds to IUP::PPlot
sub AxsBounds {
  my ($self, $axs_xmin, $axs_xmax, $axs_ymin, $axs_ymax) = @_;
  if (defined $axs_xmin) {
    $self->AXS_XMIN($axs_xmin);
    $self->AXS_XAUTOMIN('NO');
  }
  if (defined $axs_xmax) {
    $self->AXS_XMAX($axs_xmax);
    $self->AXS_XAUTOMAX('NO');
  }
  if (defined $axs_ymin) {
    $self->AXS_YMIN($axs_ymin);
    $self->AXS_YAUTOMIN('NO');
  }
  if (defined $axs_ymax) {
    $self->AXS_YMAX($axs_ymax);
    $self->AXS_YAUTOMAX('NO');
  }
}

sub AddSeries {
  my ($plot, @values) = @_;
  my (@x, @y);
  for (@values) {
    push @x, $_->[0];
    push @y, $_->[1];
  }
  $plot->PlotBegin(2)->PlotAdd2D(\@x,\@y)->PlotEnd;
}


my $plot = IUP::PPlot->new( TITLE=>"Simple Data", MARGINBOTTOM=>30, MARGINLEFT=>30 );
AxsBounds($plot, 0,100,0,100);
AddSeries($plot, [0,0],[10,10],[20,30],[30,45] );
AddSeries($plot, [40,40],[50,55],[60,60],[70,65] );

my $d = IUP::Dialog->new( TITLE=>"Easy Plotting", SIZE=>"QUARTERxQUARTER", child=>$plot );
$d->Show();

IUP->MainLoop();
