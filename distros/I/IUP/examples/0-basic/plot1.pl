# IUP::PPlot example

use strict;
use warnings;

use IUP ':all';

my $plot = IUP::PPlot->new(
  TITLE=>"Simple Line",
  MARGINBOTTOM=>"65",
  MARGINLEFT=>"65",
  AXS_XLABEL=>"X",
  AXS_YLABEL=>"Y",
  LEGENDSHOW=>"YES",
  LEGENDPOS=>"TOPLEFT",  
);

$plot->PlotBegin(2);
$plot->PlotAdd2D(0, 0);
$plot->PlotAdd2D(1, 0.4);
$plot->PlotAdd2D(2, 2);
$plot->PlotEnd();

# note: DS_nnn attributes have to be set after PlotEnd()
$plot->DS_LEGEND("test line");
$plot->DS_LINEWIDTH(2);

my $d = IUP::Dialog->new( child=>$plot, SIZE=>"300x200", TITLE=>"IUP::PPlot" );
$d->Show();

IUP->MainLoop;
