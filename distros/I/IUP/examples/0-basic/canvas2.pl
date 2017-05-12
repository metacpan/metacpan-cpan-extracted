# IUP::Canvas example
#
# This example shows how several canvas callbacks are used
# and how the scrollbar works.

use strict;
use warnings;

use IUP ':all';

my %stars = ( );
my $label = IUP::Label->new( TITLE=>'IUP::Canvas');

sub redraw_cb {
  my $self = shift;
  $self->cdActivate();
  $self->cdClear();
  for (keys %stars) {
    my ($gx, $gy) = split /:/, $_;
    my $x = $gx-320*$self->POSX;
    my $y = $gy-200*$self->POSY;
    $y = $self->cdUpdateYAxis($y);
    $self->cdMark($x, $y);
  }
  return IUP_DEFAULT;
};

sub button_cb {
  my ($self, $but, $press, $x, $y) = @_;
  my $gx = 320*$self->POSX+$x;
  my $gy = 200*$self->POSY+$y;
  if ($but == IUP_BUTTON1 && $press == 1) {
    $y = $self->cdUpdateYAxis($y);
    $self->cdMark($x, $y);    
    $stars{"$gx:$gy"} = 1;
  }
  return IUP_DEFAULT;
};

sub scroll_cb {
  my $self = shift;
  redraw_cb($self);
  return IUP_DEFAULT;
}

sub motion_cb {
  my ($self, $mx, $my, $r) = @_;
  $mx += 320*$self->POSX;
  $my += 200*$self->POSY;
  $label->TITLE("[$mx,$my]");
  return IUP_DEFAULT;
};

sub enter_cb {
  my $self = shift;
  $self->cdBackground(CD_WHITE);
  redraw_cb($self);
  return IUP_DEFAULT;
}

sub leave_cb {
  my $self = shift;
  $self->cdBackground(CD_GRAY);
  redraw_cb($self,0.0,0.0);
  $label->TITLE('IUP::Canvas');
  return IUP_DEFAULT;
}

my $cv = IUP::Canvas->new( CURSOR=>"CROSS", RASTERSIZE=>"320x200",
                           EXPAND=>"NO", SCROLLBAR=>"YES",
                           DX=>0.5, DY=>0.5 );

$cv->SetCallback( ACTION=>\&redraw_cb, BUTTON_CB=>\&button_cb,
                  SCROLL_CB=>\&scroll_cb, MOTION_CB=>\&motion_cb,
                  ENTERWINDOW_CB=>\&enter_cb, LEAVEWINDOW_CB=>\&leave_cb );

my $dg = IUP::Dialog->new( child=>IUP::Vbox->new([
                             $cv, 
                             IUP::Hbox->new( child=>[
                               IUP::Fill->new(), 
                               $label, 
                               IUP::Fill->new()
                             ]),
                           ]), TITLE=>"Welcome to IUP::Canvas demo", 
                           RESIZE=>"NO", MAXBOX=>"NO" );

$dg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop;
