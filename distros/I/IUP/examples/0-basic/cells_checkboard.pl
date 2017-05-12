# IUP::Cells example

use strict;
use warnings;

use IUP ':all';

sub draw_cb {
  my ($self, $i, $j, $xmin, $xmax, $ymin, $ymax, $canvas) = @_;
  $canvas->cdForeground( ($i%2 == $j%2) ? CD_WHITE : CD_BLACK );
  $canvas->cdBox($xmin, $xmax, $ymin, $ymax);
  return IUP_DEFAULT;
}

my $cells = IUP::Cells->new(
              DRAW_CB   => \&draw_cb,
              WIDTH_CB  => sub {50},
              HEIGHT_CB => sub {50},
              NLINES_CB => sub {8},
              NCOLS_CB  => sub {8} );

my $dlg = IUP::Dialog->new( child=>$cells, RASTERSIZE=>"450x450", TITLE=>"IUP::Cells" );
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop();
