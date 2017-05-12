# IUP::Cells example

use strict;
use warnings;

use IUP ':all';

sub height_cb {
  my ($self, $i) = @_;
  return int(30+$i*1.5);
}

sub width_cb {
  my ($self, $j) = @_;
  return int(50+$j*1.5);
}

sub mouseclick_cb {
  my ($self, $b, $m, $i, $j, $x, $y, $r)  = @_;
  printf("CLICK: %d: (%02d, %02d)\n", $b, $i, $j);
  return IUP_DEFAULT;
}

sub scrolling_cb {
  my ($self, $i, $j) = @_;
  printf("SCROLL: (%02d, %02d)\n", $i, $j);
  return IUP_DEFAULT;
}

sub vspan_cb {
  my ($self, $i, $j) = @_;
  return 2 if ($i == 1 && $j == 1);
  return 2 if ($i == 5 && $j == 5);
  return 1;
}

sub hspan_cb {
  my ($self, $i, $j) = @_;
  return 2 if ($i == 1 && $j == 1);
  return 2 if ($i == 5 && $j == 5);
  return 1;
}

sub draw_cb {
  my ($self, $i, $j, $xmin, $xmax, $ymin, $ymax, $canvas) = @_;

  my $xm = ($xmax + $xmin) / 2;
  my $ym = ($ymax + $ymin) / 2;

  return IUP_DEFAULT if ($i == 1 && $j == 2);
  return IUP_DEFAULT if ($i == 2 && $j == 1);
  return IUP_DEFAULT if ($i == 2 && $j == 2);
  return IUP_DEFAULT if ($i == 5 && $j == 6);
  return IUP_DEFAULT if ($i == 6 && $j == 5);
  return IUP_DEFAULT if ($i == 6 && $j == 6);

  if ($i == 1 && $j == 1) {
    $canvas->cdForeground(CD_WHITE);
  }
  else {
    $canvas->cdForeground($canvas->cdEncodeColor($i*20, $j*100, $i+100));
  }
  
  $canvas->cdBox($xmin, $xmax, $ymin, $ymax);
  $canvas->cdTextAlignment(CD_CENTER);
  $canvas->cdForeground(CD_BLACK);  
  $canvas->cdText($xm, $ym, "($i, $j)");

  return IUP_DEFAULT;
}

my $cells = IUP::Cells->new(
              BOXED         => "NO",
              RASTERSIZE    => "395x255",
              MOUSECLICK_CB => \&mouseclick_cb,
              DRAW_CB       => \&draw_cb,
              SCROLLING_CB  => \&scrolling_cb,
              NLINES_CB     => sub {7},
              NCOLS_CB      => sub {7},
              WIDTH_CB      => \&width_cb,
              HEIGHT_CB     => \&height_cb,
              HSPAN_CB      => \&hspan_cb,
              VSPAN_CB      => \&vspan_cb, );

my $box = IUP::Vbox->new( child=>$cells, MARGIN=>"10x10" );
my $dlg = IUP::Dialog->new( child=>$box, TITLE=>"IUP::Cells", RASTERSIZE=>"350x250" );

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop();
