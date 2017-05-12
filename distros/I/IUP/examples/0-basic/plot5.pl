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

sub add_series {
  my ($plot, $xvalues, $yvalues, $options) = @_;
  # are we given strings for the x values?
  if (looks_like_number($xvalues->[1])) {
    $plot->PlotBegin(2)->PlotAdd2D($xvalues,$yvalues)->PlotEnd;
  }
  else {
    $plot->PlotBegin(1)->PlotAdd1D($xvalues,$yvalues)->PlotEnd;
  }
  # set any series-specific plot attributes
  if ($options) {
    # mode must be set before any other attributes!
    $plot->DS_MODE(delete $options->{DS_MODE}) if $options->{DS_MODE};
    $plot->SetAttribute(%$options);
  }
}

sub least_squares {
  my ($xx, $yy) = @_;
  my $xsum = 0.0;
  my $ysum = 0.0;
  my $xxsum = 0.0;
  my $yysum = 0.0;
  my $xysum = 0.0;
  my $n = scalar(@$xx);
  for my $i (0..$n-1) {
    my ($x, $y) = ($xx->[$i], $yy->[$i]);
    $xsum += $x;
    $ysum += $y;
    $xxsum += $x*$x;
    $yysum += $y*$y;
    $xysum += $x*$y;
  }
  my $m = ($xsum*$ysum/$n - $xysum )/($xsum*$xsum/$n - $xxsum);
  my $c = ($ysum - $m*$xsum)/$n;
  return ($m, $c);
}

my $xx = [0.0, 2.0, 5.0, 10.0];
my $yy = [1.0, 1.5, 6.0,  8.0];
my ($m, $c) = least_squares($xx, $yy);

sub ev {
  my $x = shift;
  return $m*$x + $c;
}

my $plot = IUP::PPlot->new( TITLE=>"Simple Data", MARGINBOTTOM=>30, MARGINLEFT=>30, GRID=>"YES" );
AxsBounds($plot, undef, undef, 0, undef);
add_series($plot, $xx, $yy, {DS_MODE=>"MARK",DS_MARKSTYLE=>"CIRCLE"} );
my ($xmin, $xmax) = ($xx->[0], $xx->[scalar(@$xx)-1]);  # the least squares fit
add_series($plot, [$xmin,$xmax],[ev($xmin),ev($xmax)] );

my $d = IUP::Dialog->new( TITLE=>"Easy Plotting", SIZE=>"QUARTERxQUARTER", child=>$plot );
$d->Show();

IUP->MainLoop();
