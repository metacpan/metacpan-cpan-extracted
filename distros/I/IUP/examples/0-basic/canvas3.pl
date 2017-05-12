# IUP::Canvas example
#
# Redraw demo

use strict;
use warnings;

use IUP ':all';

my ($dlg, $bt, $gauge, $tabs, $cv, $cdcanvas);
my $need_redraw = 0;
my $redraw_count = 0;

sub toggle_redraw {
  $cv->cdActivate();
  $need_redraw = !$need_redraw;
  return IUP_DEFAULT;
}

sub redraw {
  if ($need_redraw) {
    $cv->cdBox(0, 300, 0, $redraw_count/100);
    $gauge->VALUE($redraw_count/30000.0);
    $redraw_count++;
    if ($redraw_count == 30000) {
      $cv->cdClear();
      $redraw_count = 0;
      $need_redraw = 0;
    }
  }
  return IUP_DEFAULT;
};

$gauge = IUP::ProgressBar->new( SIZE=>"200x15" );
$cv    = IUP::Canvas->new( SIZE=>"200x200" );
$bt    = IUP::Button->new( TITLE=>"Start/Stop", SIZE=>"50x50", ACTION=>\&toggle_redraw );
$dlg   = IUP::Dialog->new( TITLE=>"Redraw test",
                           child=>IUP::Vbox->new( [$cv, IUP::Hbox->new( [$gauge, $bt] )] ));

$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

#the folloving canvas calls have to go after ShowXY
$cv->cdForeground(CD_BLUE);
$cv->cdClear();

IUP->SetIdle(\&redraw);

IUP->MainLoop();
