# IUP::PPlot example

use strict;
use warnings;

use IUP ':all';
use Scalar::Util 'looks_like_number';

sub create_pplot {
  my %args = @_;
  # if we explicitly supply ranges, then auto must be switched off for that direction.
  $args{AXS_YAUTOMIN} = "NO" if defined $args{AXS_YMIN};
  $args{AXS_YAUTOMAX} = "NO" if defined $args{AXS_YMAX};
  $args{AXS_XAUTOMIN} = "NO" if defined $args{AXS_XMIN};
  $args{AXS_XAUTOMAX} = "NO" if defined $args{AXS_XMAX};
  return IUP::PPlot->new(%args);  
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

my $p = create_pplot( TITLE=>"Simple Data", MARGINBOTTOM=>30, MARGINLEFT=>30, AXS_YMIN=>0, GRID=>"YES" );
add_series($p, [0,5,10], [1,6,8], {DS_MARKSTYLE=>"CIRCLE", DS_MODE=>"MARKLINE"} );

my $d = IUP::Dialog->new( TITLE=>"Easy Plotting", SIZE=>"QUARTERxQUARTER", child=>$p );
$d->Show();

IUP->MainLoop();
