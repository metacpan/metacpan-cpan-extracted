# IUP::Canvas example
#
# Basic 2D drawing example

use strict;
use warnings;

use IUP ':all';

my $cv = IUP::Canvas->new( SIZE=>"300x100", XMIN=>0, XMAX=>99, POSX=>0, DX=>10 );
my $draw = 0;

$cv->ACTION( sub {
  my ($self, $sx, $sy) = @_;
  $self->cdActivate();
  $self->cdClear();
  $self->cdForeground(CD_BLUE);
  $self->cdBox(0, 100, 0, 100);
  $self->cdForeground(CD_RED);
  $self->cdLine( 0,0,500,500);  
  $self->cdLine(10,0,510,500);
  $self->cdLine(20,0,520,500);
  $self->cdLine(30,0,530,500);
  $self->cdForeground(CD_BLACK);
  $self->cdLineStyle(CD_DOTTED);
  $self->cdArc(100,100,150,80,0,360);
  return IUP_DEFAULT;

} );

$cv->BUTTON_CB( sub {
  my ($self, $but, $press, $x, $y) = @_;
  if ($but == IUP_BUTTON1 && $press == 1) {
    $y = $self->cdUpdateYAxis($y);
    $self->cdPixel($x, $y, CD_BLUE);
    $draw = 1;
  }
  else {
    $self->cdClear();
    $draw = 0;
  }
  return IUP_DEFAULT;       
} );

$cv->MOTION_CB( sub {
  my ($self, $x, $y, $r) = @_;
  if ($draw) {
    $y = $self->cdUpdateYAxis($y);
    $self->cdPixel($x, $y, CD_BLUE);
  }
  return IUP_DEFAULT;
} );

my $dg = IUP::Dialog->new( child=>IUP::Vbox->new($cv), TITLE=>"IUP::Canvas + Canvas Draw", MARGIN=>"10x10" );
$dg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
