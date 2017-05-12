# IUP::Cells example

use strict;
use warnings;

use IUP ':all';

sub mouseclick_cb {
  my ($self, $b, $m, $i, $j, $x, $y, $r) = @_;
  IUP->Message("Hi!", "CLICK: $b: ($i, $j)\n");
  return IUP_DEFAULT;
}

my $global_debug = 0;

sub draw_cb {
  my ($self, $i, $j, $xmin, $xmax, $ymin, $ymax, $canvas) = @_;
  my $xm = ($xmax + $xmin) / 2;
  my $ym = ($ymax + $ymin) / 2;
  
  #XXX checkthis - callback is very, very slow
  $global_debug++;
  warn "counter=$global_debug\n" if $global_debug%100 == 0;  

  $canvas->cdForeground($canvas->cdEncodeColor($i*20, $j*100, $i+100));
  $canvas->cdBox($xmin, $xmax, $ymin, $ymax);
  $canvas->cdTextAlignment(CD_CENTER);
  $canvas->cdForeground(CD_BLACK);
  $canvas->cdText($xm, $ym, "($i, $j)");
  return IUP_DEFAULT;
}

my $cells = IUP::Cells->new(
              BOXED         => "NO",
              MOUSECLICK_CB => \&mouseclick_cb,
              DRAW_CB       => \&draw_cb,
              WIDTH_CB      => sub {70},
              HEIGHT_CB     => sub {30},
              NLINES_CB     => sub {20},
              NCOLS_CB      => sub {50} );

my $dlg = IUP::Dialog->new( child=>$cells, RASTERSIZE=>"500x500", TITLE=>"IUP::Cells" );
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);   

IUP->MainLoop();
